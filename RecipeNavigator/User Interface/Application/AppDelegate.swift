//
//  AppDelegate.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 4/12/24.
//


import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    let navigatorCentral = NavigatorCentral.sharedInstance
    var window: UIWindow?

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        navigatorCentral.enteringForeground()

        if navigatorCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }

        if #available(iOS 15, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }
        
        return true
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logTrace()
        if navigatorCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }

        navigatorCentral.enteringForeground()
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        logTrace()
        navigatorCentral.enteringBackground()
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        logTrace()
        navigatorCentral.enteringBackground()
    }

    
    
    // MARK: Public Interfaces

    func switchToMainApp() {
        logTrace()
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        navigatorCentral.didOpenDatabase = false
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = false

            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = true
            
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }

    }


}



// MARK: NavigatorCentralDelegate Methods

extension AppDelegate: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            navigatorCentral.reloadData( self )
        }
        
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes: Bool ) {
        logTrace()

        if navigatorCentral.dataStoreLocation == .device {
            if .pad == UIDevice.current.userInterfaceIdiom {
                logTrace( "Posting recipeArrayReloaded" )
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.recipeArrayReloaded ), object: self )
            }

        }

        logTrace( "Posting ready" )
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    

}

