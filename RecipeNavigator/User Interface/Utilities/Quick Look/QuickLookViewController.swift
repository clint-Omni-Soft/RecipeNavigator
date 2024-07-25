//
//  QuickLookViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 7/5/24.
//

import UIKit
import WebKit


protocol QuickLookViewControllerDelegate: AnyObject {
    func quickLookViewControllerWantsToAddRecipeToViewer(_ quickLookViewController: QuickLookViewController, _ data: Data )
}



class QuickLookViewController: UIViewController {
    
    
    // MARK: Public Variables
    
    var delegate: QuickLookViewControllerDelegate!
    var recipe  : Recipe!
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTextView         : UITextView!
    @IBOutlet weak var myWebView          : WKWebView!
    @IBOutlet weak var recipeFilenameLabel: UILabel!

    
    
    // MARK: Private Variables
    
    private let cloudCentral        = CloudCentral.sharedInstance
    private var connectedShare      : SMBShare!
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var fileData            : Data!
    private let fileManager         = FileManager.default
    private var loadingData         = true
    private let nasCentral          = NASCentral.sharedInstance
    private let navigatorCentral    = NavigatorCentral.sharedInstance

    private let rtfAttributedStringOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue ]

    
    
    // MARK: UIViewController Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        logVerbose( "[ %@ ]", recipe.filename! )
        
        self.navigationItem.title = NSLocalizedString( "Title.QuickLook", comment: "Quick Look" )
        recipeFilenameLabel.text  = recipe.filename
        
        configureBackBarButtonItem()
        
        myActivityIndicator.startAnimating()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear( animated )
        logTrace()
        
        myTextView.text     = ""
        myTextView.isHidden = true
        myWebView .isHidden = true
        
        loadBarButtonItems()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.requestData()
        }

    }

    
    
    // MARK: Target / Action Methods
    
    @IBAction func addBarButtonItemTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            self.delegate.quickLookViewControllerWantsToAddRecipeToViewer( self, self.fileData )
            self.navigationController?.popViewController(animated: true )
        }
        
    }

    
    
    // MARK: Utility Methods
    
    private func displayRichTextFile() {
        if let attributedString = try? NSAttributedString( data: fileData, options: rtfAttributedStringOptions, documentAttributes: nil ) {
            myTextView.attributedText = attributedString
        }
        else {
            logTrace( "Attributed string conversion failed!" )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        navigationItem.rightBarButtonItem = loadingData ? nil : UIBarButtonItem.init( barButtonSystemItem: .add, target: self, action: #selector( addBarButtonItemTouched(_:) ) )
    }
    
    
    private func presentAlertAndPopVC(_ message: String ) {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.Error", comment:  "Error" ), message: message, preferredStyle: .alert)

        let okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "okAction" )
            self.navigationController?.popViewController(animated: true )
        }
        
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func presentDocument() {
        let mimeType = navigatorCentral.mimeTypeFor( recipe )
        
        loadingData = false
        loadBarButtonItems()

        myActivityIndicator.stopAnimating()
        
        switch navigatorCentral.mimeTypeFor( recipe ) {
            case FileMimeTypes.rtf:     myTextView.isHidden = false
                                        displayRichTextFile()
            
            default:                    myWebView.isHidden = false
                                        myWebView.load( fileData, mimeType: mimeType, characterEncodingName: "UTF8", baseURL: URL(string: "http://localhost")! )
        }
            
    }
    
   
    private func requestData() {
        if navigatorCentral.dataSourceLocation == .device {
            fileData = navigatorCentral.fetchFromDevice( recipe )
            presentDocument()
        }
        else if navigatorCentral.dataSourceLocation == .iCloud || navigatorCentral.dataSourceLocation == .shareCloud {
            cloudCentral.canSeeCloud( self )
        }
        else {  // Must be NAS
            nasCentral.canSeeNasDataSourceFolders( self )
        }

    }
    
    
}



// MARK: CloudCentralDelegate Methods

extension QuickLookViewController: CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool ) {
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        if canSeeCloud {
            cloudCentral.startSession( self )
        }
        else {
            deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false)
            logVerbose( "%@", deviceAccessControl.descriptor() )
            
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.CannotSeeContainer", comment: "Cannot see your iCloud container!  Please go to Settings and verify that you have signed into iCloud with your Apple ID then navigate to the iCloud setting screen and make sure iCloud Drive is on.  Finally, verify that iCloud is enabled for this app." ) )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession: Bool) {
        logVerbose( "[ %@ ]", stringFor( didEndSession ) )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchFile: Bool, _ data: Data) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        if didFetchFile {
            fileData = data
            presentDocument()
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.CannotReadFileData", comment: "We cannot the data from this recipe." ) )
        }

        cloudCentral.endSession( self )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            cloudCentral.fetchFileOn( recipe.filename!, self )
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    
}



// MARK: NASCentralDelegate Methods

extension QuickLookViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        if canSeeNasDataSourceFolders {
            nasCentral.startDataSourceSession( self )
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFile: Bool, _ data: Data ) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        if didFetchFile {
            fileData = data
            presentDocument()
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.UnableToFetchFileFromNAS", comment: "Unable to fetch file from NAS!" ) )
        }
        
    }

    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )
        var filePathAndName = ""
        
        if let relativePath = recipe.relativePath, let filename = recipe.filename {
            filePathAndName = relativePath + "/" + filename
        }

        if didOpenShare {
            nasCentral.fetchFileOn( connectedShare, filePathAndName, self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {
        logVerbose( "[ %@ ]", stringFor( didStartDataSourceSession ) )

        if didStartDataSourceSession {
            connectedShare = share
            nasCentral.openShare( share, self )
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.UnableToStartSession", comment: "Unable to start a session with the selected share!" ) )
        }
        
    }
    
    

}



