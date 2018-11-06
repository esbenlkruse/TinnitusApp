/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 */

import WatchKit
import Foundation
import Alamofire

/**
 The `RequestLocationInterfaceController` is responsible for communicating between
 the "Request" interface and the `LocationModel`. This interface controller exemplifies
 how to call the `CLLocationManager` directly from a WatchKit Extension using
 the `requestLocation(_:)` method.
 
 In order to guarantee that the information displayed in the interface is fresh,
 this class uses a 2 second timeout after every location update to reset the
 interface. This is done in order to make the example more clear and to avoid stale
 data polluting the interface.
 */
class RequestLocationInterfaceController: WKInterfaceController, CLLocationManagerDelegate {
    
    // MARK: Properties
    
    /**
     When this timer times out, the labels in the interface reset to a default state that does not resemble
     a requestLocation result.
     */
    // var interfaceResetTimer = Timer()
    
    /// Location manager to request authorization and location updates.
    let manager = CLLocationManager()
    
    /// Flag indicating whether the manager is requesting the user's location.
    var isRequestingLocation = false
    
    /// Button to request location. Also allows cancelling the location request.
    @IBOutlet var requestLocationButton: WKInterfaceButton!
    
    /// Timer to count down 5 seconds as a visual cue that the interface will reset.
    //@IBOutlet var displayTimer: WKInterfaceTimer!
    
    /// Label to display the most recent location's latitude.
    //@IBOutlet var latitudeLabel: WKInterfaceLabel!
    
    /// Label to display the most recent location's longitude.
    //@IBOutlet var longitudeLabel: WKInterfaceLabel!
    
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
        //self.setTitle(interfaceTitle)
        
        // Remember to set the location manager's delegate.
        manager.delegate = self
        
        // resetInterface()
    }
    
    // MARK: Button Actions
    
    /**
     When the user taps the Request Location button in the interface, this method
     informs the `LocationModel`'s shared instance to request a location.
     
     If the user is already requesting location, this method will instead cancel
     the request.
     */
    @IBAction func requestLocation() {
        guard !isRequestingLocation else {
            manager.stopUpdatingLocation()
            isRequestingLocation = false
            
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined:
            isRequestingLocation = true
            requestLocationButton.setTitle(savingTitle)
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse:
            isRequestingLocation = true
            requestLocationButton.setTitle(savingTitle)
            manager.requestLocation()
            //saveToFirebase()
            
            
        case .denied:
            errorLabel.setText(deniedText)
            
        default:
            errorLabel.setText(unexpectedText)
        }
    }
    
    func saveToFirebase(lat: String, lon: String) {
        let firebaseUrl = "https://tinnitus-dfcd4.firebaseio.com/observations.json"
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let dateString = formatter.string(from: now)
        let deviceName = WKInterfaceDevice.current().name
        let parameters: Parameters = [
            "timestamp": "\(dateString)", "latitude": "\(lat)", "longitude": "\(lon)", "deviceName": deviceName
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
    // MARK: CLLocationManagerDelegate Methods
    
    /**
     When the location manager receives new locations, display the latitude and
     longitude of the latest location and restart the timers.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !locations.isEmpty else { return }
        
        DispatchQueue.main.async {
            let lastLocationCoordinate = locations.last!.coordinate
            
            //self.latitudeLabel.setText(String(lastLocationCoordinate.latitude))
                print(String(lastLocationCoordinate.latitude))
            
            //self.longitudeLabel.setText(String(lastLocationCoordinate.latitude))
            
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
    
    // MARK: Resetting
    
    /**
     Resets the text labels in the interface to empty labels.
     
     This method is useful for cleaning the interface to ensure that data displayed
     to the user is not stale.
     *//*
    @objc func resetInterface() {
        DispatchQueue.main.async {
            //self.stopDisplayTimer()
            self.latitudeLabel.setText(self.latitudeResetText)
            
            self.longitudeLabel.setText(self.longitudeResetText)
            
            self.errorLabel.setText(self.errorResetText)
        }
    }*/

}
