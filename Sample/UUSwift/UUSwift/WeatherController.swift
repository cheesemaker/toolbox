//
//  WeatherController.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

class WeatherTableRow : NSObject
{
    // Tuesday, July 3rd 2017
    
    static let kDateFormat : String =
        "\(UUDate.Formats.longDayOfWeek), \(UUDate.Formats.longMonthOfYear) \(UUDate.Formats.dayOfMonth) \(UUDate.Formats.fourDigitYear)"
    
    var date : Date = Date()
    var lowTemp : Double = 0
    var highTemp : Double = 0
    
    func formatDate() -> String
    {
        return date.uuFormat(WeatherTableRow.kDateFormat)
    }
    
    func formatTemp() -> String
    {
        return "High \(highTempAsFahrenheit) / Low \(lowTempAsFahrenheit)"
    }
    
    var lowTempAsFahrenheit : Double
    {
        return celsiusToFahrenheit(lowTemp)
    }
    
    var highTempAsFahrenheit : Double
    {
        return celsiusToFahrenheit(highTemp)
    }
    
    func celsiusToFahrenheit(_ celsius: Double) -> Double
    {
        return ((celsius * (9 / 5)) + 32)
    }
}

class WeatherController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet var tableView: UITableView!
    
    private var tableData: [WeatherTableRow] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        WeatherService.shared.fetchWeather(city: "Wilsonville", country: "United States")
        { (err: Error?) in
        
            print ("Weather fetch done")
            
            let context = UUCoreData.mainThreadContext!
            context.perform
            {
                let results = WeatherRecord.uuFetchObjects(context: context)
                
                for obj in results
                {
                    let realObj = obj as? WeatherRecord
                    if (realObj != nil)
                    {
                        let row = WeatherTableRow()
                        row.lowTemp = realObj!.minTemperature
                        row.highTemp = realObj!.maxTemperature
                        row.date = realObj!.timestamp! as Date
                        
                        self.tableData.append(row)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableCell", for: indexPath) as! WeatherTableCell
        let cellData = tableData[indexPath.row]
        cell.update(cellData)
        return cell
    }
}

class WeatherTableCell : UITableViewCell
{
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    
    func update(_ cellData: WeatherTableRow)
    {
        dateLabel.text = cellData.formatDate()
        tempLabel.text = cellData.formatTemp()
    }
    
}



