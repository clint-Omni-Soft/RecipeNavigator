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
    
    private let cloudCentral            = CloudCentral.sharedInstance
    private var connectedShare          : SMBShare!
    private var currentPath             = ""
    private var directoryArray          : [SMBFile] = []
    private var directoryContentsArray  = [FileDescriptor].init()
    private let fileManager             = FileManager.default
    private let nasCentral              = NASCentral.sharedInstance
    private var networkPath             = ""
    private let navigatorCentral        = NavigatorCentral.sharedInstance
    private var nasOutputString         = ""
    private var numberOfFilesSkipped    = 0
    private var numberOfRecipesAdded    = 0
    private var rootUrl                 = URL.init( fileURLWithPath: "" )
    private var startingUrl             = URL.init( fileURLWithPath: "" )
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
        configureControls()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func startButtonTouched(_ sender: UIButton) {
        logTrace()
        scanning = true
        configureControls()
        
        myTextView.text = ""

        numberOfFilesSkipped = 0
        numberOfRecipesAdded = 0
        navigatorCentral.flushViewerRecipes()

        if navigatorCentral.dataSourceLocation == .device {
            scanDevice()
        }
        else if navigatorCentral.dataSourceLocation == .iCloud || navigatorCentral.dataSourceLocation == .shareCloud {
            scanCloud()
        }
        else {  // Must be NAS
            scanNAS()
        }
        
    }
    
    
    @IBAction func stopButtonTouched(_ sender: UIButton) {
        scanning = false
        configureControls()
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        startButton.isEnabled = !scanning
        stopButton .isEnabled = scanning
    }
    
    
    private func loadLabels() {
        logTrace()
        if navigatorCentral.dataSourceLocation == .device {
            deviceShareLabel.text = navigatorCentral.deviceName
            pathLabel       .text = NSLocalizedString( "Title.App", comment: "Recipe Navigator" )
        }
        else if navigatorCentral.dataSourceLocation == .iCloud || navigatorCentral.dataSourceLocation == .shareCloud {
            deviceShareLabel.text = NSLocalizedString( "Title.iCloud", comment: "iCloud"           )
            pathLabel       .text = NSLocalizedString( "Title.App",    comment: "Recipe Navigator" )
        }
        else {  // Must be NAS
            let descriptor = navigatorCentral.dataSourceDescriptor
            
            deviceShareLabel.text = descriptor.netbiosName + "/" + descriptor.share
            pathLabel       .text = descriptor.path
            
            currentPath = descriptor.path
        }
        
    }
    
    
}



// MARK: Scanning Methods

extension ScanRepoViewController {
    
    private func scanCloud() {
        logTrace()
        // TODO: Fill me in!
        presentAlert(title: "ERROR!", message: "iCloud support NOT yet implemeted!" )
    }
    
    
    private func scanDevice() {
        logTrace()
        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            rootUrl     = url
            startingUrl = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectory URL" )
            rootUrl     = URL( fileURLWithPath: "" )
            startingUrl = URL( fileURLWithPath: "" )
        }
        
        loadDirectoryContentsArray()
        loadTextView()
        navigatorCentral.reloadRecipesFrom( directoryContentsArray, self )
        
        scanning = false
        configureControls()
    }
    
    
    private func scanNAS() {
        logTrace()
        nasOutputString = currentPath
        nasCentral.canSeeNasDataSourceFolders( self )
    }
    
    
    
    // MARK: Device Scanning Utility Methods
    
    private func loadDirectoryContentsArray() {
        var contentsArray: [FileDescriptor] = []
        var filenameArray: [String] = []
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: startingUrl.path )
            
            //            logTrace()
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1)
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Don't show hidden files or the Library folder
                if startingString == "." || filename == "Library" || filename == "Logs" || filename.contains( "sqlite" ) {
                    continue
                }
                
                // Flag databases and directories
                var     fileType     = DescriptorFileTypes.other
                let     fileUrl      = startingUrl.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if isaDirectory.boolValue {
                        let storeContentUrl = fileUrl.appendingPathComponent( "StoreContent" )
                        
                        fileType = FileManager.default.fileExists( atPath: storeContentUrl.path ) ? .database : .directory
                    }
                    
                }
                
                let fileExtension = extensionFrom( filename )
                
                if !fileExtension.isEmpty &&  GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                    numberOfRecipesAdded += 1
                    contentsArray.append( FileDescriptor.init( filename, "", fileUrl, fileType ) )
                }
                else if fileExtension == "DOC" || fileExtension == "DOCX" {
                    numberOfFilesSkipped += 1
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
        directoryContentsArray = contentsArray.sorted(by:
        { fileDescriptor1, fileDescriptor2 in
            return fileDescriptor1.name < fileDescriptor2.name
        })
        
    }
    
    
    private func loadTextView() {
        var newText = ""
        
        for descriptor in directoryContentsArray {
            newText.append( descriptor.name + "\n" )
        }
        
        myTextView.text = newText
    }
    
    
    
    // MARK: NAS Scanning Utility Methods

    private func exploreNextDirectory() {
        if let directory = directoryArray.first {
            currentPath = directory.path
            
            logVerbose( "[ %@ ]", currentPath )
            
            nasOutputString += "\n"
            nasOutputString.append( currentPath )
            
            nasCentral.fetchFilesAt( currentPath, self )
            directoryArray.removeFirst()
        }
        else {
            scanning = false
            configureControls()
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
        logVerbose( "[ %@ ] got [ %d ]", stringFor( didFetchDirectories ), directoryArray.count )

        if didFetchDirectories {
            self.directoryArray += directoryArray
        }
        
        exploreNextDirectory()
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFiles: Bool, _ fileArray: [SMBFile] ) {
        logVerbose( "[ %@ ] got [ %d ]", stringFor( didFetchFiles ), fileArray.count )
        var filteredArray: [SMBFile] = []

        for file in fileArray {
            let fileExtension = extensionFrom( file.name )
            
            if !fileExtension.isEmpty && GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                filteredArray.append( file )
                
                nasOutputString += "\n    "
                nasOutputString.append( file.name )
            }
            else {
                numberOfFilesSkipped += 1
            }

        }
        
        nasOutputString += "\n"
        
        myTextView.text = nasOutputString
        
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
            nasCentral.fetchFilesAt( currentPath, self )
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.UnableToDeleteRecipes",   comment: "Delete Failed!" ),
                                   message: NSLocalizedString( "AlertMessage.UnableToDeleteRecipes", comment: "We were unable to delete all of your recipes!  This may leave unwanted recipes in your database." ) )
            }
        }
        
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes: Bool ) {
        logVerbose( "loaded [ %d ] recipes", navigatorCentral.numberOfRecipesLoaded )
        
        if !scanning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.presentAlert( title  :                 NSLocalizedString( "AlertTitle.ScanComplete",         comment: "Scan Complete" ),
                                   message: String( format: NSLocalizedString( "AlertMessage.ScanCompleteFormat", comment: "Added %d recipes and skipped %d files." ), self.numberOfRecipesAdded, self.numberOfFilesSkipped ) )
            }

        }

    }


}


