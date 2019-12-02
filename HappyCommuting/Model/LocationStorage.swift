//
//  LocationStorage.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 7/20/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import MapKit
import Foundation
import CoreLocation
import Contacts

class LocationsStorage
{
    static let shared = LocationsStorage()
    var homePlacemark: CLPlacemark?
    var homeMKMapItem: MKMapItem?
    var destinationPlacemark: CLPlacemark?
    var destinationMKMapItem: MKMapItem?
    var settingsCellTapped: String? // "H" for Home or "D" for Destination.

    
    func saveHomePlacemark(placemark: CLPlacemark)
    {
        do
        {
            let encodeData = try NSKeyedArchiver.archivedData(withRootObject: placemark, requiringSecureCoding: false)
            UserDefaults.standard.set(encodeData, forKey: "HomePlacemark")
        }
        catch
        {
            print(error)
        }
    }
    
    func saveDestinationPlacemark(placemark: CLPlacemark)
    {
        do
        {
            let encodeData = try NSKeyedArchiver.archivedData(withRootObject: placemark, requiringSecureCoding: false)
            UserDefaults.standard.set(encodeData, forKey: "DestinationPlacemark")
        }
        catch
        {
            print(error)
        }
    }
    
    
    func loadHomePlacemark()
    {
        if UserDefaults.standard.object(forKey: "HomePlacemark") != nil
        {
            do
            {
                let decoded = UserDefaults.standard.object(forKey: "HomePlacemark") as! Data
                homePlacemark =  try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? CLPlacemark)
                if let homePM = homePlacemark
                {
                    homeMKMapItem = MKMapItem(placemark: MKPlacemark(placemark: homePM))
                }
                print("home placemark loaded")
            }
            catch
            {
                print(error)
            }
        }
    }
    
    func loadDestinationPlacemark()
    {
        if UserDefaults.standard.object(forKey: "DestinationPlacemark") != nil
        {
            do
            {
                let decoded = UserDefaults.standard.object(forKey: "DestinationPlacemark") as! Data
                destinationPlacemark =  try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? CLPlacemark)
                if let destinationPM = destinationPlacemark
                {
                    destinationMKMapItem = MKMapItem(placemark: MKPlacemark(placemark: destinationPM))
                }
                print("destination placemark loaded")
            }
            catch
            {
                print(error)
            }
        }
    }
}

