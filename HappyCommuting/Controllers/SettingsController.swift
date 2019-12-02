//
//  SettingsController.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 8/22/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

class SettingsController: UITableViewController
{
    
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var dummyTextField: UITextField!
    @IBOutlet weak var usualDepartureLabel: UILabel!
    @IBOutlet weak var earliestPossibleDeparture: UILabel!
    @IBOutlet weak var currentLocationButtonLabel: UILabel!
    @IBOutlet weak var homeAddressLabel: UILabel!
    @IBOutlet weak var destinationAddresssLabel: UILabel!
    @IBOutlet weak var useCurrentLocationButtonView: UIView!
    @IBOutlet weak var graveyardSwitch: UISwitch!
    
    let defaults = UserDefaults.standard
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var isUpdatingLocation = false
    var lastLocationError: Error?
    let geoCoder = CLGeocoder()
    var tempDatePickerTimeChange: DepartureDate?
    var timeSinceStartedUpdating: DispatchTime?
    
    var datePickerIndexPath: NSIndexPath?
    var tappedCell = 0
    
    var locationAccuracyUnchanged = 0
    var lastLocationAccuracy: CLLocationAccuracy?
    
    
    override func viewDidLoad()
    {
        if let home = LocationsStorage.shared.homePlacemark
        {
            homeAddressLabel.text = "\(home.name!), " +
                                    "\(home.locality!), " +
                                    "\(home.administrativeArea!)"
        }
        
        if let destination = LocationsStorage.shared.destinationPlacemark
        {
            destinationAddresssLabel.text = "\(destination.name!), " +
                                            "\(destination.locality!), " +
                                            "\(destination.administrativeArea!)"
        }
        
        if let usualDeparture = DateStorage.shared.usualTimeDeparture
        {
            usualDepartureLabel.text = usualDeparture.dateAsString
        }
        
        if let earliestDeparture = DateStorage.shared.earliestTimeDeparture
        {
            earliestPossibleDeparture.text = earliestDeparture.dateAsString
        }
        else
        {
        
        }
        
    }
    
    
    @IBAction func unwindToSettings(_ unwindSegue: UIStoryboardSegue)
    {
        viewDidLoad()
        // Use data from the view controller which initiated the unwind segue
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0
        {
            if indexPath.row == 0
            {
                LocationsStorage.shared.settingsCellTapped = "H" // for Home
            }
            else     // .row == 1
            {
                print("PRESSED THE BUTTON")
                print(locationAccuracyUnchanged)
                killUseCurrentLocationButton()
                startLocationManager()
            }
        }
        else if indexPath.section == 1
        {
            LocationsStorage.shared.settingsCellTapped = "D"    // for Destination
        }
        else if indexPath.section == 2
        {
            tappedCell = indexPath.row
            editingDidBegin(self)
            setupHideKeyboardOnTap()
        }
        
    }

    @IBAction func editingDidBegin(_ sender: Any)
    {
        if tappedCell == 0
        {
            setKeyboardDatePicker()
            usualDepartureLabel.textColor = UIColor.red
            //First button pressed, set the label to target first cell
        }
        else
        {
            setKeyboardDatePicker()
            earliestPossibleDeparture.textColor = UIColor.red
            //Second button pressed, set the label to target second cell
        }
    }
    
    func setKeyboardDatePicker()
    {
        datePickerTopBarSetup()
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePicker.Mode.time
        datePickerView.minuteInterval = 5
        dummyTextField.inputView = datePickerView
        dummyTextField.becomeFirstResponder()
        //MARK:- CHECKING WHAT DATEPICKERVALUECHANGEDDOES
        datePickerView.addTarget(self, action: #selector(SettingsController.datePickerValueChanged), for: UIControl.Event.valueChanged)
    }
    
    //MARK:- DATEPICKER FORMAT

    
    @objc func datePickerValueChanged(sender:UIDatePicker)
    {
        tempDatePickerTimeChange = DepartureDate(date: sender.date)
        dummyTextField.text = tempDatePickerTimeChange!.dateAsString
        
        
        if tappedCell == 0
        {
            usualDepartureLabel.text = tempDatePickerTimeChange!.dateAsString
        }
        else
        {
            earliestPossibleDeparture.text = tempDatePickerTimeChange!.dateAsString
        }
    }
    
    func datePickerTopBarSetup()
    {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height/6, width: self.view.frame.size.width, height: 40.0))
        
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.blackTranslucent
        toolBar.tintColor = UIColor.white
        toolBar.backgroundColor = UIColor.black
        
