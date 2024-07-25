//
//  RecipeDisplayViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 7/11/24.
//

import UIKit
import WebKit



class RecipeDisplayViewController: UIViewController {
    
       // MARK: Public Variables
       
    var pageIndex = 0
    var recipe: Recipe!

    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTextView         : UITextView!
    @IBOutlet weak var myWebView          : WKWebView!
    @IBOutlet weak var recipeFilenameLabel: UILabel!

    
    
    // MARK: Private Variables
    
    private var fileData         : Data!
    private let fileManager      = FileManager.default
    private let nasCentral       = NASCentral.sharedInstance
    private let navigatorCentral = NavigatorCentral.sharedInstance

    private let rtfAttributedStringOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue ]

    
    
    // MARK: Public Methods
    
    func reload() {
        logTrace()
        presentDocument()
        myActivityIndicator.stopAnimating()
    }
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logVerbose( "[ %@ ]", recipe.filename! )
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.RecipeViewer", comment: "Recipe Viewer" )
        recipeFilenameLabel.text  = recipe.filename
        
        myTextView.text     = ""
        myTextView.isHidden = true
        
        myWebView .allowsBackForwardNavigationGestures = false
        myWebView .isHidden           = true
        myWebView .navigationDelegate = self
        
        configureBackBarButtonItem()
        
        myActivityIndicator.startAnimating()
    }
    

    override func viewDidAppear(_ animated: Bool) {
        logTrace()
        super.viewDidAppear(animated)
        
        if fileData != nil {
            presentDocument()
            myActivityIndicator.stopAnimating()
        }
        else {
            if let data = navigatorCentral.fetchViewerDataFileFor( recipe ) {
                fileData = data
                
                presentDocument()
                myActivityIndicator.stopAnimating()
            }
            else {
                myActivityIndicator.stopAnimating()
                presentAlert( title  : NSLocalizedString( "Error",                              comment: "Error" ),
                              message: NSLocalizedString( "AlertMessage.UnableToReadLocalFile", comment: "We are unable to read the data from the recipe you selected.  Please try another recipe." ) )
            }

        }
        
    }

    
    
    // MARK: Utility Methods
    
    private func displayRichTextFile() {
        logTrace()
        if let attributedString = try? NSAttributedString( data: fileData, options: rtfAttributedStringOptions, documentAttributes: nil ) {
            myTextView.attributedText = attributedString
        }
        else {
            logTrace( "ERROR!!!  Attributed string conversion failed!" )
        }
        
    }
    
    
    private func presentDocument() {
        logTrace()
        myActivityIndicator.stopAnimating()

        switch navigatorCentral.mimeTypeFor( recipe ) {
            case FileMimeTypes.rtf:     myTextView.isHidden = false
                                        displayRichTextFile()
            
            default:                    myWebView.isHidden = false
                                        myWebView.load( fileData, mimeType: navigatorCentral.mimeTypeFor( recipe ), characterEncodingName: "UTF8", baseURL: URL(string: "http://localhost")! )
        }
            
    }
    
   
}



// MARK: UITextViewDelegate Methods

extension RecipeDisplayViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return false
    }
    
    
}
    


// MARK: WKNavigationDelegate Methods

extension RecipeDisplayViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        return .allow
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        return WKNavigationResponsePolicy.cancel
    }
    
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logVerbose( "error[ %@ ]", error.localizedDescription )
    }
    
    
    private func nameFor(_ navigationAction: WKNavigationAction ) -> String {
        var name = "???"
        
        switch navigationAction.navigationType {
        case .linkActivated:     name = "link activation"
        case .formSubmitted:     name = "request to submit a form"
        case .backForward:       name = "request for the frame’s next or previous item"
        case .reload:            name = "request to reload the webpage"
        case .formResubmitted:   name = "request to resubmit a form"
        case .other:             name = "other"
        default:                 break
        }
        
        return name
    }
    
    
}



