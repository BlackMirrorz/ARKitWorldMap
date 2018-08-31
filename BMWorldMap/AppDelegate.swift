//
//  AppDelegate.swift
//  BMWorldMap
//
//  Created by Josh Robbins on 31/08/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

//---------------------------
//MARK: - Custom File Sharing
//---------------------------

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
   
    //1. List Our Custom File Type Which Will Hold Our ARWorldMap
    guard url.pathExtension == "bmarwp" else { return false }
    
    //2. Post Our Data
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MapReceived"), object: nil, userInfo: ["MapData" : url])
    
    return true
}

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }
    
    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }


}

