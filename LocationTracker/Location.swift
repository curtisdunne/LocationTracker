//
//  Location.swift
//  LocationTracker
//
//  Created by CURTIS DUNNE on 7/19/18.
//  Copyright © 2018 CURTIS DUNNE. All rights reserved.
//

import UIKit
import CoreLocation
import RealmSwift

@objcMembers class Location: Object {
    dynamic var latitude: Double = 0.0
    dynamic var longitude: Double = 0.0
    dynamic var address: String = ""
    
    convenience init(latitude: Double, longitude: Double, address: String) {
        self.init()
        
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

extension Location {
    static func all(in realm: Realm = try! Realm()) -> Results<Location> {
        return realm.objects(Location.self)
    }

    @discardableResult
    static func add(latitude: Double, longitude: Double, address: String, in realm: Realm = try! Realm()) -> Location {
        let location = Location(latitude: latitude, longitude: longitude, address: address)
        
        try! realm.write {
            realm.add(location)
        }
        
        return location
    }
}

