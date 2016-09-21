//
//  MasterViewController.swift
//  RestaurantFinder
//
//  Created by Pasan Premaratne on 5/4/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//


//MKMapTime

import UIKit
import MapKit

class RestaurantListController: UITableViewController, MKMapViewDelegate, UISearchResultsUpdating {
    
    var coordinate: Coordinate?
    let foursquareClient = FoursquareClient(clientID: "5O53IDZJAWB12DFHH1WFEYL2I1I3L0BTYQPHZUGJZYFL5IO4", clientSecret: "DXVEG1PDN0NMSOOZRRLJTWXTAON4RUL3GJSXAZVVEKHP40A3")
    let manager = LocationManager()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stackView: UIStackView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var venues: [Venue] = [] {
        didSet {
            tableView.reloadData()
            addMapAnnotation()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Search bar configuration
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation  = true
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        stackView.addSubview(searchController.searchBar)
        
        manager.getPermission()
        manager.onLocationFix = { [weak self] coordinate in
            
            self?.coordinate = coordinate
            
            self?.foursquareClient.fetchRestaurantsFor(coordinate, category: .Food(nil)) { result in
                switch result {
                case .Success(let venues):
                    self?.venues = venues
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                
                let venue = venues[indexPath.row]
                controller.venue = venue
                
                
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RestaurantCell", forIndexPath: indexPath) as! RestaurantCell
        
        let venue = venues[indexPath.row]
        
        cell.restaurantTitleLabel.text = venue.name
        cell.restaurantCheckinLabel.text = venue.checkins.description
        cell.restaurantCategoryLabel.text = venue.categoryName
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    @IBAction func refreshRestaurantData(sender: AnyObject) {
        
        if let coordinate = coordinate {
            foursquareClient.fetchRestaurantsFor(coordinate, category: .Food(nil)) { result in
                switch result {
                case .Success(let venues):
                    self.venues = venues
                case .Failure(let error):
                    print(error)
                }
            }
        }
        
        refreshControl?.endRefreshing()
    }
    
    //MARK: MKMapViewDelegate
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        var region = MKCoordinateRegion()
        region.center = mapView.userLocation.coordinate
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        mapView.setRegion(region, animated: true)
    }
    
    func addMapAnnotation() {
        
        removeMapAnnotations()        
        if venues.count > 0 {
            let annotations: [MKPointAnnotation] = venues.map { venue in
                let point = MKPointAnnotation()
                
                if let coordinate = venue.location?.coordinate {
                    point.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    point.title = venue.name
                }
                return point
            }
            mapView.addAnnotations(annotations)
        }
    }
    
    func removeMapAnnotations() {
        if mapView.annotations.count != 0 {
            for annotation in mapView.annotations {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    //MARK: UISearchResultUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let coordinate = coordinate {
            foursquareClient.fetchRestaurantsFor(coordinate, category: .Food(nil), query: searchController.searchBar.text) { result in
                switch result {
                case .Success(let venues):
                    self.venues = venues
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }
}






















