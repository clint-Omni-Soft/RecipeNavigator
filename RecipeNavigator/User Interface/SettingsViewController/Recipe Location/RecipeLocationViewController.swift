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
        static let nas    = 1
        static let unused = 2
    }
    
    private struct StoryboardIds {
        static let nasSelector = "NasDriveSelectorViewController"
    }
    
    private let nasCentral                  = NASCentral.sharedInstance
    private var navigatorCentral            = NavigatorCentral.sharedInstance
    private var notificationCenter          = NotificationCenter.default
    private var selectedOption              = CellIndexes.device
    private var userDefaults                = UserDefaults.standard
    
    private let optionArray = [ NSLocalizedString( "Title.Device",     comment: "Device" ),
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
            case .nas:         selectedOption = CellIndexes.nas
            case .shareNas:    selectedOption = CellIndexes.nas
            default:           logTrace( "ERROR!  SBH!" )
        }

        myActivityIndicator.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )

        loadBarButtonItems()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func backBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        navigationController?.popViewController(animated: true )
    }
    
    
    @IBAction func questionBarButtonTouched(_ sender : UIBarButtonItem ) {
        let     message = NSLocalizedString( "InfoText.DataStoreLocation1", comment: "DATA STORE LOCATION\n\nWe provide support for two different storage location options...\n\n   (a) on your device (default) or \n   (b) on a Network Accessible Storage (NAS) unit that supports SMB 1.0.\n\n" ) +
                          NSLocalizedString( "InfoText.DataStoreLocation2", comment: "The key point here is that there is no sharing on the device.  If you chose NAS then anyone who has access to your Wi-Fi can access it.\n" )

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        var leftBarButtonItems = [UIBarButtonItem]()
        
        leftBarButtonItems.append( backBarButtonItem( #selector( backBarButtonTouched(_:) ) ) )
        leftBarButtonItems.append( UIBarButtonItem.init( image: UIImage(systemName: "questionmark.circle" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) ) )
        
        navigationItem.leftBarButtonItems = leftBarButtonItems
    }
    

}



// MARK: NASCentralDelegate Methods

extension RecipeLocationViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )

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
        let     useDetailCell = ( indexPath.row == CellIndexes.nas ) && ( selectedOption == CellIndexes.nas )
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
            launchNasSelectorViewController()

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
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.navigationController?.popToRootViewController(animated: true )
            }
            else {
                if let settingsViewController = self.navigationController?.viewControllers[1] {
                    self.navigationController?.popToViewController( settingsViewController, animated: true)
                }
                
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.repoScanRequested ), object: self )
            }
            
        }

        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .default )
        { ( alertAction ) in
            logTrace( "No Action" )
            if let settingsViewController = self.navigationController?.viewControllers[1] {
                self.navigationController?.popToViewController( settingsViewController, animated: true)
            }
            
        }

        alert.addAction( yesAction )
        alert.addAction( noAction  )

        present( alert, animated: true, completion: nil )
    }
    
    

}
