//
//  WeatherData.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 8/6/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import SwiftyJSON

struct WeatherData {

    var temperature: String
    var tempHigh: String
    var tempLow: String
    var description: String
    var icon: String

    init(data: Any) {
        let json = JSON(data)
        let currentWeather = json["currently"]
        let dailyWeather = json["daily"]["data"][0]

        func initTemp(jsonItem: JSON) -> String {
            if let responseItem = jsonItem.float {
                return String(format: "%.0f", responseItem)
            } else {
                return "--"
            }
        }
        print("initialized WeatherData item")
        
    
        
        self.temperature = initTemp(jsonItem: currentWeather["temperature"]) + " ºF"
        self.tempHigh = initTemp(jsonItem: dailyWeather["temperatureHigh"])
        self.tempLow = initTemp(jsonItem: dailyWeather["temperatureLow"])
    

        self.description = currentWeather["summary"].string ?? "--"
        self.icon = dailyWeather["icon"].string ?? "--"
        //init the self.high value
        //init the self.low value
        
        
    }
}
