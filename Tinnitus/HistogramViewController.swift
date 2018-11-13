//
//  HistogramViewController.swift
//  Tinnitus
//
//  Created by Esben Kruse on 25/10/2018.
//  Copyright © 2018 Esben Kruse. All rights reserved.
//

import UIKit
import Firebase

class HistogramViewController: UIViewController {
    
    @IBOutlet weak var TimeController: UISegmentedControl!
    @IBOutlet weak var barChart: BarChart!
    var observations: NSDictionary!
    var ref: DatabaseReference!
//    let userName = UIDevice.current.name.split(separator: " ").first.map(String.init)
    let userName = "Charlottes"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.ref = Database.database().reference()
        readFromDatabase()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func populateDate(mode : String) -> [BarEntry] {
        let colors = [#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)]
        var result: [BarEntry] = []
        
        let calendar = Calendar.current
        var date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "dk_DA")
        
        var numDays = 0
        let year = calendar.component(.year, from: date)
        
        if (mode == "Week") {
            // Week with test data
            let dateComponentsTestData = DateComponents(year: year, month: 10, day: 22, hour: 5)
            date = calendar.date(from: dateComponentsTestData)!
            numDays = calendar.range(of: .day, in: .weekOfMonth, for: date)!.count
        }
        
        let days = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        for i in days..<(days + numDays) {
            var value = 0
            
            let dateComponents = DateComponents(year: year, month: month, day: i)
            let iterateDate = calendar.date(from: dateComponents)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = obsDevice.split(separator: " ").first.map(String.init)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .day)) {
                        value += 1
                    }
                }
            }
            
            let height: Float = Float(value) / 50.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            result.append(BarEntry(color: colors[i % colors.count], height: height, textValue: "\(value)", title: formatter.string(from: iterateDate)))
        }
        return result
    }
    
//    func generateDataEntries() -> [BarEntry] {
//        let colors = [#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)]
//        var result: [BarEntry] = []
//        for i in 0..<20 {
//            let value = (arc4random() % 90) + 10
//            let height: Float = Float(value) / 100.0
//
//            let formatter = DateFormatter()
//            formatter.dateFormat = "d MMM"
//            var date = Date()
//            date.addTimeInterval(TimeInterval(24*60*60*i))
//            result.append(BarEntry(color: colors[i % colors.count], height: height, textValue: "\(value)", title: formatter.string(from: date)))
//        }
//        return result
//    }
    
    func readFromDatabase() {
        self.ref.child("observations").observeSingleEvent(of: .value, with: { (snapshot) in
            self.observations = snapshot.value as? NSDictionary
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func TimeChanged(_ sender: Any) {
        
        switch TimeController.selectedSegmentIndex {
        case 0:
            // Day
            
            break
        case 1:
            // Week
            let data = populateDate(mode: "Week")
            barChart.dataEntries = data
            
            break
        case 2:
            // Month
            
            break
        default:
            break
        }
    }
}
