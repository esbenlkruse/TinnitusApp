//
//  TinnitusInterfaceController.swift
//  Tinnitus WatchKit App Extension
//
//  Created by Esben Kruse on 31/10/2018.
//  Copyright © 2018 Google. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire


class TinnitusInterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    
    
    // MARK: Properties
    
    /// Location manager to request authorization and location updates.
    let manager = CLLocationManager()
    
    /// Flag indicating whether the manager is requesting the user's location.
    var isRequestingLocation = false
    
    var tinnitusLevel = 2
    @IBOutlet var saveObservationButton: WKInterfaceButton!
    
    /// Label to display an error if the location manager finishes with an error.
    @IBOutlet var errorLabel: WKInterfaceLabel!
    
    
    // MARK: Localized String Convenience
    
    var interfaceTitle: String {
        return NSLocalizedString("Request", comment: "Indicates that this interface exemplifies requesting location from the watch")
    }
    
    var requestLocationTitle: String {
        return NSLocalizedString("Request Location", comment: "Button title to indicate that pressing the button will cause the location manager to request location")
    }
    
    var cancelTitle: String {
        return NSLocalizedString("Cancel", comment: "Cancel the current action")
    }
    
    var savingTitle: String {
        return NSLocalizedString("Saving...", comment: "Saving the current action")
    }
    
    var deniedText: String {
        return NSLocalizedString("Location authorization denied.", comment: "Text to indicate authorization status is .Denied")
    }
    
    var unexpectedText: String {
        return NSLocalizedString("Unexpected authorization status.", comment: "Text to indicate authorization status is an unexpected value")
    }
    
    var latitudeResetText: String {
        return NSLocalizedString("<latitude reset>", comment: "String indicating that no latitude is shown to the user due to a timer reset")
    }
    
    var longitudeResetText: String {
        return NSLocalizedString("<longitude reset>", comment: "String indicating that no longitude is shown to the user due to a timer reset")
    }
    
    var errorResetText: String {
        return NSLocalizedString("<no error>", comment: "String indicating that no error is shown to the user")
    }
    
    // MARK: Interface Controller
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print(WKInterfaceDevice.current().name)
        
        // Remember to set the location manager's delegate.
        manager.delegate = self
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    // MARK: Button Actions
    
    @IBAction func saveObservation() {
        guard !isRequestingLocation else {
            manager.stopUpdatingLocation()
            isRequestingLocation = false
            
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined:
            isRequestingLocation = true
            saveObservationButton.setTitle(savingTitle)
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse:
            isRequestingLocation = true
            saveObservationButton.setTitle(savingTitle)
            manager.requestLocation()
            
            
        case .denied:
            errorLabel.setText(deniedText)
            
        default:
            errorLabel.setText(unexpectedText)
        }
    }
    
    func saveToFirebase(lat: String, lon: String) {
        var firebaseUrl = "https://tinnitus-dfcd4.firebaseio.com/observations.json"
        
        if (IsDebug) {
            firebaseUrl = "https://tinnitus-dfcd4.firebaseio.com/test-observations.json"
        }
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let dateString = formatter.string(from: now)
        let deviceName = WKInterfaceDevice.current().name
        let parameters: Parameters = [
            "timestamp": "\(dateString)",
            "latitude": lat,
            "longitude": lon,
            "deviceName": deviceName,
            "level": "\(tinnitusLevel)"
        ]
        
        // Post data to firebase database
        let request = Alamofire.request(firebaseUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        
        
        request.responseData { response in
            switch response.result {
            case .success:
                self.presentController(withName: "ObservationSavedController", context: [])
            case .failure:
                self.presentController(withName: "ObservationNotSavedController", context: [])
            }
        }
    }
    
    @IBAction func tinnitusLevelChanged(_ value: Float) {
        tinnitusLevel = Int(round(value))
    }
    
    
    // MARK: CLLocationManagerDelegate Methods
    
    /**
     When the location manager receives new locations, display the latitude and
     longitude of the latest location and restart the timers.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        
        DispatchQueue.main.async {
            let lastLocationCoordinate = locations.last!.coordinate
            
            print(String(lastLocationCoordinate.latitude))
            
            self.saveToFirebase(lat: String(lastLocationCoordinate.latitude), lon: String(lastLocationCoordinate.longitude))
        
        }
    }
    
    /**
     When the location manager receives an error, display the error and restart the timers.
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorLabel.setText(String(error.localizedDescription))
            
            self.isRequestingLocation = false

        }
    }
    
    /**
     Only request location if the authorization status changed to an authorization
     level that permits requesting location.
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            guard self.isRequestingLocation else { return }
            
            switch status {
            case .authorizedWhenInUse:
                manager.requestLocation()
                
            case .denied:
                self.errorLabel.setText(self.deniedText)
                self.isRequestingLocation = false
                
            default:
                self.isRequestingLocation = false
            }
        }
    }
}
