//
//  AppDelegate.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 4/12/24.
//


import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // Public Definitions
    var hidePrimary = false
    var window      : UIWindow?
    
    
    // Private Definitions
    private let navigatorCentral   = NavigatorCentral.sharedInstance
    private let notificationCenter = NotificationCenter.default
    private var splitViewController: UISplitViewController!

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        navigatorCentral.enteringForeground()

        if navigatorCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }

        if #available(iOS 15, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            setSplitViewControllerDelegate()
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

    func hidePrimaryView(_ isHidden: Bool ) {
        if splitViewController != nil {
            hidePrimary = isHidden

            UIView.animate(withDuration: 0.5 ) { () -> Void in
                self.splitViewController?.preferredDisplayMode = self.hidePrimary ? UISplitViewController.DisplayMode.secondaryOnly : UISplitViewController.DisplayMode.oneBesideSecondary
            }
            
        }
       
        logVerbose( "hidePrimary[ %@ ]", stringFor( hidePrimary ) )
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.splitViewChanged ), object: self )
    }
    
    
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
    
    private func setSplitViewControllerDelegate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            if let splitVC = self.window!.rootViewController as? UISplitViewController {
                self.splitViewController          = splitVC
//                self.splitViewController.delegate = self
                self.splitViewController.presentsWithGesture = false
                logTrace( "Captured pointer to SplitViewController" )
            }
            else {
                logTrace( "ERROR!  Could NOT capture pointer to SplitViewController!" )
            }

        }

    }
    
    
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


