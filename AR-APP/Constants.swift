//
//  Constants.swift
//  AR-App
//
//  Created by Rooban Abraham on 13/09/19.
//  Copyright © 2019 Rooban Abraham. All rights reserved.
//

import UIKit

class Constants{
    
    static let shared = Constants()
    
    var maxmimumDistance: Float = 4000.00 // radius in miles (i.e. 2.4 miles)
    var randomLocationLimit: Double = 0.01 // for increasing or decreasing the random lat & Long distance from current location. (0.0001 lower which will plot location which is less then 10 meter)
    var minimumLocationLimit: Double = 100.00 // in meter
    
    //Initializer access level change now
    private init(){}
}

