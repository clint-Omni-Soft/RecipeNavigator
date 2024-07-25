//
//  RecipeListViewControllerSectionCell.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 5/20/24.
//

import UIKit


protocol RecipeListViewControllerSectionCellDelegate: AnyObject {
    func recipeListViewControllerSectionCell(_ recipeListViewControllerSectionCell: RecipeListViewControllerSectionCell, section: Int, isOpen: Bool )
}



class RecipeListViewControllerSectionCell: UITableViewCell {

    
    // MARK: Public Variables
    
    @IBOutlet weak var titleLabel  : UILabel!
    @IBOutlet weak var toggleButton: UIButton!

    
    
    // MARK: Private Variables
    
    private var delegate            : RecipeListViewControllerSectionCellDelegate!
    private let navigatorCentral    = NavigatorCentral.sharedInstance
    private var sectionIsOpen       = false
    private var sectionNumber       = 0

        
    
    // MARK: Cell Lifecycle Methods
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func toggleButtonTouched(_ sender: UIButton) {
        delegate.recipeListViewControllerSectionCell( self, section: sectionNumber, isOpen: sectionIsOpen )
    }

        
        
    // MARK: Public Initializer

    func initializeFor(_ section: Int, with titleText: String, isOpen: Bool, _ delegate: RecipeListViewControllerSectionCellDelegate ) {
        self.delegate = delegate
        
        sectionIsOpen = isOpen
        sectionNumber = section
        
        titleLabel.text      = titleText
        titleLabel.textColor = .black
        
        toggleButton.setTitle( "", for: .normal )
    }

    

}
