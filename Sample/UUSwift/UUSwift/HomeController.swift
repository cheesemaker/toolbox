//
//  HomeController.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit

class HomeTableRow : NSObject
{
    var label : String = ""
    
    var action: () -> Void = { }
    
    required init(_ label : String, _ action: @escaping () -> Void)
    {
        super.init()
        self.label = label
        self.action = action
    }
}

class HomeController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet var tableView: UITableView!
    
    private var tableData: [HomeTableRow] = []

    override func viewDidLoad()
    {
        super.viewDidLoad()

        tableData.append(HomeTableRow("UUWeather", loadWeather))
        tableData.append(HomeTableRow("Ron Swanson Quotes", loadRSQuotes))
        tableData.append(HomeTableRow("Image Gallery", loadImageGallery))
        
        tableView.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableCell", for: indexPath) as! HomeTableCell
        let cellData = tableData[indexPath.row]
        cell.update(cellData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cellData = tableData[indexPath.row]
        cellData.action()
    }
    
    private func loadWeather()
    {
        performSegue(withIdentifier: "showWeatherController", sender: nil)
    }
    
    private func loadRSQuotes()
    {
        performSegue(withIdentifier: "showRSQuotes", sender: nil)
    }
    
    private func loadImageGallery()
    {
        performSegue(withIdentifier: "showImageGallery", sender: nil)
    }
}

class HomeTableCell : UITableViewCell
{
    @IBOutlet var label: UILabel!
    
    func update(_ cellData: HomeTableRow)
    {
        label.text = cellData.label
    }
}


