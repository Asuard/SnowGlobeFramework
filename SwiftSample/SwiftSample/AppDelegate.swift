//
//  AppDelegate.swift
//  SwiftSample
//
//  Created by stringCode on 11/23/14.
//

import UIKit
import SnowGlobe

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var snowGlobeView: SnowGlobeView?
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if snowGlobeView == nil {
            let bounds = application.keyWindow?.bounds
            snowGlobeView = SnowGlobeView(frame: bounds!)
            snowGlobeView?.shakeToSnow = true
            snowGlobeView?.cellConfiguration.birthRate = 10
            snowGlobeView?.cellConfiguration.velocity = -20
            snowGlobeView?.cellConfiguration.velocityRange = 10
            application.keyWindow?.addSubview(snowGlobeView!)
        }
    }

}
