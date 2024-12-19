//
//  ScanRepoViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 6/17/24.
//


import UIKit



class ScanRepoViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var deviceShareLabel: UILabel!
    @IBOutlet weak var pathLabel       : UILabel!
    @IBOutlet weak var myTextView      : UITextView!
    @IBOutlet weak var startButton     : UIButton!
    @IBOutlet weak var stopButton      : UIButton!
    
    
    
    // MARK: Private Variables
    
    private var connectedShare          : SMBShare!
    private var currentPath             = ""
    private let dataSourceCentral       = DataSourceCentral.sharedInstance
    private var directoryArray          : [SMBFile] = []
    private var fileDescriptorArray     = [FileDescriptor].init()
    private let fileManager             = FileManager.default
    private let nasCentral              = NASCentral.sharedInstance
    private var networkPath             = ""
    private let navigatorCentral        = NavigatorCentral.sharedInstance
    private var nasOutputString         = ""
    private var numberOfFilesSkipped    = 0
    private var numberOfRecipesAdded    = 0
    private var scanning                = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.ScanRecipeRepository", comment: "Scan Recipe Repository" )
        myTextView.text = ""
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadLabels()
        
        configureControls( hideStart: false, running: false )
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func startButtonTouched(_ sender: UIButton) {
        logTrace()
        configureControls( hideStart: true, running: true )

        myTextView.text = ""

        numberOfFilesSkipped = 0
        numberOfRecipesAdded = 0

        if navigatorCentral.dataSourceLocation == .device {
            scanDevice()
        }
        else {  // Must be NAS
            scanNAS()
        }
        
    }
    
    
    @IBAction func stopButtonTouched(_ sender: UIButton) {
        configureControls( hideStart: true, running: false )
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls( hideStart: Bool, running: Bool ) {
        scanning = running
        
        startButton.isHidden = hideStart
        stopButton .isHidden = !running
    }
    
    
    private func loadLabels() {
        logTrace()
        if navigatorCentral.dataSourceLocation == .device {
            deviceShareLabel.text = navigatorCentral.deviceName
            pathLabel       .text = NSLocalizedString( "Title.App", comment: "Recipe Navigator" )
        }
        else {  // Must be NAS
            let descriptor = navigatorCentral.dataSourceDescriptor
            
            deviceShareLabel.text = descriptor.netbiosName + "/" + descriptor.share
            pathLabel       .text = descriptor.path
            
            currentPath = descriptor.path
        }
        
    }
    
    
    func scrollTextViewToBottom() {
        if myTextView.text.count > 0 {
            let location = myTextView.text.count - 1
            let bottom = NSMakeRange(location, 1)
            
            myTextView.scrollRangeToVisible(bottom)
        }
        
    }
    
    
}



// MARK: Scanning Methods

extension ScanRepoViewController {
    
    private func scanDevice() {
        logTrace()
        navigatorCentral.deleteAllRecipes( self )
    }
    
    
    private func scanNAS() {
        logTrace()
        nasOutputString = currentPath
        nasCentral.canSeeNasDataSourceFolders( self )
    }
    
    
    
    // MARK: Device Scanning Utility Methods
    
    private func loadTextView() {
        var newText = ""
        
        for descriptor in fileDescriptorArray {
            newText.append( descriptor.name + "\n" )
        }
        
        myTextView.text = newText
    }
    
    
    
    // MARK: NAS Scanning Utility Methods

    private func exploreNextDirectory() {
        if let directory = directoryArray.first {
            currentPath = directory.path
            
            logVerbose( "[ %@ ]\n", currentPath )
            
            nasOutputString += "\n"
            nasOutputString.append( currentPath )
            
            nasCentral.fetchFilesAt( currentPath, self )
            directoryArray.removeFirst()
        }
        else {
            logVerbose( "End of Scan ... directoryArray.count[ %d ]\n", directoryArray.count )
            configureControls( hideStart: true, running: false )

            navigatorCentral.reloadData( self )
        }
        
    }

    
}



