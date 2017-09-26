//
//  BeaconController.swift
//  UUSwift
//
//  Created by Ryan DeVore on 9/20/17.
//  Copyright © 2017 Useful Utilities. All rights reserved.
//

import UIKit
import CoreLocation

class BeaconController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    private var tableData : [UUBeaconRegion] = []

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad()
    {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(handleRegionChanged), name: UUBeaconManager.Notifications.regionChanged, object: nil)
    }

    @objc public func handleRegionChanged(_ sender: Notification)
    {
        print("region did change")
        tableData = UUBeaconManager.shared.cachedRegions()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
     
        UUBeaconManager.shared.monitorBeacon()
    }

    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let rowData = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MonitoredRegionCell", for: indexPath) as! MonitoredRegionCell
        cell.update(rowData)
        return cell
    }
    
    
    
    
    
    
    /*public func hasPermission() -> Bool
    {
        let authStatus = CLLocationManager.authorizationStatus()
        return (authStatus == .authorizedAlways)
    }
    
    public func monitorBeacon()
    {
        let uuid =  UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let region = CLBeaconRegion(proximityUUID: uuid, identifier: "Estimote")
        
        cancelAllMonitoredRegions()
        
        locationManager.startMonitoring(for: region)
    }
    
    public func cancelAllMonitoredRegions()
    {
        let regions = locationManager.monitoredRegions
        for r in regions
        {
            locationManager.stopMonitoring(for: r)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        print("Entered region: \(region)")
        //
        let br = region as! CLBeaconRegion
        print("Entered Region, identifier: \(br.identifier), proximityUUID: \(br.proximityUUID), major: \(String(describing: br.major)), minor: \(String(describing: br.minor)) ")
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        //print("Exited region: \(region)")
        
        let br = region as! CLBeaconRegion
        print("Left Region, identifier: \(br.identifier), proximityUUID: \(br.proximityUUID), major: \(String(describing: br.major)), minor: \(String(describing: br.minor)) ")
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        print("Auth status changed to \(status)")
        
        if (hasPermission())
        {
            monitorBeacon()
        }
    }
    
    private func listMonitoredRegions()
    {
        tableData = locationManager.uuMonitoredBeaconRegions()
        tableView.reloadData()
        
//        for r in locationManager.monitoredRegions
//        {
//            print("Monitored region: \(r)")
//            
//        }
    }
 */

}

class BeaconCell : UITableViewCell
{
    var beaconRegion : CLBeaconRegion? = nil
    
    @IBOutlet var label: UILabel!
    
    func update(_ br: CLBeaconRegion)
    {
        beaconRegion = br
     
        
//        beaconRegion?.identifier
//        beaconRegion?.proximityUUID
//        beaconRegion?.major
//        beaconRegion?.minor

        print("Beacon Region, identifier: \(br.identifier), proximityUUID: \(br.proximityUUID), major: \(String(describing: br.major)), minor: \(String(describing: br.minor)) ")
        
        label.text = br.identifier
    }
}

class MonitoredRegionCell : UITableViewCell
{
    private var region : UUBeaconRegion? = nil
    
    @IBOutlet var regionNameLabel: UILabel!
    @IBOutlet var regionUuidLabel: UILabel!
    @IBOutlet var majorLabel: UILabel!
    @IBOutlet var minorLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    func update(_ r: UUBeaconRegion)
    {
        region = r
        regionNameLabel.text = r.identifier
        regionUuidLabel.text = r.proximityUUID.uuidString
        majorLabel.text = r.major?.stringValue ?? "nil"
        minorLabel.text = r.minor?.stringValue ?? "nil"
        statusLabel.text = String(describing: r.status)
    }
}




public class UUBeaconManager : NSObject, CLLocationManagerDelegate
{
    public struct Notifications
    {
        public static let regionChanged = NSNotification.Name(rawValue: "UUBeaconRegionChanged")
    }
    
    public static let shared = UUBeaconManager()
    
    private var locationManager : CLLocationManager!
    private var cachedRegionMap : [String:UUBeaconRegion] = [:]
    
    
    
