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
    
//    private let cloudCentral        = CloudCentral.sharedInstance
    private var connectedShare      : SMBShare!
    private let dataSourceCentral   = DataSourceCentral.sharedInstance
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
        recipeFilenameLabel.text  = (recipe.relativePath ?? "??") + "\n" + (recipe.filename ?? "???")
        
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
            self.dataSourceCentral.requestViewerDataFor( self.recipe, self )
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

    
    @IBAction func favoriteBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        promptToChangeFavoriteStatus()
    }
    
    

    // MARK: Utility Methods
    
    private func displayRichTextFile(_ data: Data ) {
        if let attributedString = try? NSAttributedString( data: data, options: rtfAttributedStringOptions, documentAttributes: nil ) {
            myTextView.attributedText = attributedString
        }
        else {
            logTrace( "Attributed string conversion failed!" )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        var rightBarButtonItemArray = [UIBarButtonItem]()
        
        if !loadingData {
            let favoriteIconName = recipe.favoriteRecipe != nil ? "heart-selected" : "heart-empty"
                
            rightBarButtonItemArray.append( UIBarButtonItem.init( barButtonSystemItem: .add, target: self, action: #selector( addBarButtonItemTouched(_:) ) ) )
            rightBarButtonItemArray.append( UIBarButtonItem.init( image: UIImage(named: favoriteIconName ), style: .plain, target: self, action: #selector( favoriteBarButtonTouched(_:) ) ) )
        }

        navigationItem.rightBarButtonItems = rightBarButtonItemArray
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
    
    
    private func presentDocument(_ data: Data ) {
        let mimeType = navigatorCentral.mimeTypeFor( recipe )
        
        loadingData = false
        loadBarButtonItems()

        myActivityIndicator.stopAnimating()
        
        switch navigatorCentral.mimeTypeFor( recipe ) {
            case FileMimeTypes.rtf:     myTextView.isHidden = false
                                        displayRichTextFile( data )
            
            default:                    myWebView.isHidden = false
                                        myWebView.load( data, mimeType: mimeType, characterEncodingName: "UTF8", baseURL: URL(string: "http://localhost")! )
        }
            
    }
    
   
    private func promptToChangeFavoriteStatus() {
        let isFavorite = recipe.favoriteRecipe != nil
        let title      = isFavorite ? NSLocalizedString( "ButtonTitle.RemoveFromFavorites", comment: "Remove from Favorites" ) : NSLocalizedString( "ButtonTitle.AddToFavorites", comment: "Add to Favorites" )

        let     alert  = UIAlertController.init( title: title, message: nil, preferredStyle: .alert)

        let yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .destructive )
        { ( alertAction ) in
            if isFavorite {
                logTrace( "YES Action ... Remove from Favorites" )
                self.navigatorCentral.removeFromFavorites( self.recipe, self )
            }
            else {
                logTrace( "YES Action ... Add to Favorites" )
                self.navigatorCentral.addToFavorites( self.recipe, self )
            }
            
        }
        
        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No!" ), style: .cancel, handler: nil )

        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}



// MARK: DataSourceCentralDelegate Methods

extension QuickLookViewController: DataSourceCentralDelegate {
    
    func dataSourceCentral(_ dataSourceCentral: DataSourceCentral, didFetch: Bool, data: Data, from recipe: Recipe ) {
        logVerbose( "[ %@ ]", stringFor( didFetch ) )
        if didFetch {
            fileData = data // hold onto this for our callback
            presentDocument( data )
        }
        else {
            presentAlertAndPopVC( NSLocalizedString( "AlertMessage.CannotReadFileData", comment: "We cannot the data from this recipe." ) )
        }
        
    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension QuickLookViewController: NavigatorCentralDelegate {
    
    func navigatorCentralDidUpdateFavoriteRecipes(_ navigatorCentral: NavigatorCentral) {
        logTrace()
        loadBarButtonItems()
    }
    
    
}
