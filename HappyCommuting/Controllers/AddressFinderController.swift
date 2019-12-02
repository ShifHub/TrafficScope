//
//  AddressFinderController.swift
//  HappyCommuting
//
//  Created by Sarrick Shiflett on 6/13/19.
//  Copyright © 2019 Sarrick Shiflett. All rights reserved.
//

import UIKit
import MapKit

class AddressFinderController: UIViewController
{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var responseString = "None"
    var destinationLocation: CLLocation?
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if LocationsStorage.shared.settingsCellTapped == "H"
        {
            self.title = "Current Address"
        }
        else
        {
            self.title = "Destination Address"
        }
        
        //searchBar
        searchBar.delegate = self
        //tableView
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        //searchCompleter
        searchCompleter.delegate = self
    }
    
}




//SEARCHBAR
extension AddressFinderController: UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
        searchResults = []
        searchCompleter.queryFragment = searchBar.text!
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}

//TABLEVIEW
extension AddressFinderController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let searchResult = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectedAddress = searchResults[indexPath.row]
        self.getPlacemarkFrom(selectedAddress)
        
        TempWeatherStorage.shared.newWeatherNeeded = true
    }
    
}


//SearchCompleter

extension AddressFinderController: MKLocalSearchCompleterDelegate
{
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter)
    {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error)
    {
        // TODO: LOOK UP POSSIBLE ERRORS AND HANDLING
    }
    
    func getPlacemarkFrom(_ mkSearchCompletion: MKLocalSearchCompletion)
    {
        let searchRequest = MKLocalSearch.Request(completion: mkSearchCompletion)
        let search = MKLocalSearch(request: searchRequest)
        //FIXME: - FIX THE INFORMATION HERE NEED TO DESCRIMINATE BETWEEN HOME AND DESTINATION
        search.start { (response, error) in
            if let placemarkResponse = response?.mapItems.first?.placemark {
                if LocationsStorage.shared.settingsCellTapped == "H" {
                    LocationsStorage.shared.homePlacemark = placemarkResponse
                    LocationsStorage.shared.saveHomePlacemark(placemark: LocationsStorage.shared.homePlacemark!)
                    LocationsStorage.shared.homeMKMapItem = self.makeMKMapItemFrom(placemark: LocationsStorage.shared.homePlacemark!)
                
                } else if LocationsStorage.shared.settingsCellTapped == "D" {
                    LocationsStorage.shared.saveDestinationPlacemark(placemark: placemarkResponse)
                    LocationsStorage.shared.destinationPlacemark = placemarkResponse
                    LocationsStorage.shared.destinationMKMapItem = self.makeMKMapItemFrom(placemark: LocationsStorage.shared.destinationPlacemark!)
                }
            } else {
                print(error as Any)
            }
                self.performSegue(withIdentifier: "AddressResponse", sender: self)
        }
    }
    
    func makeMKMapItemFrom(placemark: CLPlacemark) -> MKMapItem
    {
        //Helper Function To: setProperCLPlacemarkAndMapItemFor()
        let mkPlacemark = MKPlacemark(coordinate: placemark.location!.coordinate)
        return MKMapItem(placemark: mkPlacemark)
    }
}


    
    

