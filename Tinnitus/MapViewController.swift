import Foundation
import UIKit
import Firebase
import GoogleMaps
import WatchConnectivity
import CoreLocation

class MapViewController: UIViewController, GMSMapViewDelegate {
    // MARK: Properties
    @IBOutlet weak var TimeController: UISegmentedControl!
    
    /// Default WatchConnectivity session for communicating with the watch.
    let session = WCSession.default
    
    /// Location manager used to start and stop updating location.
    let manager = CLLocationManager()
    
    /// Indicates whether the location manager is updating location.
    var isUpdatingLocation = false
    
    var currentLocation: CLLocation?
    var zoomLevel: Float = 9.0
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: 55.676098, longitude: 12.568337)
    
    var ref: DatabaseReference!
    var observations: NSDictionary!
    var mapView: GMSMapView!
    var heatmapLayer: GMUHeatmapTileLayer!
    
    var gradientColors = [UIColor.green, UIColor.red]
    var gradientStartPoints = [0.2, 1.0]
    
    var userName = getUserName(deviceName: UIDevice.current.name)
    
    let calendar = Calendar.current
    var now = Date()
    let dateFormatter = DateFormatter()
    
    // MARK: Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        commonInit()
    }
    
    @objc func startStopUpdatingLocation() {
        if isUpdatingLocation {
            stopUpdatingLocation(commandedFromPhone: true)
        }
        else {
            startUpdatingLocationAllowingBackground(commandedFromPhone: true)
        }
    }
    

    func commonInit() {
        // Initialize the `WCSession` and the `CLLocationManager`.
        session().delegate = self
        session().activate()
        
        manager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if (IsDebug) {
            self.userName = "Charlottes".lowercased()
        }
        
        loadHeatMap()
        
        self.ref = Database.database().reference()
        readFromDatabase()
    }
    
    func loadHeatMap() {
        // Initialize the location manager.
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.distanceFilter = 50
        manager.startUpdatingLocation()
        manager.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        mapView.delegate = self
        view.bringSubview(toFront: TimeController)
        
        heatmapLayer = GMUHeatmapTileLayer()
        heatmapLayer.radius = 80
        heatmapLayer.opacity = 0.8
        heatmapLayer.gradient = GMUGradient(colors: gradientColors,
                                            startPoints: gradientStartPoints as [NSNumber],
                                            colorMapSize: 256)
    }
    
    func readFromDatabase() {
        self.ref.child("observations").observeSingleEvent(of: .value, with: { (snapshot) in
            var coords = [GMUWeightedLatLng]()
            
            self.observations = snapshot.value as? NSDictionary

            // Month
            coords = self.populateDataMonth()

            // Add the latlngs to the heatmap layer.
            self.heatmapLayer.weightedData = coords
            self.heatmapLayer.map = self.mapView
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    /*
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
    }
    
    /*
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
    
    /*
     Send the current cumulative location to the watch and reset the batch
     count to zero.
     */
    
    @IBAction func TimeChanged(_ sender: UISegmentedControl) {
        var coords = [GMUWeightedLatLng]()
        
        switch TimeController.selectedSegmentIndex {
        case 0:
            // Day
            coords = populateDataDay()
            
            break
        case 1:
            // Week
            coords = populateDataWeek()
            
            break
        case 2:
            // Month
            coords = populateDataMonth()
            
            break
        default:
            // Month
            coords = populateDataMonth()
            
            break
        }
        
        // Clear heatmap layer.
        self.heatmapLayer.map = nil
        
        // Add the latlngs to the heatmap layer.
        self.heatmapLayer.weightedData = coords
        self.heatmapLayer.map = self.mapView
    }
    
    func populateDataDay() -> [GMUWeightedLatLng] {
        var coords = [GMUWeightedLatLng]()
        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "dk_DA")
        
        let numHours = 24
        
        if (IsDebug) {
            // Day with test data
            let year = calendar.component(.year, from: now)
            let dateComponentsTestData = DateComponents(year: year, month: 10, day: 27, hour: 22)
            now = calendar.date(from: dateComponentsTestData)!
        }
        
        for i in 1..<(numHours + 1) {
            let iterateDate = calendar.date(byAdding: .hour, value: i - numHours, to: now)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .hour)) {
                        coords.append(saveCoords(obj: element))
                    }
                }
            }
        }
        return coords
    }
    
    func populateDataWeek() -> [GMUWeightedLatLng] {
        var coords = [GMUWeightedLatLng]()
        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "dk_DA")
        
        let numDays = 7
        
        if (IsDebug) {
            // Week with test data
            let year = calendar.component(.year, from: now)
            let dateComponentsTestData = DateComponents(year: year, month: 11, day: 2, hour: 5)
            now = calendar.date(from: dateComponentsTestData)!
        }
        
        for i in 1..<(numDays + 1) {
            let iterateDate = calendar.date(byAdding: .day, value: i - numDays, to: now)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .day)) {
                        coords.append(saveCoords(obj: element))
                    }
                }
            }
        }
        return coords
    }
    
    func populateDataMonth() -> [GMUWeightedLatLng] {
        var coords = [GMUWeightedLatLng]()
        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "dk_DA")
        
        let numWeeks = 5
        
        for i in 1..<(numWeeks + 1) {
            let iterateDate = calendar.date(byAdding: .weekOfYear, value: i - numWeeks, to: now)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .weekOfYear)) {
                        coords.append(saveCoords(obj: element))
                    }
                }
            }
        }
        return coords
    }
    
    func saveCoords(obj: NSObject) -> GMUWeightedLatLng {
        let lat:String! = obj.value(forKey: "latitude") as? String
        let lng:String! = obj.value(forKey: "longitude") as? String
        
        let savedLocation = CLLocation(
            latitude: Double(lat) ?? self.defaultLocation.coordinate.latitude,
            longitude: Double(lng) ?? self.defaultLocation.coordinate.longitude)
        
        let position = CLLocationCoordinate2D(
            latitude: savedLocation.coordinate.latitude,
            longitude: savedLocation.coordinate.longitude)
        
        let coord = GMUWeightedLatLng(coordinate: position, intensity: 1.0)
        
        return coord;
    }
}

// Delegates to handle events for the location manager.
extension MapViewController: CLLocationManagerDelegate {
    /*
     Increases that location count by the number of locations received by the
     manager. Updates the batch count with the added locations.
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location: CLLocation = locations.last!
        var camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
    
        if (IsDebug) {
            camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                                  longitude: defaultLocation.coordinate.longitude,
                                                  zoom: zoomLevel)
        }
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Log any errors to the console.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        print("Error occured: \(error.localizedDescription).")
    }
}

extension MapViewController: WCSessionDelegate {
    /*
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
    
    /*
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
}
