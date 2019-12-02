//
//  File.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 10/13/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//
//SAVING IS SHORT - NO COMMENTS
//LOADING HAS COMMENTS AT EACH STEP
import Foundation

class DateStorage
{
    static let shared = DateStorage()
    var earliestTimeDeparture: DepartureDate?
    var didSetUTDAheadOneDay = false
    {
        didSet
        {
            print("didSet Proc")
        }
    }
    var usualTimeDeparture: DepartureDate?
    var reloadOfDTsRequired = false
    
    func saveETD(earliestDate: DepartureDate)
    {
        do
        {
            if usualTimeDeparture == nil
            {
                reloadOfDTsRequired = true
            }
            let cleanDate = DepartureDate(date: earliestDate.date.zeroSeconds!)
            let encodeData = try NSKeyedArchiver.archivedData(withRootObject: cleanDate, requiringSecureCoding: false)
            UserDefaults.standard.set(encodeData, forKey: "ETD")
        }
        catch
        {
            print(error)
        }
    }
    
    func saveUTD(usualDate: DepartureDate)
    {
        do
        {
            let encodeData = try NSKeyedArchiver.archivedData(withRootObject: usualDate, requiringSecureCoding: false)
            UserDefaults.standard.set(encodeData, forKey: "UTD")
            if reloadOfDTsRequired || hasPassed(date: usualDate.date)
            {
                loadUTD()
                loadETD()
                reloadOfDTsRequired = false
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func loadETD()
    {
        if UserDefaults.standard.object(forKey: "ETD") != nil
        {
            do
            {
                let decoded = UserDefaults.standard.object(forKey: "ETD") as! Data
                earliestTimeDeparture =  try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? DepartureDate)
                print("ETD Loaded")
                
                
                if earliestTimeDeparture != nil
                {
                    if usualTimeDeparture != nil
                    {
                        if graveyardShiftTest()
                        {
                            earliestTimeDeparture!.date = replace(use: usualTimeDeparture!.date.dayBefore, for: earliestTimeDeparture!.date)
                        }
                        else
                        {
                            earliestTimeDeparture!.date = replace(use: usualTimeDeparture!.date, for: earliestTimeDeparture!.date)
                        }
                        
                        
                    }
                    
                }
            }
            catch
            {
                print(error)
            }
        }
    }
    
    func loadUTD()
    {
        if UserDefaults.standard.object(forKey: "UTD") != nil
        {
            do
            {
                let decoded = UserDefaults.standard.object(forKey: "UTD") as! Data
                usualTimeDeparture =  try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? DepartureDate)
        
                if usualTimeDeparture != nil
                {
                    let today = Date()
                    usualTimeDeparture!.date = replace(use: today, for: usualTimeDeparture!.date)
                    if usualTimeDeparture!.date < today
                    {
                        usualTimeDeparture!.date = replace(use: today.dayAfter, for: usualTimeDeparture!.date)
                        saveUTD(usualDate: usualTimeDeparture!)
                    }
                }
                else
                {
                    print("UTD SHOWS NIL")
                }
            print("UTD Loaded")
            }
            catch
            {
                print(error)
            }
        }
        
    }
    
    func timeDifference() -> Int
    {
        if earliestTimeDeparture != nil && usualTimeDeparture != nil
        {
            var difference = usualTimeDeparture!.date.minutes(from: earliestTimeDeparture!.date)
            print(difference)
            if difference < 0
            {
                usualTimeDeparture!.date = usualTimeDeparture!.date.dayAfter
                saveUTD(usualDate: usualTimeDeparture!)
                difference = usualTimeDeparture!.date.minutes(from: earliestTimeDeparture!.date)
                print("new difference: " + "\(difference)")
            }
            return abs(difference)
        }
        else
        {
            print("returning zero")
            return 0
        }
    }
    
    func replace(use date: Date, for time: Date) -> Date
    {
        let calendar = Calendar.current
        let replacementDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: 0,
            of: date)
        return replacementDate!
    }
    
    func graveyardShiftTest() -> Bool
    {
        let today = Date()
        let etdTestDate = replace(use: today, for: earliestTimeDeparture!.date)
        let utdTestDate = replace(use: today, for: usualTimeDeparture!.date)
        
        if utdTestDate < etdTestDate
        {
            return true
        }
        return false
    }
    
    func hasPassed(date: Date) -> Bool {
        let now = Date()
        if date < now {
            return true
        }
        return false
    }
    
    
}

extension Date
{
    
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    
    var dayBefore: Date
    {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    
    var dayAfter: Date
    {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    
    var noon: Date
    {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    
    var midnight: Date
    {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    var month: Int
    {
        return Calendar.current.component(.month,  from: self)
    }
    
    func minutes(from date: Date) -> Int
    {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    
    
    //MANIUPLATING DATE'S TIME
    var zeroSeconds: Date?
    {
        get
        {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
            return calendar.date(from: dateComponents)
        }
    }
    
    func adding(minutes: Int) -> Date
    {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    //RETURNING FORMATTED STRINGS OF DATE INFO
    
    func timeToString() -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: self)
    }
    
    func getMonthAndDayAndYear() -> String
    {
        let format = DateFormatter()
        format.dateFormat = "MM-dd-yyyy"
        let formattedDate = format.string(from: self)
        return formattedDate
    }
    
    func getDayOfWeek() -> Int? {
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: self)
        return weekDay
    }
    
    func getMonthAndDay() -> String
    {
        let format = DateFormatter()
        format.dateFormat = "MM-dd"
        let formattedDate = format.string(from: self)
        return formattedDate
    }
    
    func getYear() -> Int? {
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.year, from: self)
        return weekDay
    }

}







