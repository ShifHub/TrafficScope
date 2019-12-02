//
//  Departure.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 10/13/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import Foundation

class DepartureDate: NSObject, NSCoding
{
    var date: Date {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.short
            dateFormatter.timeStyle = DateFormatter.Style.short
            dateFormatter.dateFormat = "hh:mm a"
            self.dateAsString = dateFormatter.string(from: date)
        }
    }
    var dateAsString: String
    
    init(date: Date)
    {
        self.date = date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "hh:mm a"
        self.dateAsString = dateFormatter.string(from: date)
    }
    
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(date, forKey: "date")
        aCoder.encode(dateAsString, forKey:"dateAsString")
    }
    
    
    required init?(coder: NSCoder)
    {
        self.date = coder.decodeObject(forKey: "date") as! Date
        self.dateAsString = coder.decodeObject(forKey: "dateAsString") as! String
    }
}