    public override required init()
    {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        updateCachedRegions()
    }
    
    public func cachedRegions() -> [UUBeaconRegion]
    {
        return Array(cachedRegionMap.values)
    }
    
    public func requestPermissionIfNeeded()
    {
        if (CLLocationManager.authorizationStatus() == .notDetermined)
        {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    public func hasPermission() -> Bool
    {
        let authStatus = CLLocationManager.authorizationStatus()
        return (authStatus == .authorizedAlways)
    }
    
    public func monitorBeacon()
    {
        let uuid =  UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let region = CLBeaconRegion(proximityUUID: uuid, identifier: "Estimote")
        
        locationManager.uuCancelAllMonitoredRegions()
        
        locationManager.startMonitoring(for: region)
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        updateCachedRegion(region, .inside)
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
    {
        updateCachedRegion(region, .outside)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        print("Auth status changed to \(status)")
        
        if (hasPermission())
        {
            monitorBeacon()
        }
    }
    
    private func updateCachedRegion(_ region : CLRegion, _ status: UUBeaconRegionStatus = .unknown)
    {
        var uuRegion : UUBeaconRegion? = cachedRegionMap[region.identifier]
        if (uuRegion == nil)
        {
            uuRegion = UUBeaconRegion.fromRegion(region)
        }
        
        uuRegion?.updateStatus(status)
        
        if (uuRegion != nil)
        {
            cachedRegionMap[region.identifier] = uuRegion!
            print("updated cached region map: \(uuRegion!)")
            notifyRegionChanged(uuRegion!)
        }
        
        logCachedRegions()
    }
    
    private func updateCachedRegions()
    {
        for r in locationManager.monitoredRegions
        {
            updateCachedRegion(r)
        }
    }
    
    private func logCachedRegions()
    {
        for r in cachedRegionMap
        {
            print("\(r)")
        }
    }
    
    private func notifyRegionChanged(_ region: UUBeaconRegion)
    {
        DispatchQueue.main.async
        {
            NotificationCenter.default.post(name: Notifications.regionChanged, object: region)
        }
    }
}





extension CLLocationManager
{
    public func uuMonitoredBeaconRegions() -> [CLBeaconRegion]
    {
        var list : [CLBeaconRegion] = []
        
        for r in monitoredRegions
        {
            let br = r as? CLBeaconRegion
            if (br != nil)
            {
                list.append(br!)
            }
        }
        
        return list
    }
    
    public func uuCancelAllMonitoredRegions()
    {
        for r in monitoredRegions
        {
            stopMonitoring(for: r)
        }
    }
}

public enum UUBeaconRegionStatus
{
    case inside
    case outside
    case unknown
}

public class UUBeaconRegion : NSObject
{
    private var region : CLBeaconRegion!
    private var _status: UUBeaconRegionStatus = .unknown
    
    public init(region: CLBeaconRegion)
    {
        super.init()
        self.region = region
        _status = .unknown
    }
    
    public func updateStatus(_ status: UUBeaconRegionStatus)
    {
        _status = status
    }
    
    public static func fromRegion(_ r : CLRegion?) -> UUBeaconRegion?
    {
        var uuRegion : UUBeaconRegion? = nil
        
        let beaconRegion = r as? CLBeaconRegion
        if (beaconRegion != nil)
        {
            uuRegion = UUBeaconRegion(region: beaconRegion!)
        }
        
        return uuRegion
    }
    
    public var identifier : String
    {
        return region.identifier
    }
    
    public var proximityUUID : UUID
    {
        return region.proximityUUID
    }
    
    public var major : NSNumber?
    {
        return region.major
    }
    
    public var minor : NSNumber?
    {
        return region.minor
    }
    
    public var status : UUBeaconRegionStatus
    {
        return _status
    }
    
    public override var description: String
    {
        return "id: \(identifier), uuid: \(proximityUUID), major: \(String(describing: major)), minor: \(String(describing: minor)), status: \(status)"
    }
}






