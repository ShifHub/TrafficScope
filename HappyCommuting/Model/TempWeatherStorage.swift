//
//  WeatherTempStorage.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 9/19/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import Foundation
import UIKit

class TempWeatherStorage {
    static let shared = TempWeatherStorage()
    var currentWeatherData: WeatherData?
    var newWeatherNeeded = true
    
    /*
    Keys are possible responses from DarkSkiWeather API.
    Values are the file name for the proper icon to represent them.
    *Uses apples built-in icons*
    */
    let iconResponseDictionary: [String: String] =
        [
            "clear-day": "sun.max",
            "clear-night": "moon.stars",
            "rain": "cloud.rain",
            "snow": "cloud.snow",
            "wind": "wind",
            "fog": "cloud.fog",
            "cloudy": "cloud",
            "partly-cloudy-day": "cloud.sun",
            "partly-cloudy-night": "cloud.moon",
            "hail": "cloud.hail",
            "thunderstorm": "cloud.bolt.rain",
            "tornado": "tornado"
        ]
    
    
}
