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

class MapViewController: UIViewController, GMSMapViewDelegate {
    
    private var ref: DatabaseReference!
    private var observations: NSDictionary!
    private var mapView: GMSMapView!
    private var heatmapLayer: GMUHeatmapTileLayer!
    
    private var gradientColors = [UIColor.green, UIColor.red]
    private var gradientStartPoints = [0.2, 1.0] as? [NSNumber]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
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
}

