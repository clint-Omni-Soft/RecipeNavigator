//
//  AppDelegate.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 4/12/24.
//


import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // MARK: Public Definitions
    var hidePrimary        = false
    var recipeViewer       : RecipeViewerViewController!
    var splitViewController: UISplitViewController!
    var window             : UIWindow?
    
    
    // MARK: Private Definitions
    private let navigatorCentral   = NavigatorCentral.sharedInstance
    private let notificationCenter = NotificationCenter.default
    private let userDefaults       = UserDefaults.standard

    private var activeWindow: UIWindow? {
        get {
            var myWindow = window
            
            if myWindow == nil {
                let sceneDelegate = (UIApplication.shared.connectedScenes.first as? UIWindowScene)!.delegate as! SceneDelegate
                myWindow = sceneDelegate.window
            }
            
            return myWindow
        }
        
    }


    
    // MARK: UIApplication Lifecycle Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        setRepoDirectory()

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

    func configureSplitViewController() {
        logTrace()
        if haveLinkToSplitViewController() {
            splitViewController.presentsWithGesture = false
            
            let minimumWidth = min( CGRectGetWidth( splitViewController.view.bounds ), CGRectGetHeight( splitViewController.view.bounds ) )
            
            splitViewController.minimumPrimaryColumnWidth = minimumWidth / 2
            splitViewController.maximumPrimaryColumnWidth = minimumWidth;
        }

    }

    
    func hidePrimaryView(_ isHidden: Bool ) {
        if haveLinkToSplitViewController() {
            hidePrimary = isHidden

            UIView.animate(withDuration: 0.5 ) { () -> Void in
                self.splitViewController?.preferredDisplayMode = self.hidePrimary ? UISplitViewController.DisplayMode.secondaryOnly : UISplitViewController.DisplayMode.oneBesideSecondary
            }
            
        }
       
        if self.recipeViewer != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.recipeViewer.primaryWindow( isHidden )
            }
            
        }
        
    }
    
    
    func primaryIsHidden() -> Bool {
        var isHidden = true
        
        if haveLinkToSplitViewController() {
            isHidden = splitViewController.isCollapsed
        }

        return isHidden
    }
    
    
    func switchToMainApp() {
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        logVerbose( "[ %@ ]", storyboardName )
        splitViewController = nil
        navigatorCentral.didOpenDatabase = false
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = false

            activeWindow?.rootViewController = initialViewController
            activeWindow?.makeKeyAndVisible()
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                configureSplitViewController()
            }
            
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func haveLinkToSplitViewController() -> Bool {
        var foundIt = true
        
        if splitViewController == nil {
            if let splitVC = self.activeWindow?.rootViewController as? UISplitViewController {
                splitViewController = splitVC
            }
            else {
                foundIt = false
                logVerbose( "NOT instantiated!" )
            }

        }
        
        return foundIt
    }
    
    
    private func setRepoDirectory() {
        var repoDirectory = ""
        
        if let directory = userDefaults.string( forKey: UserDefaultKeys.repoDirectory ) {
            repoDirectory = directory
        }

        if repoDirectory.isEmpty {
            // TODO: Configure DirectoryNames.xxxxx for each application
            userDefaults.set( DirectoryNames.recipes, forKey: UserDefaultKeys.repoDirectory )
            userDefaults.synchronize()
        }

    }


    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            navigatorCentral.pleaseWaiting = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.activeWindow?.rootViewController = initialViewController
                self.activeWindow?.makeKeyAndVisible()
            }

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


