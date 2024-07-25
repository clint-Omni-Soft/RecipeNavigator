//
//  KeywordManagerViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 6/21/24.
//


import UIKit



class KeywordManagerViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID = "KeywordManagerViewControllerCell"
    }
    
    private var keywordArray     : [String] = []
    private var keywordsChanged  = false
    private let navigatorCentral = NavigatorCentral.sharedInstance
    private var updatingRecipes  = false
    

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString( "Title.KeywordManager", comment: "Keyword Manager" )
        myActivityIndicator.stopAnimating()
    }
    

    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
        keywordArray = navigatorCentral.recipeKeywords
        
        keywordArray = keywordArray.sorted(by: { (keyword1, keyword2) -> (Bool) in
            return keyword1.uppercased() < keyword2.uppercased()
        } )

        myTableView.reloadData()
    }
    
    

    // MARK: Target/Action Methods
    
    @IBAction func addBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        promptForActionOnKeywordAt( GlobalConstants.noSelection )
    }

    
    @IBAction func backBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        if keywordsChanged {
            navigatorCentral.saveRecipeKeywords( keywordArray )
            promptToUpdateRecipeKeywords()
        }
        else {
            navigationController?.popViewController( animated: true )
        }
        
    }

    
    @IBAction func questionBarButtonTouched(_ sender: UIBarButtonItem ) {
        let     message = NSLocalizedString( "AlertMessage.KeywordManagerInfo", comment: "Use this tool to manage your keywords list.  Touch the (+) sign to add.  Swipe left to delete. Select to modify." )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    

    // MARK: Utility Methods

    private func loadBarButtonItems() {
        logTrace()
        let title                 = "< " + NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
        let addBarButtonItem      = UIBarButtonItem.init( barButtonSystemItem: .add,                         target: self, action: #selector( addBarButtonTouched(_:     ) ) )
        let backBarButtonItem     = UIBarButtonItem.init( title: title,                       style: .plain, target: self, action: #selector( backBarButtonTouched(_:    ) ) )
        let questionBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
        
        navigationItem.leftBarButtonItems = [ backBarButtonItem, questionBarButtonItem ]
        navigationItem.rightBarButtonItem = addBarButtonItem
    }


    private func promptForActionOnKeywordAt(_ index: Int ) {
        let addMode    = ( index == GlobalConstants.noSelection )
        let alertTitle = addMode ? NSLocalizedString( "AlertTitle.AddNewKeyword", comment: "Add New Keyword" ) : NSLocalizedString( "AlertTitle.ModifyKeyword", comment: "Modify Keyword" )
        let alert      = UIAlertController.init(title: alertTitle, message: "", preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            let     keywordNameTextField = alert.textFields![0] as UITextField
            
            if let textString = keywordNameTextField.text {
                if !textString.isEmpty {
                    var keywordIsUnique = true
                    
                    for keyword in self.keywordArray {
                        if keyword.uppercased() == textString.uppercased() {
                            if addMode {
                                keywordIsUnique = false
                                break
                            }
                            else {
                                if keyword == self.keywordArray[index] && keyword != textString {
                                    // the casing (upper/lower) was changed
                                }
                                else {
                                    keywordIsUnique = false
                                    break
                                }
                                
                            }
                            
                        }

                    }

                    if !keywordIsUnique {
                        self.presentAlert( title  : NSLocalizedString( "AlertTitle.DuplicateEntry",         comment: "Duplicate Entry!" ),
                                           message: NSLocalizedString( "AlertMessage.KeywordsMustBeUnique", comment: "Keywords must be unique!" ))
                    }
                    else {
                        if addMode {
                            self.keywordArray.append( textString )
                        }
                        else {
                            self.keywordArray[index] = textString
                        }
                        
                        self.keywordArray = self.keywordArray.sorted(by: { (keyword1, keyword2) -> (Bool) in
                            return keyword1.uppercased() < keyword2.uppercased()
                        } )
                        
                        self.keywordsChanged = true
                        
                        self.myTableView.reloadData()
                    }
                    
                }
                else {
                    logTrace( "We got an empty string" )
                }
                
            }
            else {
                logTrace( "We didn't get anything" )
            }

        }

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addTextField
            { ( textField ) in
                textField.autocapitalizationType = .words
                textField.placeholder            = NSLocalizedString( "LabelText.Keyword", comment: "Keyword" )
                textField.text                   = addMode ? "" : self.keywordArray[index]
            }
        
        alert.addAction( okAction )
        alert.addAction( cancelAction )
        
        present( alert, animated: true )
    }
                                                          
                                                          
    private func promptToUpdateRecipeKeywords() {
        let alert      = UIAlertController.init(title: NSLocalizedString( "AlertTitle.UpdateKeywords", comment: "Would you like to update the keywords in your recipes now?" ), message: "", preferredStyle: .alert )
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Yes Action" )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.myActivityIndicator.startAnimating()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    self.navigatorCentral.updateKeywordsInAllRecipes( self )
                }
                
            }
            
        }

        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "No Action" )
            self.navigationController?.popViewController( animated: true )
        }

        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true )
    }
                                                          
       
    func tellTheUserWeAreDone() {
        let alert = UIAlertController.init(title: NSLocalizedString( "AlertTitle.UpdateComplete", comment: "Update Complete!" ), message: "", preferredStyle: .alert )
       
        let okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            self.navigationController?.popViewController( animated: true )
        }

        alert.addAction( okAction )
        
        present( alert, animated: true )
    }
    

}



// MARK: NavigatorCentralDelegate Methods

extension KeywordManagerViewController: NavigatorCentralDelegate {
    
    func navigatorCentralDidUpdateRecipeKeywords(_ navigatorCentral: NavigatorCentral) {
        logTrace()
        navigatorCentral.reloadData( self )
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes: Bool) {
        logVerbose( "[ %@ ]", stringFor( didReloadRecipes ) )
        
        myActivityIndicator.stopAnimating()
        tellTheUserWeAreDone()
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension KeywordManagerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keywordArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        cell.textLabel?.text = keywordArray[indexPath.row]
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension KeywordManagerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            keywordArray.remove(at: indexPath.row )
            keywordsChanged = true
            
            tableView.reloadData()
        }
        
    }
    

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return keywordArray.count > 0
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false )
        promptForActionOnKeywordAt( indexPath.row )
    }
    
    
}
