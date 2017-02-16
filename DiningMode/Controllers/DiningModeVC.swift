//
//  DiningModeVC.swift
//  DiningMode
//
//  Created by Scott Delly on 2/13/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class DiningModeVC: UIViewController, StoryboardTrait {
    
    let maxDishes = 3
    
    enum DiningModeSection {
        case info(name: String, time: Date, groupSize: Int, photo: Photo?)
        case address(RestaurantAnnotation)
        case dishes([Dish])
    }

    @IBOutlet weak var collectionView: UICollectionView!
    
    var diningModeSections = [DiningModeSection]()
    var reservationID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.backgroundColor = UIColor.purple
        NetworkService.shared.getReservation(reservationID: self.reservationID) { [weak self] (response) in
            switch response {
            case .Fail(let error):
                print("Failed to load reservations: \(error)")
                self?.diningModeSections = []
            case .Pass(let reservation):
                let infoSection = DiningModeSection.info(name: reservation.restaurant.name, time: reservation.localDate, groupSize: reservation.partySize, photo: reservation.restaurant.profilePhoto)
                let addressSection = DiningModeSection.address(RestaurantAnnotation(reservation: reservation))
                var finalSections = [infoSection, addressSection]
                if reservation.restaurant.dishes.count > 0 {
                    let dishSection = DiningModeSection.dishes(reservation.restaurant.dishes)
                    finalSections.append(dishSection)
                }
                self?.diningModeSections = finalSections
            }
            self?.collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension DiningModeVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.diningModeSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section < self.diningModeSections.count {
            return 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section < self.diningModeSections.count {
            let section = self.diningModeSections[indexPath.section]
            switch section {
            case .info(let name, let time, let groupSize, let photo):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiningCellInfo", for: indexPath) as! DiningCellInfo
                if let photo = photo {
                    cell.imageView.image(withPhoto: photo)
                }
                
                cell.labelTitle.text = name
                cell.labelGroupSize.text = "\(groupSize) \(groupSize>1 ? "people" : "person")"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEE, MMM. d"
                cell.labelDate.text = dateFormatter.string(from: time)
                let timeFormatter = DateFormatter()
                timeFormatter.dateStyle = .none
                timeFormatter.timeStyle = .short
                cell.labelTime.text = timeFormatter.string(from: time)
                return cell
            case .address(let annotation):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiningCellMap", for: indexPath) as! DiningCellMap
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                cell.mapView.setRegion(region, animated: false)
                cell.mapView.addAnnotation(annotation)
                cell.labelAddress.text = annotation.fullAddress()
                return cell
            case .dishes:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiningCellDishes", for: indexPath) as! DiningCellDishes
                cell.tableView.reloadData()
                return cell
            }
        }
        return UICollectionViewCell() // This will cause a runtime crash, but the compiler will aloow it. That was we can build and run the app, but we'll know quickly if this code is having issues because indexPath.section should never be greater than or equal to self.diningModeSections.count
    }
    
}

extension DiningModeVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "DiningViewHeader", for: indexPath)
    }
    
    
}

extension DiningModeVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: collectionView.bounds.size.width)
    }
}

extension DiningModeVC: UITableViewDataSource {
    
    var dishes: [Dish]? {
        get {
            if let dishSection = self.diningModeSections.first(where: { (section) -> Bool in
                switch section { case .dishes: return true default: return false }
            }) {
                if case let .dishes(dishArray) = dishSection {
                    return dishArray
                }
            }
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let dishes = self.dishes else { return 0 }
        return max(0,min(dishes.count, self.maxDishes))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dish = self.dishes![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellDish", for: indexPath) as! CellDish
        if let photo = dish.photos.first {
            cell.imageViewDish.image(withPhoto: photo)
        }
        
        let snippetRange = dish.snippet.content.range(from: dish.snippet.range)!
        let snippetText = dish.snippet.content.substring(with: snippetRange)
        
        let attributedTitle = NSMutableAttributedString(string: "\(dish.name)\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)])
        let attributedSnippet = NSMutableAttributedString(string: snippetText, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)])
        for highlight in dish.snippet.highlights {
            let locationInSnippet = highlight.location - dish.snippet.range.location
            if locationInSnippet < 0 || locationInSnippet > snippetText.characters.count || locationInSnippet + highlight.length > snippetText.characters.count  {
                continue
            }
            let updatedHighlight = NSMakeRange(locationInSnippet, highlight.length)
            attributedSnippet.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: updatedHighlight)
        }
        attributedTitle.append(attributedSnippet)
        
        cell.labelSnippet.attributedText = attributedTitle
        
        return cell
    }
}

extension DiningModeVC: UITableViewDelegate {
    
}

extension String {
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }
}
