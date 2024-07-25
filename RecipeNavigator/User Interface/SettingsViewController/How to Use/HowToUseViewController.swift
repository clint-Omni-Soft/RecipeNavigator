//
//  HowToUseViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 4/30/24.
//

import UIKit



class HowToUseViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myTextView : UITextView!
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID = "HowToUseViewControllerCell"
    }
    
    private var currentSelection = GlobalConstants.noSelection
    
    private let infoMessageArray = [ NSLocalizedString( "InfoText.FirstThingsFirst",     comment: "Before you start using this app, you should consider where we can find your recipes (see Recipe Repository for details)." ),
                                     NSLocalizedString( "InfoText.KeywordManager",       comment: "This is where you manage (add/modify/delete) the keywords that you want to use to search and organize the titles of your recipes." ),
                                     NSLocalizedString( "InfoText.RecipeRepository",     comment: "Use this utility to specify where your recipes are located.  They can be on either (a) on this device, (b) in the iCloud or (c) on a Network Accessible Storage (NAS) unit.\n\nThis app ONLY recognizes recipes can be in the following file formats: JPG, JPEG, HTM, HTML, PDF, PNG or TXT." ),
                                     NSLocalizedString( "InfoText.ScanRecipeRepository", comment: "Once you have specified where your recipes are located (your repository), you can this utility to scan the designated location and create a database on this device for easy access.\n\nThe time it takes to access and display a recipe will depend on where you store your recipe files.  We do NOT copy your recipes files to your device." ) ]

    private let tableDataArray   = [ NSLocalizedString( "Title.FirstThingFirst",      comment: "First things first"     ),
                                     NSLocalizedString( "Title.KeywordManager",       comment: "Keyword Manager"        ),
                                     NSLocalizedString( "Title.RecipeRepository",     comment: "Recipe Repository"      ),
                                     NSLocalizedString( "Title.ScanRecipeRepository", comment: "Scan Recipe Repository" ) ]

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.HowToUse", comment: "How to Use"   )
        configureBackBarButtonItem()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        myTextView.backgroundColor = .white
        myTextView.text = ""
        
        myTableView.reloadData()
    }
    

}



// MARK: UITableViewDataSource Methods

extension HowToUseViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableDataArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        cell.textLabel?.text = tableDataArray[indexPath.row]
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension HowToUseViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if currentSelection != GlobalConstants.noSelection {
            tableView.deselectRow( at: IndexPath.init( item: currentSelection, section: 0 ) , animated: true )

            if indexPath.row != currentSelection {
                tableView.deselectRow( at: indexPath, animated: false )
            }
            
            currentSelection = GlobalConstants.noSelection

            myTextView.backgroundColor = .white
            myTextView.text  = ""
        }
        else {
            myTextView.backgroundColor = GlobalConstants.groupedTableViewBackgroundColor

            currentSelection = indexPath.row
            loadInfoBox()
        }
        
    }



    // MARK: UITableViewDelegate Utility Methods

    private func loadInfoBox() {
        let     infoMessage = infoMessageArray[ currentSelection ]
        let     title       = tableDataArray[   currentSelection ]
        let     infoText    = title + "\n\n" + infoMessage

        myTextView.text = infoText
    }
    
    
}

