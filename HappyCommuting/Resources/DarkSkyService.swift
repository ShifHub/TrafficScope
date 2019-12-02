//
//  DarkSkyService.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 8/6/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import Alamofire


public class DarkSkyService {
    
    private static let apiKey = DarkSkyApiKey
    private static let baseURL = "https://api.darksky.net/forecast/"
    
    static func weatherForCoordinates(latitude: String, longitude: String, completion: @escaping (WeatherData?, Error?) -> ()) {
        let url = baseURL + apiKey + "/\(latitude),\(longitude)"

        request(url).responseJSON { response in
            switch response.result {
                case .success(let result):
                    completion(WeatherData(data: result), nil)
                case .failure(let error):
                    completion(nil, error)

            }

        }
        
    }
    
}