        let todayBtn = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(SettingsController.tappedCancelBarBtn))
        let okBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(SettingsController.donePressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        
        label.font = UIFont(name: "Helvetica", size: 12)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = "Set a time"
        label.textAlignment = NSTextAlignment.center
        let textBtn = UIBarButtonItem(customView: label)
        toolBar.setItems([todayBtn,flexSpace,textBtn,flexSpace,okBarBtn], animated: true)
        dummyTextField.inputAccessoryView = toolBar
    }
    
    @objc func donePressed(sender: UIBarButtonItem)
    {
        dummyTextField.resignFirstResponder()
       
        //UTD CELL
        if tappedCell == 0
        {
            if dummyTextField.text != ""
            {
                usualDepartureLabel.text = tempDatePickerTimeChange!.dateAsString
                DateStorage.shared.usualTimeDeparture = tempDatePickerTimeChange
                DateStorage.shared.saveUTD(usualDate: tempDatePickerTimeChange!)
                
                if DateStorage.shared.graveyardShiftTest()
                {
                    showAlert(title: "Earliest Time Is Later Than Usual Time", message: "Your traffic times will carry on into the next day; this is regular for times that cross over the 0th hour.")
                }
                
            }
            tableView.deselectRow(at: [2,0], animated: true)
            usualDepartureLabel.textColor = UIColor(named: "titleLabelColor")
        }
            
        //ETD CELL
        else if tappedCell == 1
        {
            if dummyTextField.text != ""
            {
                earliestPossibleDeparture.text = tempDatePickerTimeChange!.dateAsString
                DateStorage.shared.earliestTimeDeparture = tempDatePickerTimeChange
                DateStorage.shared.saveETD(earliestDate: tempDatePickerTimeChange!)
                
                if DateStorage.shared.graveyardShiftTest()
                {
                    showAlert(title: "Earliest Time is Later than Usual Time", message: "Your traffic times will carry on into the next day; this is regular for times that cross over the 0th hour.")
                }
            }
            earliestPossibleDeparture.textColor = UIColor(named: "titleLabelColor")
            tableView.deselectRow(at: [2,1], animated: true)
        }
        dummyTextField.text = ""
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func deselectDepartureTimeCell()
    {
        if tappedCell == 0
        {
            usualDepartureLabel.textColor = UIColor(named: "titleLabelColor")
            
            if DateStorage.shared.usualTimeDeparture != nil
            {
                usualDepartureLabel.text = DateStorage.shared.usualTimeDeparture!.dateAsString
            }
            else
            {
                usualDepartureLabel.text = "00:00"
            }
            tableView.deselectRow(at: [2,0], animated: true)
        }
        
        else if tappedCell == 1
        {
            earliestPossibleDeparture.textColor = UIColor(named: "titleLabelColor")
            
            if DateStorage.shared.earliestTimeDeparture != nil
            {
                earliestPossibleDeparture.text = DateStorage.shared.earliestTimeDeparture!.dateAsString
            }
            else
            {
                earliestPossibleDeparture.text = "00:00"
            }
            tableView.deselectRow(at: [2,1], animated: true)
        }
        
        dummyTextField.text = ""
    }
    
    
    @objc func tappedCancelBarBtn(sender: UIBarButtonItem)
    {
        dummyTextField.resignFirstResponder()
        deselectDepartureTimeCell()
        
    }
    
    func setupHideKeyboardOnTap()
    {
            self.view.addGestureRecognizer(self.endEditingRecognizer())
    }

    
    private func endEditingRecognizer() -> UIGestureRecognizer
    {
        print("Hello")
        print(tappedCell)
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tap.addTarget(self, action: #selector(deselectDepartureTimeCell))
        tap.cancelsTouchesInView = false
        return tap
        }
}




extension SettingsController: CLLocationManagerDelegate {
    
    func checkAccuracyProgress(newLocation: CLLocation) {
        if let lastLocationAccuracy = lastLocationAccuracy
        {
            if newLocation.horizontalAccuracy == lastLocationAccuracy || newLocation.horizontalAccuracy < lastLocationAccuracy
            {
                locationAccuracyUnchanged += 1
            }
            
            if locationAccuracyUnchanged > 8
            {
                stopLocationManager()
                showAlert(title: "Accuracy Issue", message: "It's best to enter your address manually. The address found may be inaccurate.")
                locationAccuracyUnchanged = 0
            }
        }
    }
    
    func reanimateUseCurrentLocationButton()
    {
        useCurrentLocationButtonView.backgroundColor = .systemBlue
        tableView.deselectRow(at: [0, 1], animated: true)
        currentLocationButtonLabel.text = "Use Current Location"
        tableView.cellForRow(at: [0, 1])!.isUserInteractionEnabled = true
    }
    
    func killUseCurrentLocationButton()
    {
        useCurrentLocationButtonView.backgroundColor = .gray
        currentLocationButtonLabel.text = "Fetching Location"
        tableView.cellForRow(at: [0, 1])!.isUserInteractionEnabled = false
    }
    
    func startLocationManager()
    {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            reanimateUseCurrentLocationButton()
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .denied || authStatus == .restricted
        {
            showAlert(title: "Location Services Disabled",
                      message: "Please enable location services for this app in settings"
            )
            return
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }
    
    func stopLocationManager()
    {
        if isUpdatingLocation
        {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        isUpdatingLocation = false
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager)
    {
                print("PAUSED LOCATION UPDATES")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if timeSinceStartedUpdating == nil
        {
            timeSinceStartedUpdating = DispatchTime.now()
        }
        else
        {
            if timeSinceStartedUpdating! + 20 <  DispatchTime.now() //15 SECONDS PASSED
            {
                stopLocationManager()
                showAlert(title: "Accuracy Issues with GPS", message: "Please try again, or enter the address manually.")
                reanimateUseCurrentLocationButton()
                timeSinceStartedUpdating = nil
                return
            }
        }
        
        //MAKING VISUAL LOADING APPEARANCE
        if currentLocationButtonLabel.text!.count > 19
        {
            currentLocationButtonLabel.text = "Fetching Location"
        }
        else
        {
            currentLocationButtonLabel.text!.append(".")
        }
        
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        lastLocationError = nil
        checkAccuracyProgress(newLocation: newLocation)
        
        if (newLocation.horizontalAccuracy < 0) {
            return;
        }
        let interval = newLocation.timestamp.timeIntervalSinceNow

        if abs(interval) < 20
        {
            
            if newLocation.timestamp.timeIntervalSinceNow < -5
            {
                locationAccuracyUnchanged = 0
                showAlert(title: "GPS Couldn't Update The Location", message: "Try again later, or enter a location manually")
                stopLocationManager()
                reanimateUseCurrentLocationButton()
                timeSinceStartedUpdating = nil
                return
            }
        
            if newLocation.horizontalAccuracy < 0
            {
                locationAccuracyUnchanged = 0
                showAlert(title: "GPS Accuracy Issues", message: "Try again later, or enter the address manually")
                stopLocationManager()
                reanimateUseCurrentLocationButton()
                timeSinceStartedUpdating = nil
                return
            }
        
            if currentLocation == nil || currentLocation!.horizontalAccuracy > newLocation.horizontalAccuracy
            {
                lastLocationError = nil
                currentLocation = newLocation
            
                if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy
                {
                    print("Done!")
                    stopLocationManager()
                    timeSinceStartedUpdating = nil
                    setProperCLPlacemarkAndMapItemFor(location: newLocation)
                    locationAccuracyUnchanged = 0
                }
            }
        }
    }
    
    func setProperCLPlacemarkAndMapItemFor(location: CLLocation)
    {
        func makeMKMapItemFrom(placemark: CLPlacemark) -> MKMapItem
        {
            let mkPlacemark = MKPlacemark(coordinate: placemark.location!.coordinate)
            return MKMapItem(placemark: mkPlacemark)
        }
        
        let cLVersionOfLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(cLVersionOfLocation, completionHandler: {(placemarks:[CLPlacemark]?, error:Error?) -> Void in
            
                if let placemarks = placemarks
                {
                    let placemark = placemarks[0]
                
                    self.geoCoder.reverseGeocodeLocation(placemark.location!, completionHandler:
                        {(placemarks, error) in
                            if (error != nil)
                            {
                                print("reverse geodcode fail: \(error!.localizedDescription)")
                                return
                            }
                            let pm = placemarks! as [CLPlacemark]
                            if pm.count > 0 {
                                let pm = placemarks![0]
                                LocationsStorage.shared.homePlacemark = pm
                                LocationsStorage.shared.saveHomePlacemark(placemark: pm)
                                LocationsStorage.shared.homeMKMapItem = makeMKMapItemFrom(placemark: LocationsStorage.shared.homePlacemark!)
                            
                                self.homeAddressLabel.text = "\(pm.name!)" + " \(pm.locality!)" + "," + " \(pm.administrativeArea!)"
                        
                                self.reanimateUseCurrentLocationButton()
                            }
                        })
                }
            } as CLGeocodeCompletionHandler)
    }
}
