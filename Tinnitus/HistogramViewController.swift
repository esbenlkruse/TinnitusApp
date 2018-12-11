import UIKit
import Firebase

class HistogramViewController: UIViewController {
    
    @IBOutlet weak var TimeController: UISegmentedControl!
    @IBOutlet weak var barChart: BarChart!
    var observations: NSDictionary!
    var ref: DatabaseReference!
    var userName = getUserName(deviceName: UIDevice.current.name)
    
    let calendar = Calendar.current
    var now = Date()
    let dateFormatter = DateFormatter()
    let colors = [#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 1, green: 0, blue: 0.06691975147, alpha: 1), #colorLiteral(red: 0.3397175074, green: 0.4522598982, blue: 0.9626483321, alpha: 1), #colorLiteral(red: 0, green: 0.9475013614, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0.9461720586, blue: 0.914932251, alpha: 1), #colorLiteral(red: 0, green: 0.947642982, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0, blue: 0.6851263046, alpha: 1), #colorLiteral(red: 0, green: 0.9450717568, blue: 0.1970072985, alpha: 1), #colorLiteral(red: 0.7593582273, green: 0.3454462886, blue: 0.9615538716, alpha: 1), #colorLiteral(red: 0.9778212905, green: 0.6510156989, blue: 0.4021205604, alpha: 1), #colorLiteral(red: 0.8516482711, green: 0.9332258105, blue: 0, alpha: 1), #colorLiteral(red: 0, green: 0.9475703835, blue: 0.4974002242, alpha: 1), #colorLiteral(red: 0.05924382061, green: 0.06317590177, blue: 0.3495635092, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 0.7618283629, green: 1, blue: 0.4321216345, alpha: 1), #colorLiteral(red: 0.6178457737, green: 0.2966837287, blue: 0.2622496784, alpha: 1), #colorLiteral(red: 0.05904775113, green: 0.1058480367, blue: 0.8025799394, alpha: 1), #colorLiteral(red: 0, green: 0.7838665247, blue: 0.3135640919, alpha: 1)]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if (IsDebug) {
            self.userName = "Charlottes".lowercased()
        }
        
        self.ref = Database.database().reference()
        readFromDatabase()
    }
    
    func populateDataDay() -> [BarEntry] {
        var result: [BarEntry] = []
        
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
            var value = 0
            let iterateDate = calendar.date(byAdding: .hour, value: i - numHours, to: now)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .hour)) {
                        value += 1
                    }
                }
            }
            
            let height: Float = Float(value) / 5.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH"
            result.append(BarEntry(color: colors[i % colors.count], height: height, textValue: "\(value)", title: formatter.string(from: iterateDate)))
        }
        return result
    }
    
    func populateDataWeek() -> [BarEntry] {
        var result: [BarEntry] = []
        
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
            var value = 0
            let iterateDate = calendar.date(byAdding: .day, value: i - numDays, to: now)!
            
            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject
                
                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)
                
                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)
                    
                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .day)) {
                        value += 1
                    }
                }
            }
            
            let height: Float = Float(value) / 10.0
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            result.append(BarEntry(color: colors[i % colors.count], height: height, textValue: "\(value)", title: formatter.string(from: iterateDate)))
        }
        return result
    }
    
    func populateDataMonth() -> [BarEntry] {
        var result: [BarEntry] = []
        
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "dk_DA")

        let numWeeks = 5

        for i in 1..<(numWeeks + 1) {
            var value = 0
            let iterateDate = calendar.date(byAdding: .weekOfYear, value: i - numWeeks, to: now)!

            for (key, _) in self.observations {
                let element:NSObject = self.observations[key] as! NSObject

                let obsDevice:String! = element.value(forKey: "deviceName") as? String
                let obsUserName = getUserName(deviceName: obsDevice)

                if (obsUserName == self.userName) {
                    let timestamp:String! = element.value(forKey: "timestamp") as? String
                    let obsTime = dateFormatter.date(from: timestamp)

                    if (calendar.isDate(obsTime!, equalTo: iterateDate, toGranularity: .weekOfYear)) {
                        value += 1
                    }
                }
            }

            let height: Float = Float(value) / 30.0

            let formatter = DateFormatter()
            formatter.dateFormat = "ww"
            result.append(BarEntry(color: colors[i % colors.count], height: height, textValue: "\(value)", title: formatter.string(from: iterateDate)))
        }
        return result
    }
    
    func readFromDatabase() {
        self.ref.child("observations").observeSingleEvent(of: .value, with: { (snapshot) in
            self.observations = snapshot.value as? NSDictionary
            
            // Month
            let data = self.populateDataMonth()
            self.barChart.dataEntries = data
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func TimeChanged(_ sender: Any) {
        switch TimeController.selectedSegmentIndex {
        case 0:
            // Day
            let data = populateDataDay()
            barChart.dataEntries = data
            
            break
        case 1:
            // Week
            let data = populateDataWeek()
            barChart.dataEntries = data
            
            break
        case 2:
            // Month
            let data = populateDataMonth()
            barChart.dataEntries = data
            
            break
        default:
            // Month
            let data = populateDataMonth()
            barChart.dataEntries = data
            
            break
        }
    }
}