// MARK: NASCentralDelegate Methods

extension ScanRepoViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        if canSeeNasDataSourceFolders {
            nasCentral.startDataSourceSession( self )
        }
        else {
            presentAlert( title  : NSLocalizedString( "AlertTitle.Error",                     comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchDirectories: Bool, _ directoryArray: [SMBFile] ) {
        logVerbose( "[ %@ ] adding [ %d ] directories to array [ %d ]", stringFor( didFetchDirectories ), directoryArray.count, self.directoryArray.count )

        if didFetchDirectories && directoryArray.count > 0 {
            self.directoryArray.append(contentsOf: directoryArray )
        }
        
        exploreNextDirectory()
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFiles: Bool, _ fileArray: [SMBFile] ) {
        logVerbose( "[ %@ ] got [ %d ]", stringFor( didFetchFiles ), fileArray.count )
        var filteredArray     = [SMBFile]()
        var directoryContents = currentPath + "\n"

        for file in fileArray {
            let fileExtension = extensionFrom( file.name )
            
            if !fileExtension.isEmpty && GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                filteredArray.append( file )
                
                directoryContents += "\n    "
                directoryContents.append( file.name )
            }
            else {
                numberOfFilesSkipped += 1
            }

        }
        
        directoryContents += "\n"
        
        myTextView.text.append( directoryContents )
        scrollTextViewToBottom()

        navigatorCentral.addRecipesFrom( filteredArray, self )
        nasCentral.fetchDirectoriesFrom( connectedShare, currentPath, self )
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )

        if didOpenShare {
            navigatorCentral.deleteAllRecipes( self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {
        logVerbose( "[ %@ ]", stringFor( didStartDataSourceSession ) )

        if didStartDataSourceSession {
            connectedShare = share
            nasCentral.openShare( share, self )
        }
        else {
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment:  "Error" ),
                          message : NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension ScanRepoViewController: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddRecipes: Bool, count: Int) {
        logVerbose( "[ %@ ] [ %d ]", stringFor( didAddRecipes ), count )
        
        if didAddRecipes {
            numberOfRecipesAdded += count
        }
        else {
            presentAlert(title  : NSLocalizedString( "AlertTitle.Error",                comment: "Error!" ),
                         message: NSLocalizedString( "AlertMessage.UnableToAddRecipes", comment: "We are unable to add the recipes we found!  Please try again." ) )
        }

    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteAllRecipes: Bool) {
        logVerbose( "[ %@ ]", stringFor( didDeleteAllRecipes ) )
        
        if didDeleteAllRecipes {
            if navigatorCentral.dataSourceLocation == .device {
                fileDescriptorArray = dataSourceCentral.scanDeviceRepo()
                loadTextView()
                configureControls( hideStart: true, running: false )

                navigatorCentral.reloadRecipesFrom( fileDescriptorArray, self )
            }
            else {
                nasCentral.fetchFilesAt( currentPath, self )
            }
            
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.UnableToDeleteRecipes",   comment: "Delete Failed!" ),
                                   message: NSLocalizedString( "AlertMessage.UnableToDeleteRecipes", comment: "We were unable to delete all of your recipes!  This may leave unwanted recipes in your database." ) )
            }
            
        }
        
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes: Bool ) {
        logVerbose( "loaded [ %d ] recipes", navigatorCentral.numberOfRecipesLoaded )
        
        if !scanning {
            navigatorCentral.cleanUpAfterScan()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.presentAlert( title  :                 NSLocalizedString( "AlertTitle.ScanComplete",         comment: "Scan Complete" ),
                                   message: String( format: NSLocalizedString( "AlertMessage.ScanCompleteFormat", comment: "Added %d recipes" ), self.navigatorCentral.numberOfRecipesLoaded ) )
            }

        }
        else {
            logTrace( "ERROR!!!  SBH if still scanning!" )
        }

    }


}


