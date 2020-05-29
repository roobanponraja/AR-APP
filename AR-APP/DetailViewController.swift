//
//  DetailViewController.swift
//  ARLocation
//
//  Created by Rooban Abraham on 08/08/19.
//  Copyright © 2019 Rooban Abraham All rights reserved.
// 


import UIKit

class DetailViewController: UIViewController {
    
    var  dealObj : LocationModel?
    @IBOutlet weak var headingLbl: UILabel?
    @IBOutlet weak var addressLbl: UILabel?
    @IBOutlet weak var descriptionLbl: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

         self.navigationItem.title = "AR Detail View"
        
        self.headingLbl?.text = dealObj?.name
        self.addressLbl?.text = dealObj?.address
        self.descriptionLbl?.text = dealObj?.offerDescription
    }
}
