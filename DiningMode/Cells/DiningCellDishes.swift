//
//  DiningCellDishes.swift
//  DiningMode
//
//  Created by Scott Delly on 2/15/17.
//  Copyright © 2017 OpenTable, Inc. All rights reserved.
//

import UIKit

class DiningCellDishes: UICollectionViewCell {
    
    @IBOutlet weak var tableView: UITableView!
    
}

class CellDish: UITableViewCell {
    
    @IBOutlet weak var imageViewDish: OTImageView!
    @IBOutlet weak var labelSnippet: UILabel!
    
}
