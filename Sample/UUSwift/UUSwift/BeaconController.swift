//
//  BeaconController.swift
//  UUSwift
//
//  Created by Ryan DeVore on 9/20/17.
//  Copyright © 2017 Useful Utilities. All rights reserved.
//

import UIKit

class BeaconController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    private var tableData : [String] = []

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let rowData = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconCell", for: indexPath) as! BeaconCell
        cell.label.text = rowData
        return cell
    }

}

class BeaconCell : UITableViewCell
{
    @IBOutlet var label: UILabel!
}

