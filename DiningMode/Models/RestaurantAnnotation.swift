//
//  RestaurantAnnotation.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit
import MapKit

class RestaurantAnnotation: NSObject, MKAnnotation {

    let title: String?
    let coordinate: CLLocationCoordinate2D
    let streetAddress: String
    let cityName: String
    let stateAbbreviation: String
    let postalCode: String
    
    init(title: String, coordinate: CLLocationCoordinate2D, streetAddress: String, cityName: String, stateAbbreviation: String, postalCode: String) {
        self.title = title
        self.coordinate = coordinate
        self.streetAddress = streetAddress
        self.cityName = cityName
        self.stateAbbreviation = stateAbbreviation
        self.postalCode = postalCode
        
        super.init()
    }
    
    convenience init(reservation: Reservation) {
        let restaurantName = reservation.restaurant.name
        let coordinate = reservation.restaurant.location.coordinate
        let streetAddress = reservation.restaurant.street
        let cityName = reservation.restaurant.city
        let state = reservation.restaurant.state
        let postalCode = reservation.restaurant.zip
        
        self.init(title: restaurantName, coordinate: coordinate, streetAddress: streetAddress, cityName: cityName, stateAbbreviation: state, postalCode: postalCode)
    }
    
    func fullAddress() -> String {
        return "\(self.streetAddress) \(self.cityName), \(self.stateAbbreviation) \(self.postalCode)"
    }
    
}
