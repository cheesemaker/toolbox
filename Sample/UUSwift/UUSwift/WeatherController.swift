//
//  WeatherController.swift
//  UUSwift
//
//  Created by Ryan DeVore on 7/3/17.
//  Copyright © 2017 Useful Utilities. All rights reserved.
//

import UIKit

class WeatherTableRow : NSObject
{
    // Tuesday, July 3rd 2017
    
    static let kDateFormat : String =
        "\(UUDate.Formats.longDayOfWeek), \(UUDate.Formats.longMonthOfYear) \(UUDate.Formats.dayOfMonth) \(UUDate.Formats.fourDigitYear)"
    
    var date : Date = Date()
    var lowTemp : Float = 0
    var highTemp : Float = 0
    
    func formatDate() -> String
    {
        return date.uuFormat(WeatherTableRow.kDateFormat, TimeZone.current, Locale.current)
    }
    
    func formatTemp() -> String
    {
        return "High \(highTemp) / Low \(lowTemp)"
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
        
        var row = WeatherTableRow()
        row.lowTemp = 50
        row.highTemp = 80
        row.date = Date()
        tableData.append(row)
        
        row = WeatherTableRow()
        row.lowTemp = 45
        row.highTemp = 75
        row.date = Date().addingTimeInterval(-UUDate.Constants.secondsInOneDay * 2)
        tableData.append(row)
        
        row = WeatherTableRow()
        row.lowTemp = 53
        row.highTemp = 68
        row.date = Date().addingTimeInterval(-UUDate.Constants.secondsInOneDay * 3)
        tableData.append(row)
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



