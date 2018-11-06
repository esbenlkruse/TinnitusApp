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


class TinnitusInterfaceController: WKInterfaceController {
    
    // MARK: Interface Controller
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    /*
    func saveToFirebase() {
        let firebaseUrl = "https://tinnitus-dfcd4.firebaseio.com/test-observations.json"
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let dateString = formatter.string(from: now)
        
        let parameters: Parameters = [
            "timestamp": "\(dateString)"
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
    
    @IBAction func saveObservation() {
        saveToFirebase()
    } */
}
