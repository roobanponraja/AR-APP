//
//  LocationModel.swift
//  ARLocation
//
//  Created by Rooban Abraham on 20/06/19.
//  Copyright © 2019 Rooban Abraham. All rights reserved.
// 


import UIKit
import CoreLocation
import MapKit
import ARKit

class LocationModel: NSObject {
    var latitude : Double!
    var longitude : Double!
    var altitude : Double!
    var name : String!
    var offers : String!
    var imageURL : String!
    var distance : String!
    var pinCoordinate : CLLocationCoordinate2D!
    var pinLocation : CLLocation!
    var annotationView : AnnotationView!
    var annotationNode : SCNNode!
    var annotation :MKPointAnnotation!
    var address :String!
    var offerDescription :String!
    override init() {
        
    }
}
