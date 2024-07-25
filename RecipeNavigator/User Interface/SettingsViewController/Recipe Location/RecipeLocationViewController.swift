//
//  RecipeLocationViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 5/6/24.
//

import UIKit


class RecipeLocationViewController: UIViewController {
   
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic  = "RecipeLocationViewControllerCell"
        static let detail = "RecipeLocationViewControllerDetailCell"
    }
    
    private struct CellIndexes {
        static let device = 0
        static let iCloud = 1
        static let nas    = 2
        static let unused = 3
    }
    
    private struct StoryboardIds {
        static let nasSelector = "NasDriveSelectorViewController"
    }
    
    private var canSeeCloud                 = false
    private var canSeeNasDataSourceFolders  = false
    private var canSeeCount                 = 0
    private let cloudCentral                = CloudCentral.sharedInstance
    private let nasCentral                  = NASCentral.sharedInstance
    private var navigatorCentral            = NavigatorCentral.sharedInstance
    private var notificationCenter          = NotificationCenter.default
    private var selectedOption              = CellIndexes.device
    private var userDefaults                = UserDefaults.standard
    
    private let optionArray = [ NSLocalizedString( "Title.Device",     comment: "Device" ),
                                NSLocalizedString( "Title.iCloud",     comment: "iCloud" ),
                                NSLocalizedString( "Title.InNASDrive", comment: "Network Accessible Storage" ) ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        if navigatorCentral.pleaseWaiting {
            logTrace( "PleaseWaiting..." )
            return
        }
        
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.RecipeRepository",  comment: "Recipe Repository" )
        
        switch navigatorCentral.dataSourceLocation {
            case .device:      selectedOption = CellIndexes.device
            case .shareCloud:  selectedOption = CellIndexes.iCloud
            case .iCloud:      selectedOption = CellIndexes.iCloud
            case .nas:         selectedOption = CellIndexes.nas
            case .shareNas:    selectedOption = CellIndexes.nas
            default:           logTrace( "ERROR!  SBH!" )
        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        canSeeCount = 1
        canSeeCloud = false
        canSeeNasDataSourceFolders = false
        
        if selectedOption == CellIndexes.iCloud {
            cloudCentral.canSeeCloud( self )
        }
        else if selectedOption == CellIndexes.nas {
            nasCentral.canSeeNasDataSourceFolders( self )
        }
        else {  // Currently on the device 
            canSeeCount = 0
            cloudCentral.canSeeCloud( self )
            nasCentral.canSeeNasDataSourceFolders( self )
        }

        if selectedOption != CellIndexes.device {
            myActivityIndicator.isHidden = false
            myActivityIndicator.startAnimating()
        }
        
        loadBarButtonItems()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let    message = NSLocalizedString( "InfoText.RecipeRepository",  comment: "Once you have specified where your recipes are located (your repository), you can this utility to scan the designated location and create a database on this device for easy access.\n\nThe time it takes to access and display a recipe will depend on where you store your recipe files.  We do NOT copy your recipes files to your device." )

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        configureBackBarButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
    }
    

}



// MARK: CloudCentralDelegate Methods

extension RecipeLocationViewController: CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        self.canSeeCloud = canSeeCloud
        canSeeCount += 1
        
        if canSeeCount > 1 {
            myActivityIndicator.stopAnimating()
            myActivityIndicator.isHidden = true
        }

        myTableView.reloadData()
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool ) {
        logVerbose( "[ %@ ]", stringFor( rootDirectoryIsPresent ) )
        promptToScanNow()
    }

}



// MARK: NASCentralDelegate Methods

extension RecipeLocationViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        self.canSeeNasDataSourceFolders = canSeeNasDataSourceFolders
        canSeeCount += 1
        
        if canSeeCount > 1 {
            myActivityIndicator.stopAnimating()
            myActivityIndicator.isHidden = true
        }

        myTableView.reloadData()
    }

    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension RecipeLocationViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension RecipeLocationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     useDetailCell = ( indexPath.row == CellIndexes.nas ) && canSeeNasDataSourceFolders && ( selectedOption == CellIndexes.nas )
        let     cellID        = useDetailCell ? CellIDs.detail : CellIDs.basic
        
        guard let cell = tableView.dequeueReusableCell( withIdentifier: cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }

        cell.textLabel?.text = optionArray[indexPath.row]
        cell.accessoryType   = ( indexPath.row == selectedOption ) ? .checkmark : .none
        
        if useDetailCell {
            let     descriptor = navigatorCentral.dataSourceDescriptor
            let     fullPath   = String( format: "%@/%@/%@", descriptor.netbiosName, descriptor.share, descriptor.path )
            
            cell.detailTextLabel?.text = fullPath
        }
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension RecipeLocationViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow( at: indexPath, animated: false )
        
        if  indexPath.row == selectedOption && indexPath.row != CellIndexes.nas {
            return
        }
        
        switch indexPath.row {
        case CellIndexes.device:
            selectedOption = CellIndexes.device
            navigatorCentral.dataSourceLocation = .device
            tableView.reloadData()
            promptToScanNow()

        case CellIndexes.nas:
            if selectedOption == CellIndexes.iCloud {
                presentAlert( title  : NSLocalizedString( "AlertTitle.Error",                          comment: "Error!" ),
                              message: NSLocalizedString( "AlertMessage.CannotGoDirectFromCloudToNas", comment: "You can't go from iCloud directly to NAS, you must go back to the Device and then to NAS" ) )
                return
            }
            
            if canSeeNasDataSourceFolders {
                launchNasSelectorViewController()
            }
            else {
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                     comment:  "Error" ),
                              message : NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
            }

        case CellIndexes.iCloud:
            if selectedOption == CellIndexes.nas {
                presentAlert( title  : NSLocalizedString( "AlertTitle.Error",                          comment: "Error!" ),
                              message: NSLocalizedString( "AlertMessage.CannotGoDirectFromNasToCloud", comment: "You can't go from NAS directly to iCloud, you must go back to the Device and then to iCloud" ) )
                return
            }
            
            if canSeeCloud {
                cloudCentral.isRootDirectoryPresent( self )
            }
            else {
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                comment:  "Error" ),
                              message : NSLocalizedString( "AlertMessage.CannotSeeContainer", comment: "Cannot see your iCloud container!  Please go to Settings and verify that you have signed into iCloud with your Apple ID then navigate to the iCloud setting screen and make sure iCloud Drive is on.  Finally, verify that iCloud is enabled for this app." ) )
            }

        default:
            logTrace( "ERROR!  SBH!" )
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods
    
    private func launchNasSelectorViewController() {
        guard let nasDriveSelector: NasDriveSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.nasSelector ) as? NasDriveSelectorViewController else {
            logTrace( "Error!  Unable to load NasDriveSelectorViewController!" )
            return
        }
        
        logTrace()
        nasDriveSelector.mode = .dataSourceLocation
        navigationController?.pushViewController( nasDriveSelector, animated: true )
    }
    
    
    private func promptToScanNow() {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ScanNowPrompt", comment: "Would you like for us to scan your repository now?" ), message: "", preferredStyle : .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            self.navigationController?.popToRootViewController(animated: true )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.repoScanRequested ), object: self )
            }
            
        }

        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .default )
        { ( alertAction ) in
            logTrace( "No Action" )
            self.navigationController?.popToRootViewController(animated: true )
        }

        alert.addAction( yesAction )
        alert.addAction( noAction  )

        present( alert, animated: true, completion: nil )
    }
    
    

}
