//
//  ViewController.swift
//  LocationTracker
//
//  Created by CURTIS DUNNE on 7/19/18.
//  Copyright © 2018 CURTIS DUNNE. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import RealmSwift

let ZOOM_FACTOR_LAT = 0.03
let ZOOM_FACTOR_LON = 0.03

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    var locations: Results<Location>?
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startMonitoringSignificantLocationChanges()
        
        locations = Location.all()
        guard locations != nil else { return }

        pinEachLocation()
    }
    
    func createLocationPoint(location: CLLocation) {
        let latitude: CLLocationDegrees = location.coordinate.latitude
        let longitude: CLLocationDegrees = location.coordinate.longitude
        
        let latitudeZoomFactor: CLLocationDegrees = ZOOM_FACTOR_LAT
        let longitudeZoomFactor: CLLocationDegrees = ZOOM_FACTOR_LON
        let span: MKCoordinateSpan = MKCoordinateSpanMake(latitudeZoomFactor, longitudeZoomFactor)
        
        let locationCoord: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(locationCoord, span)
        
        self.map.setRegion(region, animated: true)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            var address = "* Unknown *"
            
            if error != nil {
                print("A reverse Geo-location error has occurred: \(String(describing: error?.localizedDescription))")
            } else {
                if let placemarks = placemarks {
                    let p = CLPlacemark(placemark: placemarks[0])
                    address = self.buildAddressString(placemark: p)
                    
                    let locationData: Location = Location(latitude: latitude, longitude: longitude, address: address)
                    
                    self.createAnnotationAt(location: locationCoord, address: address)
                    
                    // TODO: add new record to realm
                    let realm = try! Realm()
                    try! realm.write {
                        realm.add(locationData)
                    }
                }
            }
        }
    }

    func buildAddressString(placemark: CLPlacemark) -> String {
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare,
           let subLocality = placemark.subLocality,
           let subAdministrativeArea = placemark.subAdministrativeArea,
           let postalCode = placemark.postalCode,
           let country = placemark.country {
            return "\(subThoroughfare) \(thoroughfare) \n \(subLocality) \n \(subAdministrativeArea) \n \(postalCode)) \n \(country)"
        } else if let thoroughfare = placemark.thoroughfare,
                  let subLocality = placemark.subLocality,
                  let subAdministrativeArea = placemark.subAdministrativeArea,
                  let postalCode = placemark.postalCode,
                  let country = placemark.country {
            return "\(thoroughfare) \n \(subLocality) \n \(subAdministrativeArea) \n \(postalCode) \n \(country)"
        } else if let subLocality = placemark.subLocality,
                  let subAdministrativeArea = placemark.subAdministrativeArea,
                  let postalCode = placemark.postalCode,
                  let country = placemark.country {
            return "\(subLocality) \n \(subAdministrativeArea) \n \(postalCode) \n \(country)"
        } else if let subAdministrativeArea = placemark.subAdministrativeArea,
                  let postalCode = placemark.postalCode,
                  let country = placemark.country {
            return "\(subAdministrativeArea) \n \(postalCode) \n \(country)"
        } else if let postalCode = placemark.postalCode,
                  let country = placemark.country {
            return "\(postalCode) \n \(country)"
        } else if let country = placemark.country {
            return "\(country))"
        }
        
        return "* Unknown *"
    }
    
    func pinEachLocation() {
        if let locations = self.locations {
            for location in locations {
                let annotateLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                createAnnotationAt(location: annotateLocation, address: location.address)
            }
        }
    }
    
    func createAnnotationAt(location: CLLocationCoordinate2D, address: String) {
        DispatchQueue.main.async {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "🚶🏻‍♂️"
            annotation.subtitle = address
            
            self.map.addAnnotation(annotation)
        }
    }

    // MARK: CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        
        DispatchQueue.main.async {
            self.createLocationPoint(location: location)
        }
    }
}

