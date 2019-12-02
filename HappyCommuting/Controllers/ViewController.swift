//
//  ViewController.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 6/10/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class TrafficTimeViewCell: UITableViewCell
{
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var departureTimeLabel: UILabel!
    @IBOutlet weak var trafficTimeLabel: UILabel!
}

class ViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource
{
  
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var workAddressLabel: UILabel!
    @IBOutlet weak var currentTrafficTimeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var highAndLowTempLabel: UILabel!
    @IBOutlet weak var weatherDescriptionLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var trafficTableView: UITableView!
    
    
    var currentWeatherData: WeatherData?
    
    let locationManager = CLLocationManager()
    
    let lStorage = LocationsStorage.shared
    let dStorage = DateStorage.shared
    
    var homePlacemark: CLPlacemark?
    var destinationPlacemark: CLPlacemark?
    var eTD: DepartureDate?
    var uTD: DepartureDate?
    
    var trafficTimes: [Int : String] = [:]
    var departureTimes: [Int: Date] = [:]
    var passedTimes: [Int: Bool] = [:]
    
    override func viewDidLoad()
    {
        trafficTableView.dataSource = self
        trafficTableView.delegate = self
        super.viewDidLoad()
        navigationBarSetup()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        setUpLocations()
        
        super.viewWillAppear(animated)
            self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    func setUpLocations()
    {
        if homePlacemark != lStorage.homePlacemark || destinationPlacemark != lStorage.destinationPlacemark
        {
            homePlacemark = lStorage.homePlacemark
            destinationPlacemark = lStorage.destinationPlacemark
            trafficTimes = [:]
            departureTimes = [:]
        }
        
        if eTD != dStorage.earliestTimeDeparture || uTD != dStorage.usualTimeDeparture
        {
            eTD = dStorage.earliestTimeDeparture
            uTD = dStorage.usualTimeDeparture
            trafficTimes = [:]
            departureTimes = [:]
        }
        
        updateLocationLabels()
        
        if lStorage.destinationPlacemark != nil
        {
            getWeather()
            if lStorage.homePlacemark != nil
            {
                getCurrentTrafficTime()
            }
        }
        updateWeatherLabels()
        
        if dStorage.usualTimeDeparture != nil && dStorage.earliestTimeDeparture != nil
        {
            print("Both are loaded successfully!")
            trafficTableView.reloadData()
        }
        
        
    }
    
    func getWeather()
    {
        if TempWeatherStorage.shared.newWeatherNeeded
        {
            DarkSkyService.weatherForCoordinates(latitude: String(Double((LocationsStorage.shared.destinationPlacemark!.location?.coordinate.latitude)!)), longitude: String(Double((LocationsStorage.shared.destinationPlacemark!.location?.coordinate.longitude)!)))
                { (response, error) in
                    TempWeatherStorage.shared.currentWeatherData = response
                    TempWeatherStorage.shared.newWeatherNeeded = false
                    self.updateWeatherLabels()
                }
        }
        else
        {
            self.updateWeatherLabels()
        }
    }
    
    func updateWeatherLabels()
    {
        if let weather = TempWeatherStorage.shared.currentWeatherData
        {
            self.temperatureLabel.text = weather.temperature
            self.highAndLowTempLabel.text = weather.tempHigh + "/" + weather.tempLow
            self.weatherDescriptionLabel.text = weather.description
            if #available(iOS 13.0, *) {
                self.weatherIcon.image = UIImage(systemName: TempWeatherStorage.shared.iconResponseDictionary[weather.icon]!)
            } else {
                self.weatherIcon.image = UIImage(named: weather.icon)
                
            }
        }
    }
    
    func updateLocationLabels()
    {
        if let destinationPlacemark = lStorage.destinationPlacemark
        {
            if workAddressLabel.text != destinationPlacemark.name
            {
                workAddressLabel.text = destinationPlacemark.name
            }
        }
    }
    
    func format(_ duration: TimeInterval) -> String
    {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        if duration >= 3600
        {
            formatter.allowedUnits.insert(.hour)
        }
        return formatter.string(from: duration)!
    }
    
    func abreviatedFormat(_ duration: TimeInterval) -> String
    {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated

        formatter.allowedUnits = [.minute, .second]
        if duration >= 3600
        {
            formatter.allowedUnits.insert(.hour)
        }

        let string = formatter.string(from: duration)
        if string != nil
        {
            return string!
        }
        else
        {
            return "error"
        }
    }
    
    func getFutureTrafficTimes(homeMapItem: MKMapItem, destMapItem: MKMapItem, departureDate: Date, indexPath: IndexPath) -> TimeInterval
    {
        let request = MKDirections.Request()
        request.source = homeMapItem
        request.destination = destMapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        request.departureDate = departureDate
        var traffic = TimeInterval()
        
        let group = DispatchGroup()
        let queue = DispatchQueue.global()
        
        group.enter()
        queue.async
            {
                let directions = MKDirections(request: request)
                directions.calculateETA { (response, error) in
                    if let response = response
                    {
                        traffic = TimeInterval(response.expectedTravelTime)
                        if let cell = self.trafficTableView.cellForRow(at: indexPath) as! TrafficTimeViewCell?
                        {
                            cell.trafficTimeLabel.text = self.abreviatedFormat(traffic)
                        }
                        self.trafficTimes[indexPath.row] = self.abreviatedFormat(traffic)
                        group.leave()
                    } else {
                        traffic = TimeInterval()
                    }
                    if error != nil {
                        group.leave()
                    }
            }
        }
        return traffic
    }
    
