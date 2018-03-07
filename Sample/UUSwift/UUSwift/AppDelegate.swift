//
//  AppDelegate.swift
//  UUSwift
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//

import UIKit
import CoreData
import UUToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        setupCoreData()
        return true
    }

    private func setupCoreData()
    {
        let url = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library").appendingPathComponent("UUSwift.db")
        UUCoreData.configure(url: url)
    }
    
}

