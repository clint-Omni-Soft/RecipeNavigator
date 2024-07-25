//
//  RecipeListViewControllerCell.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 5/20/24.
//


import UIKit



class RecipeListViewControllerCell: UITableViewCell {
    
    
    // MARK: Private Variables
    
    private let navigatorCentral = NavigatorCentral.sharedInstance

    
    
    // MARK: UITableViewCell Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( false, animated: animated)
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith(_ recipe: Recipe ) {
        textLabel?.text = recipe.filename
        accessoryType   = navigatorCentral.accessoryTypeFor( recipe )
    }

    
    
    // MARK: Utility Methods
    
}