    func getCurrentTrafficTime()
    {
        //Function Linked To: updateUILabels()
        if let homeMKMapItem = lStorage.homeMKMapItem
        {
            if let destinationMKMapItem = lStorage.destinationMKMapItem
            {
                let request = MKDirections.Request()
                request.source = homeMKMapItem
                request.destination = destinationMKMapItem
                request.transportType = .automobile
                request.requestsAlternateRoutes = false

                let directions = MKDirections(request: request)
                directions.calculateETA { (response, error) in
                    let traffic = response?.expectedTravelTime
                    self.currentTrafficTimeLabel.text = self.abreviatedFormat(traffic ?? TimeInterval())
                }
            }
        }
    }
    
    func handleError(message: String, title: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //TODO:- TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if dStorage.earliestTimeDeparture == nil || dStorage.usualTimeDeparture == nil || lStorage.destinationPlacemark == nil || lStorage.homePlacemark == nil
        {
            return 0
        }
        
        let rows = DateStorage.shared.timeDifference()
        
        if rows == 0
        {
            return 0
        }
        else
        {
            return DateStorage.shared.timeDifference() / 5 + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "traffic cell", for: indexPath) as! TrafficTimeViewCell
        
        cell.departureTimeLabel.textColor = UIColor(named: "titleLabelColor")
        if let time = departureTimes[indexPath.row]
        {
            cell.departureTimeLabel.text = time.timeToString()
            if passedTimes[indexPath.row]!
            {
                cell.departureTimeLabel.textColor = UIColor.red
                cell.trafficTimeLabel.textColor = UIColor.red
            }
            else
            {
                cell.departureTimeLabel.textColor = UIColor(named: "titleLabelColor")
                cell.trafficTimeLabel.textColor = UIColor(named: "titleLabelColor")
            }
        }
        else
        {
            let dateMinusMinutes = DateStorage.shared.usualTimeDeparture!.date.adding(minutes: -((indexPath.row)*5))
            print(dateMinusMinutes.description)
            print(dateMinusMinutes.timeToString().description)
            cell.departureTimeLabel.text = dateMinusMinutes.timeToString()
            departureTimes[indexPath.row] = dateMinusMinutes
            
            if dateMinusMinutes < Date()
            {
                cell.departureTimeLabel.textColor = UIColor.red
                cell.trafficTimeLabel.textColor = UIColor.red
                passedTimes[indexPath.row] = true
                
            }
            else
            {
                cell.departureTimeLabel.textColor = UIColor(named: "titleLabelColor")
                cell.trafficTimeLabel.textColor = UIColor(named: "titleLabelColor")
                passedTimes[indexPath.row] = false
            }
        }
        
        if let traf = trafficTimes[indexPath.row]
        {
            cell.trafficTimeLabel.text = traf
        }
        else
        {
            
            let traffic = format(getFutureTrafficTimes(homeMapItem: LocationsStorage.shared.homeMKMapItem!, destMapItem: LocationsStorage.shared.destinationMKMapItem!, departureDate: departureTimes[indexPath.row]!, indexPath: indexPath))
            cell.trafficTimeLabel.text = traffic
        }

        return cell
    }
    
    //MARK:- TableView - Header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if eTD != nil && uTD != nil
        {
            return "Departure Times and Traffic"
        }
        else
        {
            return "Traffic Date Will Appear Here"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        
        let dummyViewHeight = CGFloat(40)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: dummyViewHeight))
        tableView.contentInset = UIEdgeInsets(top: -dummyViewHeight, left: 0, bottom: 0, right: 0)
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "Wanted M54", size: 14)
        header.textLabel?.textColor = UIColor(named: "titleLabelColor")
        header.textLabel!.center.y = header.center.y
        header.textLabel?.textAlignment = .center
        
        view.tintColor = UIColor(named: "barColor")
        
        
        
    }
    
    
    func navigationBarSetup() {
        self.navigationItem.title = "Traffic Investigator"
        self.navigationController?.navigationBar.titleTextAttributes =
        [
            NSAttributedString.Key.foregroundColor: UIColor(named: "titleLabelColor")!,
            NSAttributedString.Key.font: UIFont(name: "Vogue", size: 21)!
        ]
        
        let menuBtn = settingsButton
        menuBtn?.imageView?.frame = CGRect(x: 0.0, y: 0.0, width: 30, height: 30)
        menuBtn?.setImage(UIImage.init(named:"cogwheel"), for: .normal)
        let menuBarItem = UIBarButtonItem(customView: menuBtn!)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 30)
        
        currHeight?.isActive = true
           self.navigationItem.rightBarButtonItem = menuBarItem
        
    }
    
    func showAlert(title: String, message: String)
        {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okayAction)
                present(alert, animated: true, completion: nil)
        }
}



