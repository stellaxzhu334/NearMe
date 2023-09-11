//
//  ViewController.swift
//  NearMe
//
//  Created by Stella Zhu on 2023/9/10.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    var locationManager: CLLocationManager?
    private var places: [PlaceAnnotation] = [] // places array
    
    //  lazy: no need to create MapKit many times
    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.delegate = self // self is the viewController
        map.showsUserLocation = true // have not connected your location
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    } ()
    
    lazy var searchTextField: UITextField = {
        let searchTextField = UITextField()
        searchTextField.layer.cornerRadius = 10
        searchTextField.delegate = self
        searchTextField.clipsToBounds = true
        searchTextField.backgroundColor = UIColor.white
        searchTextField.placeholder = "Search"
        searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0)) // front text padding
        searchTextField.leftViewMode = .always
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        return searchTextField
    } ()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  initalize location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self    // self will be ViewController
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.requestLocation()
        
        setupUI()
    }
    
    private func setupUI() {
        
        view.addSubview(searchTextField)
        view.addSubview(mapView)
        
        view.bringSubviewToFront(searchTextField)
        
        //  add constraints to the searchTextField
        searchTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        searchTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        searchTextField.widthAnchor.constraint(equalToConstant: view.bounds.size.width/1.2).isActive = true
        searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        searchTextField.returnKeyType = .go
        
        //  add constraints to the mapView
        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mapView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager,
              let location = locationManager.location else { return }
        
        
        switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways: // if enabled, zoom in location automatically
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 750, longitudinalMeters: 750)
                mapView.setRegion(region, animated: true)
            case .denied:
                print("Location Services have been denied.")
            case .notDetermined, .restricted:
                print("Location cannot be determined or restricted.")
            @unknown default:
                print("Unknown error. Unable to get location.")
        }
    }
    
    private func presentPlacesSheet(places: [PlaceAnnotation]) {
        
        guard let locationManager = locationManager, // use locationManager to access user's location
              let userLocation = locationManager.location
        else { return }
        
        let placesTVC = PlacesTableViewController(userLocation: userLocation, places: places)
        placesTVC.modalPresentationStyle = .pageSheet
        if let sheet = placesTVC.sheetPresentationController {
            sheet.prefersGrabberVisible = true // coming from the bottom
            sheet.detents = [.medium(), .large()] // can be half screen or full screen
            present(placesTVC, animated: true)
        }
    }

    private func findNearbyPlaces(by query: String) {
        
        // clear any annotations
        mapView.removeAnnotations(mapView.annotations)
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in // weak self does not capture reference
            guard let response = response, error == nil else { return } // response are results
            // pin annotation on results
            self?.places = response.mapItems.map(PlaceAnnotation.init)
            self?.places.forEach { place in
                self?.mapView.addAnnotation(place)
            }
            // show results in table by PlacesTableViewController
            if let places = self?.places { // self?. should not be wrapped
                self?.presentPlacesSheet(places: places)
            }
        }
        
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let text = textField.text ?? ""
        if !text.isEmpty {
            textField.resignFirstResponder()
            // function here for searching nearby places
            findNearbyPlaces(by: text)
        }
        return true
    }
}

extension ViewController: MKMapViewDelegate {
    
    private func clearAllSelections() {
        self.places = self.places.map { place in
            place.isSelected = false
            return place
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        
        // clear all selections
        clearAllSelections()
        
        guard let selectedAnnotation = annotation as? PlaceAnnotation else { return } // cast as PlaceAnnotation
        let placeAnnotation = self.places.first(where: {$0.id == selectedAnnotation.id}) // get the ref from self.places
        placeAnnotation?.isSelected = true // use it in the placesTableViewController
        
        presentPlacesSheet(places: self.places)
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

