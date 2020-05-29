This app provides a way to plot geo locations in the real world of AR and Map. In AR, we plot each elements in the form of 3D, and those plotted elements will be based on the current user location as per the centre point. (Based on the radius defined by user). 

In the same way, the existing plotted elements will be shown as a default location in the device map, through this user can experience the 2D visualization. 

We have provided the support for both AR and Map in a single screen of advanced visualization. We use latitude and longitude to drop annotation /node for the each offers on the based upon selecting any annotation/node and helps user to navigate to Location details.

Prerequisites 
-------------
Supported OS - 
 iOS 11 and above.
 
Supported Devices - 
-------------

The devices that use A9, A10 and A11 chips are:
•    iPhone 6s and 6s Plus
•    iPhone 7 and 7 Plus
•    iPhone SE
•    iPad Pro (9.7, 10.5 or 12.9) – both first-gen and 2nd-gen
•    iPad (2017)
•    iPhone 8 and 8 Plus
•    All versions after iPhone X
•     
Supported XCode version (For development) - XCode 10.0 and above
 
Frameworks Used -  ARKit, CoreLocation and MapKit
 

Permission Required:
-------------

•    Camera  - Camera and motion data helps to map out the real world as users moves around.
•    Location - Wi-Fi and GPS data to determine current location with a low degree of accuracy. 
Add NSCameraUsageDescription and NSLocationWhenInUseUsageDescription to plist with a brief explanation.

#Code Overview:

Sample_offers JSON file, 
-------------
We have created an array for the each dictionaries. The dictionaries will have the location details like (Latitude, Longitude and Altitude) to be used for AR, whereas Latitude and Longitude will be used for Map. Once we tap on any location/item, we load location details screen with the few mocked descriptions. 
Note – In app Latitude, Longitude, Altitude will be initially empty in JSON file and those values will be updated at runtime depending upon the user current location.

ARViewController swift file, 
-------------
* readLocationJson() : method for parsing JSON file to array of LocationModel (where LocationModel is the class used to store each location objects). 

* getRandomLocation() : To identify the random location in and around for the user’s current location. The random location applicable only for demo purposes, it is not applicable for real time implementation.

* getAddressFromCoordinates() : For getting the address of random location. (This is applicable only for demo purposes, it is not applicable for real time implementation)

* plotCoordinates() : Plotting both AR Annotation and Map Annotation view, While plotting annotation need to check for the collision and based on that need adjust position in Y- axis.

* translateNode() : This is the base method for generating SCNVector3 (X,Y, Z) for the offer location from the users current location.

* transformMatrix() : This method will multiply the matrix and transformed matrix

* bearingBetweenLocations() : This method will calculate the angle of the offer location from the users current location.

* rotateAroundY() : This method will rotate the matrix using the angle which will be calculated using the  bearingBetweenLocations method.

* getTranslationMatrix() : This method will translate the matrix with the distance in Z position.


* handleTap(rec: UITapGestureRecognizer) : On clicking SCNNode in ARSCNView user’s will take it to detail screen.

* mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) : On clicking Annotation in MKMapView user’s will take it to detail screen.


Constants swift file, 
-------------
* maximumDistance : Offers will not be added when distance from your current location going beyond the maximumDistance meter, (i.e. SCNNode will not be added to ARSCNView).

* randomLocationLimit : Increasing or decreasing the random location LAT & LONG distance from current location. (0.0001 lower which will plot location which is less then 10 meter)

* minimumLocationLimit : Offers will not be added when distance from your current location going below the minimumLocationLimit meter, In this case SCNNode to be adjusted as per the scaling factor to make visible.

