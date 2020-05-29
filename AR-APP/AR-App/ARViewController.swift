//
//  ViewController.swift
//  AR-App
//
//  Created by Rooban Abraham on 29/08/19.
//  Copyright © 2019 Rooban Abraham. All rights reserved.
//

import UIKit
import CoreLocation
import SceneKit
import ARKit
import MapKit


class ARViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var mapView: MKMapView!
    var isARView: Bool = true
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation ()
    var offersArray =  Array<Any> ()
    

    var scene = SCNScene()

    var locationNodes: [SCNNode] = []
    var locationDetermined: Bool!

    
    @IBAction func segmentChange(_ sender: Any) {
        self.mapView.isHidden = false
        self.sceneView.isHidden = false
        
        self.isARView = !self.isARView
        if (self.isARView == true) {
            UIView.transition(with: self.sceneView,
                              duration: 0.5,
                              options: [.transitionFlipFromRight],
                              animations: {
                                self.sceneView.isHidden = false
                                self.mapView.isHidden = true
            }, completion: nil)
            
        } else {
            UIView.transition(with: self.mapView,
                              duration: 0.5,
                              options: [.transitionFlipFromRight],
                              animations: {
                                self.sceneView.isHidden = true
                                self.mapView.isHidden = false
                                
                                self.mapView.showsUserLocation = true
                                //We can change the Map Type among following options.
                                // standard, satellite, hybrid, satelliteFlyover, hybridFlyover, mutedStandard
                                self.mapView.mapType = .standard
                                self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                                //self.mapView.fitAllAnnotations()
            }, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        locationDetermined = false

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
 
    // CLLocationManagerDelegate.
    
    //this method will be called each time when a user change his location access preference.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location!
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        self.scene = SCNScene()
        readLocationJson()
        self.plotCordinate()
        
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        self.sceneView.addGestureRecognizer(tapRec)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did location updates is called but failed getting location \(error)")
    }
    
    //Detail Naviagation: 1. Method called when user taps on the AR annotation in AR View.
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: self.sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                let tappedNode = hits.first?.node
                let index:Int! = Int(tappedNode?.name ?? "0")
                
                if (self.offersArray.count > 0) {
                    let dealObj = self.offersArray[index] as? LocationModel
                    self.performSegue(withIdentifier: "DetailViewController", sender: dealObj)
                }
            }
        }
    }
    
    //Detail Naviagation: 2. Delegate method called when user taps on the Map annotation in Map View.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let arAnnotation = view.annotation as? ARAnnotation {
            let dealObj = arAnnotation.locationModel
            self.performSegue(withIdentifier: "DetailViewController", sender: dealObj)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
        if segue.identifier == "DetailViewController" {
            if let destination = segue.destination as? DetailViewController {
                destination.dealObj = sender as? LocationModel
            }
        }
    }
    
    // Method which will perform Haversine Formula calculation.
    func translateNode (_ location: CLLocation) -> SCNVector3 {
        let locationTransform = transformMatrix(matrix_identity_float4x4, self.currentLocation, location)
        return positionFromTransform(locationTransform)
    }
    
    // Multiply both matrices (remember, the order is important) to combine them
    func transformMatrix(_ matrix:simd_float4x4,_ originLocation:CLLocation, _ offerLocation: CLLocation) -> simd_float4x4 {
        let bearing = bearingBetweenLocations(originLocation, offerLocation)
        let rotationMatrix = rotateAroundY(matrix_identity_float4x4, Float(bearing))
        let distance = Float(originLocation.distance(from: offerLocation))
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = getTranslationMatrix(matrix_identity_float4x4, position)
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
    
    // Calculate the bearing using the formula : atan2 (sin(long2 – long1) * cos(long2),cos(lat1) * sin(lat2) – sin(lat1) * cos(lat2) * cos(long2 – long1))
    func bearingBetweenLocations(_ originLocation: CLLocation, _ offerLocation: CLLocation) -> Double {
        let lat1 = originLocation.coordinate.latitude.toRadians()
        let lon1 = originLocation.coordinate.longitude.toRadians()
        let lat2 = offerLocation.coordinate.latitude.toRadians()
        let lon2 = offerLocation.coordinate.longitude.toRadians()
        let longitudeDiff = lon2 - lon1
        let y = sin(longitudeDiff) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDiff);
        return atan2(y, x)
    }
    
    // Get a rotation matrix in the y-axis using that bearing.
    func rotateAroundY(_ matrix: simd_float4x4, _ degrees: Float) -> simd_float4x4
    {
        var matrix = matrix
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    // Create a four-element vector with the distance in the z position to get a translation matrix
    func getTranslationMatrix(_ matrix:simd_float4x4, _ translation:vector_float4)->simd_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    // Transform the matrix.
    func positionFromTransform(_ transform: simd_float4x4) -> SCNVector3 {
        return SCNVector3Make(
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z
        )
    }
    
    //*** OFFERS ***
    
    private func readLocationJson() {
        do {
            if let file = Bundle.main.url(forResource: "sample_offers", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                let locationInformation = json.value(forKey: "offersList") as! NSArray
                //In this method we get data from "sample_offers.json"
                // We will get near by random locations from user current location.
                getAddressFromCoordinates(locationInformation:locationInformation)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // *** For getting Random Location Close to Current User Location "Near By" ***
    func getRandomLocation(centerLatitude: Double, centerLongitude: Double, deltaLat: Double, deltaLon: Double, altitudeDelta: Double) -> (location:CLLocation,altitude:CLLocationDistance)
    {
        var lat = centerLatitude
        var lon = centerLongitude
        
        let latDelta = -(deltaLat / 2) + drand48() * deltaLat
        let lonDelta = -(deltaLon / 2) + drand48() * deltaLon
        lat = lat + latDelta
        lon = lon + lonDelta
        
        let altitude = drand48() * altitudeDelta
        return (location:CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: altitude, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 0, timestamp: Date()),altitude:altitude)
    }
    
    @objc func getAddressFromCoordinates(locationInformation:NSArray){
    
        for (_ , value) in locationInformation.enumerated() {
            let locationInfo = value as! NSDictionary
            let locationModel = LocationModel()
            
            // Create random annotations around center point
            let deltaLat =  Constants.shared.randomLocationLimit
            let deltaLon =  Constants.shared.randomLocationLimit
            let altitudeDelta: Double = 0
            
            let location = self.getRandomLocation(centerLatitude: self.currentLocation.coordinate.latitude, centerLongitude: self.currentLocation.coordinate.longitude, deltaLat: Double(deltaLat), deltaLon: deltaLon, altitudeDelta: altitudeDelta)
            
            
            let ceo: CLGeocoder = CLGeocoder()
            ceo.reverseGeocodeLocation(location.location, completionHandler:
                {(placemarks, error) in
                    if (error != nil)
                    {
                        print("reverse geodcode fail: \(error!.localizedDescription)")
                    }
                    let pm = placemarks! as [CLPlacemark]
                    if pm.count > 0 {
                        let pm = placemarks![0]
                        var addressString : String = ""
                        if pm.subLocality != nil {
                            addressString = addressString + pm.subLocality! + ", "
                        }
                        if pm.thoroughfare != nil {
                            addressString = addressString + pm.thoroughfare! + ", "
                        }
                        if pm.locality != nil {
                            addressString = addressString + pm.locality! + ", "
                        }
                        if pm.country != nil {
                            addressString = addressString + pm.country! + ", "
                        }
                        if pm.postalCode != nil {
                            addressString = addressString + pm.postalCode! + " "
                        }
                        locationModel.address = addressString
                    }
            })
            
            locationModel.latitude = location.location.coordinate.latitude
            locationModel.longitude = location.location.coordinate.longitude
            locationModel.altitude = location.altitude
            locationModel.name = locationInfo.value(forKey: "merchantName") as? String
            locationModel.offers = locationInfo.value(forKey: "shortMessage") as? String
            locationModel.offerDescription = locationInfo.value(forKey: "expandedMessage") as? String
            locationModel.pinCoordinate = CLLocationCoordinate2D(latitude: locationModel.latitude! , longitude: locationModel.longitude! )
            locationModel.pinLocation = CLLocation(coordinate: locationModel.pinCoordinate, altitude: locationModel.altitude!)

            let distance = Float(self.currentLocation.distance(from: locationModel.pinLocation))
            locationModel.distance = String(Int(distance)) + " meter"
            
            // Do any additional setup after loading the view.
            let arAnnotationView = (Bundle.main.loadNibNamed("AnnotationView", owner: nil, options: nil)?.first as? UIView as! AnnotationView)
            arAnnotationView.offerLbl.text = locationModel.name
            arAnnotationView.offerDesc.text = locationModel.offers
            arAnnotationView.offerImg.image = (UIImage (named: "Deals"))
            arAnnotationView.offerDistance.text = locationModel.distance
            locationModel.annotationView = arAnnotationView
        
            
            let annotation = ARAnnotation()
            annotation.locationModel = locationModel
            annotation.title = locationModel.name
            annotation.subtitle = locationModel.offers
            annotation.coordinate = locationModel.pinCoordinate
            locationModel.annotation = annotation
            
            offersArray.append(locationModel)
        }
    }
    
    func plotCordinate() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        // Get sorted array in descending order (largest to the smallest number)
        // We need to plot the node from far to nearest order. (So that nearest will be always visible to user)
        self.offersArray = self.offersArray.sorted(by: { ($0 as! LocationModel).distance > ($1 as! LocationModel).distance })
        
        for  (index , model) in self.offersArray.enumerated() {
            let locationModel = model as! LocationModel
            let plane1 = SCNPlane(width: (locationModel.annotationView.frame.size.width / 100) * 0.10, height: (locationModel.annotationView.frame.size.height / 100) * 0.10)
            let annoImg :UIImage = locationModel.annotationView.asImage()
            let annotationImg = annoImg.withRoundedCorners(radius: 5)
            plane1.firstMaterial!.diffuse.contents = annotationImg
            plane1.firstMaterial!.lightingModel = .constant
            
            let offerNode   = SCNNode ()
            offerNode.name = String(index)
            offerNode.geometry = plane1
            
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = SCNBillboardAxis.Y
            offerNode.constraints = [billboardConstraint]
            
            var position = translateNode(locationModel.pinLocation)
            var scale = SCNVector3(x: 100, y: 100, z: 100)
     
            //Should not allow user to view SCNNode which is far from allowed maximum distance.
            let distance = Float(self.currentLocation.distance(from: locationModel.pinLocation))
            if (distance > Constants.shared.maxmimumDistance) {
                continue
            }
            
            // If distance is more than 100 meter, In that case particular node wont visible to user.
            // For makeing it to visible we need to scale the view based on percentage calculation.
            if (distance > 100) {
                position = SCNVector3(
                    x: position.x/Float(Constants.shared.minimumLocationLimit),
                    y: 0,
                    z: position.z/Float(Constants.shared.minimumLocationLimit))
                
                let scaleLimit = Float(Constants.shared.minimumLocationLimit)/2
                scale = SCNVector3(x: distance/scaleLimit, y: distance/scaleLimit, z: distance/scaleLimit)
            } else if (distance < 25) {
                position = SCNVector3(
                    x: position.x*Float(Constants.shared.minimumLocationLimit),
                    y: 0,
                    z: position.z*Float(Constants.shared.minimumLocationLimit))
                
                let scaleLimit = Float(Constants.shared.minimumLocationLimit)*10
                scale = SCNVector3(x: scaleLimit, y: scaleLimit, z: scaleLimit)
            }
            
            
            //Check for collision with other nodes and rearrange the node.
            for (_ , annotationNode) in self.locationNodes.enumerated() {
                let node = annotationNode
                if ( CGFloat(position.x - node.position.x) < CGFloat(scale.x + 10) || ( CGFloat(position.y - node.position.y) < CGFloat(scale.y + 10) ) || ( CGFloat(position.z - node.position.z) < CGFloat(scale.z + 10) ) ) { // 10 for padding
                    
                    //Check for Y -axis if it goes beyond 200 then restrict to 200.
                    //Then it will be visible to user without moving mobile to top.
                    if (position.y > 200) {
                        position = SCNVector3(
                            x: position.x,
                            y: (Float(CGFloat(position.y) - CGFloat(scale.y/15))),
                            z: position.z)
                    } else {
                        position = SCNVector3(
                            x: position.x,
                            y: (Float(CGFloat(position.y) + CGFloat(scale.y/15))), // 15 meter for padding to move upward
                            z: position.z)
                    }
                }
            }
            
            offerNode.position = position
            offerNode.scale = scale
            locationModel.annotationView.offerLbl.text = locationModel.name
            locationModel.annotationView.offerDesc.text = locationModel.offers
            locationModel.annotationView.offerImg.image = (UIImage (named: "Deals"))
            
            self.mapView.addAnnotation( locationModel.annotation)
            locationDetermined = true
            
            locationModel.annotationNode = offerNode
            self.locationNodes.append(offerNode)
            scene.rootNode.addChildNode(offerNode)
        }
        
        sceneView.scene = scene
        SCNTransaction.commit()
    }
    
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIImage {
    // image with rounded corners
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class ARAnnotation : MKPointAnnotation {
    var locationModel:LocationModel?
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

public extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance) {
        self.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
    }
}

