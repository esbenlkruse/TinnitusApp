//
//  MapViewController.swift
//  Tinnitus
//
//  Created by Esben Kruse on 19/09/2018.
//  Copyright © 2018 Esben Kruse. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMaps
import WatchConnectivity
import CoreLocation

class MapViewController: UIViewController, WCSessionDelegate, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    /**
     This determines whether the phone is actively connected to the watch.
     If the activationState is active, do nothing. If the activation state is inactive,
     temporarily disable location streaming by modifying the UI.
     */
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if activationState == .notActivated || activationState == .inactive {
                
            }
        }
    }
    
    
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    @available(iOS 9.0, *)
    func sessionWatchStateDidChange(_ session: WCSession) {
        
    }
    
    
    // MARK: Properties
    
    /// Default WatchConnectivity session for communicating with the watch.
    let session = WCSession.default
    
    /// Location manager used to start and stop updating location.
    let manager = CLLocationManager()
    
    /// Indicates whether the location manager is updating location.
    var isUpdatingLocation = false
    
    /// Cumulative count of received locations.
    //var receivedLocationCount: AnyObject = 0
    var receivedLocationCount = 0
    
    /// The number of locations that will be sent in a batch to the watch.
    var locationBatchCount = 0
    
    /**
     Timer to send the cumulative count to the watch.
     To avoid polluting IDS traffic, its better to send batch updates to the watch
     instead of sending the updates as they arrive.
     */
    var sessionMessageTimer = Timer()
    
    // MARK: Localized String Convenience
    
    private var ref: DatabaseReference!
    private var observations: NSDictionary!
    private var mapView: GMSMapView!
    private var heatmapLayer: GMUHeatmapTileLayer!
    
    private var gradientColors = [UIColor.green, UIColor.red]
    private var gradientStartPoints = [0.2, 1.0] as? [NSNumber]
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        commonInit()
    }
    
    /**
     Responds to the button press by either starting or stopping location updates
     depending on the current state.
     */
    /*@IBAction func startStopUpdatingLocation(sender: AnyObject) {
     if isUpdatingLocation.isEqual(true) {
     stopUpdatingLocation(commandedFromPhone: true)
     }
     else {
     startUpdatingLocationAllowingBackground(commandedFromPhone: true)
     }
     }*/
    @objc func startStopUpdatingLocation() {
        if isUpdatingLocation {
            stopUpdatingLocation(commandedFromPhone: true)
        }
        else {
            startUpdatingLocationAllowingBackground(commandedFromPhone: true)
        }
    }
    
    /**
     Sets the delegates and activate the `WCSession`.
     
     The `WCSession` needs to be activated in the init methods so that when the
     app is launched into the background when it wasn't previously running, the
     session can still be activated allowing communication between the watch and
     the phone. Activating the session in the `viewDidLoad()` method wont suffice
     since the `viewDidLoad()` method will not be called if the app is launched
     into the background.
     */
    func commonInit() {
        
        // Initialize the `WCSession` and the `CLLocationManager`.
        session().delegate = self
        session().activate()
        
        manager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        print(UIDevice.current.name)
    
        self.ref = Database.database().reference()
        heatmapLayer = GMUHeatmapTileLayer()
        heatmapLayer.radius = 80
        heatmapLayer.opacity = 0.8
        heatmapLayer.gradient = GMUGradient(colors: gradientColors,
                                            startPoints: gradientStartPoints!,
                                            colorMapSize: 256)
        readFromDatabase()
    }

    override func loadView() {
        let camera = GMSCameraPosition.camera(withLatitude: 55.695689833791086,
                                              longitude: 12.538195107338126,
                                              zoom: 13)
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = self
        self.view = mapView
//        self.mapView = mapView
    }
    
    func readFromDatabase() {
        self.ref.child("observations").observeSingleEvent(of: .value, with: { (snapshot) in
            var list = [GMUWeightedLatLng]()
            
            // Get user value
            self.observations = snapshot.value as? NSDictionary
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                let lat:String! = element.value(forKey: "latitude") as? String
                let lng:String! = element.value(forKey: "longitude") as? String
                
                let position = CLLocationCoordinate2D(latitude: Double(lat) ?? 0.0, longitude: Double(lng)  ?? 0.0)
                let coords = GMUWeightedLatLng(coordinate: position, intensity: 1.0)
                list.append(coords)
//                let marker = GMSMarker(position: position)
//                marker.map = self.mapView
            }
            
            // Add the latlngs to the heatmap layer.
            self.heatmapLayer.weightedData = list
            self.heatmapLayer.map = self.mapView
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    /**
     Starts updating location and allows the app to receive background location
     updates.
     
     This method also sets the view into a state that lets the user know that
     the manager has started updating location, as well as starts the batch timer
     for sending location counts to the watch.
     
     Use `commandedFromPhone` to determine whether or not to call `requestWhenInUseAuthorization()`.
     If this method was called due to a command from the watch, the watch should
     be responsible for requesting authorization, and therefore this method
     should not request authorization. This ensures that the authorization prompt
     will come from the device that the user is currently interacting with.
     */
    func startUpdatingLocationAllowingBackground(commandedFromPhone: Bool) {
        isUpdatingLocation = true
        // When commanding from the phone, request authorization and inform the watch app of the state change.
        if commandedFromPhone {
            manager.requestWhenInUseAuthorization()
            
            do {
                try session().updateApplicationContext([
                    MessageKey.stateUpdate.rawValue: isUpdatingLocation
                    ])
            }
            catch let error as NSError {
                print("Error when updating application context \(error.localizedDescription).")
            }
        }
        
        manager.allowsBackgroundLocationUpdates = true
        
        manager.startUpdatingLocation()
        
        sessionMessageTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(MapViewController.sendLocationCount), userInfo: nil, repeats: true)
    }
    
    /**
     Informs the manager to stop updating location, invalidates the timer, and
     updates the view.
     
     If the command comes from the phone, this method sends a state update to
     the watch to inform the watch that location updates have stopped.
     */
    func stopUpdatingLocation(commandedFromPhone: Bool) {
        isUpdatingLocation = false
        /*
         When commanding from the phone, request authorization and inform the
         watch app of the state change.
         */
        if commandedFromPhone {
            do {
                try session().updateApplicationContext([
                    MessageKey.stateUpdate.rawValue: isUpdatingLocation
                    ])
            }
            catch let error as NSError {
                print("Error when updating application context \(error.localizedDescription)")
            }
        }
        
        manager.stopUpdatingLocation()
        
        manager.allowsBackgroundLocationUpdates = false
    }
    
    
    
    /**
     On the receipt of a message, check for expected commands.
     
     On a `startUpdatingLocation` command, inform the manager to start updating
     location, and start a repeating 5 second timer that sends the cumulative
     location count to the watch.
     
     On a `stopUpdatingLocation` command, inform the manager to stop updating
     location, and stop the repeating timer.
     */
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        guard let messageCommandString = message[MessageKey.command.rawValue] as? String else { return }
        
        guard let messageCommand = MessageCommand(rawValue: messageCommandString) else {
            print("Unknown command \(messageCommandString).")
            return
        }
        
        DispatchQueue.main.async {
            switch messageCommand {
            case .startUpdatingLocation:
                self.startUpdatingLocationAllowingBackground(commandedFromPhone: false)
                
                replyHandler([
                    MessageKey.acknowledge.rawValue: messageCommand.rawValue as AnyObject
                    ])
                
            case .stopUpdatingLocation:
                self.stopUpdatingLocation(commandedFromPhone: false)
                
                replyHandler([
                    MessageKey.acknowledge.rawValue: messageCommand.rawValue as AnyObject
                    ])
                
            case .sendLocationStatus:
                replyHandler([
                    MessageKey.acknowledge.rawValue: self.isUpdatingLocation
                    ])
            }
        }
    }
    
    /**
     Send the current cumulative location to the watch and reset the batch
     count to zero.
     */
    @objc func sendLocationCount() {
        do {
            try self.session().updateApplicationContext([
                MessageKey.locationCount.rawValue: String(self.receivedLocationCount) as AnyObject
                ])
            
            locationBatchCount = 0
        }
        catch let error as NSError {
            print("Error when updating application context \(error).")
        }
    }
    
    /**
     Increases that location count by the number of locations received by the
     manager. Updates the batch count with the added locations.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        receivedLocationCount = receivedLocationCount + locations.count
        locationBatchCount = locationBatchCount + locations.count
    }
    
    /// Log any errors to the console.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error occured: \(error.localizedDescription).")
    }
}

