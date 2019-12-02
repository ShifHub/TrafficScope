//
//  Location.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 7/23/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import Foundation
import CoreLocation

class Location: Codable {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var cLLocation: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    enum LocationType: Int, Codable {
        case home
        case destination
    }
    
    let latitude: Double
    let longitude: Double
    let date: Date
    let dateString: String
    let type: LocationType
    
    
    
    
    init(_ location: CLLocationCoordinate2D, date: Date, type: LocationType) {
        latitude =  location.latitude
        longitude =  location.longitude
        self.date = date
        dateString = Location.dateFormatter.string(from: date)
        self.type = type
    }

    
    
}

