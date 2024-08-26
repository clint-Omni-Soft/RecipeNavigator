//
//  RecipeListViewController.swift
//  Recipe Navigator
//
//  Created by Clint Shank on 4/9/24.
//


import UIKit



class RecipeListViewController: UIViewController {

    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var myTextField: UITextField!
    @IBOutlet weak var sortButton : UIButton!
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID              = "RecipeListViewControllerCell"
        static let lastSectionKey      = "ListLastSection"
        static let rowHeight           = CGFloat( 44.0 )
        static let sectionHeaderHeight = CGFloat( 44.0 )
        static let sectionHeaderID     = "RecipeListViewControllerSectionCell"
    }
    
    private struct StoryboardIds {
        static let quickLook   = "QuickLookViewController"
        static let sortOptions = "SortOptionsViewController"
    }
    
    private let appDelegate         = UIApplication.shared.delegate as! AppDelegate
    private var application         = UIApplication.shared
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var navigatorCentral    = NavigatorCentral.sharedInstance
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []
    private var showAllSections     = true
    private var searchEnabled       = false
    private var searchResults       : [Recipe] = []
    private let userDefaults        = UserDefaults.standard

    
    // This is used only when we are sorting on Type
    private var selectedSection: Int {
        get {
            var     section = GlobalConstants.noSelection
            
            if let lastSection = userDefaults.string(forKey: Constants.lastSectionKey ) {
                let thisSection = Int( lastSection ) ?? GlobalConstants.noSelection
                
                section = ( thisSection < myTableView.numberOfSections ) ? thisSection : GlobalConstants.noSelection
            }
            
            return section
        }
        
        set ( section ) {
            userDefaults.set( String( format: "%d", section ), forKey: Constants.lastSectionKey )
        }
        
    }

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.Recipes", comment: "Recipes" )
        
        myTextField.delegate      = self
        myTextField.isHidden      = !searchEnabled
        myTextField.returnKeyType = .done
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        configureSortButtonTitle()
        loadBarButtonItems()
        
        if !navigatorCentral.didOpenDatabase {
            navigatorCentral.openDatabaseWith( self )
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.buildSectionTitleIndex()

                self.myTableView.reloadData()
                
                if self.navigatorCentral.numberOfRecipesLoaded != 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                        self.scrollToLastSelectedItem()
                    }
                    
                }
                
            }
            
        }
        
        registerForNotifications()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            application.isIdleTimerDisabled = false
            logVerbose( "isIdleTimerDisabled[ %@ ]", stringFor( application.isIdleTimerDisabled ) )
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )

        if UIDevice.current.userInterfaceIdiom == .pad {
            application.isIdleTimerDisabled = true
            logVerbose( "isIdleTimerDisabled[ %@ ]", stringFor( application.isIdleTimerDisabled ) )
        }
        
    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        myTableView.reloadData()
    }


    @objc func recipeArrayReloaded( notification: NSNotification ) {
        logTrace()
        myTableView.reloadData()
    }


    @objc func viewerRecipesArrayReloaded( notification: NSNotification ) {
        logTrace()
        myTableView.reloadData()
    }



    // MARK: Target / Action Methods
    
    @IBAction func backBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( true )
    }

    
    @IBAction func searchToggleBarButtonTouched(_ sender : UIBarButtonItem ) {
        searchEnabled = !searchEnabled
        
        logVerbose( "searchEnabled[ %@ ]", stringFor( searchEnabled ) )
        myTextField.isHidden = !searchEnabled
        sortButton .isHidden =  searchEnabled
        
        if searchEnabled {
            myTextField.text = ""
            myTextField.becomeFirstResponder()
        }
        else {
            myTextField.resignFirstResponder()
        }
        
        loadBarButtonItems()
        myTableView.reloadData()
    }
    
    
    @IBAction func showAllBarButtonTouched(_ sender : UIBarButtonItem ) {
        logVerbose( "[ %@ ]", stringFor( showAllSections ) )
        selectedSection = GlobalConstants.noSelection
        showAllSections = !showAllSections
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
        }

    }
    
    
    @IBAction func sortButtonTouched(_ sender: Any) {
        logTrace()
        presentSortOptions()
    }
    
    
    
    // MARK: Utility Methods
    
    private func buildSectionTitleIndex() {
        var     currentTitle = ""
        var     index        = 0
        
        sectionIndexTitles .removeAll()
        sectionTitleIndexes.removeAll()
        
        let sortDescriptor = navigatorCentral.sortDescriptor
        let sortType       = sortDescriptor.0
        
        if sortType == SortOptions.byKeywords {
//            logTrace( "Sort by type is NOT by name so don't populate the section index" )
            return
        }
        
        let recipeArray = navigatorCentral.recipeArrayOfArrays[0]   // When sorting by name or path, we know that there will always only be one array
        
        for recipe in recipeArray {
            let     nameStartsWith: String = ( recipe.filename?.prefix(1).uppercased() )!
            
            if nameStartsWith != currentTitle {
                currentTitle = nameStartsWith
                sectionTitleIndexes.append( index )
                sectionIndexTitles .append( nameStartsWith )
            }
            
            index += 1
        }
        
    }
    
    
    private func configureSortButtonTitle() {
//        logTrace()
        let sortDescriptor = navigatorCentral.sortDescriptor
        let sortAscending  = sortDescriptor.1
        let sortType       = sortDescriptor.0
        let sortTypeName   = navigatorCentral.nameForSortType( sortType )
        let title          = NSLocalizedString( "LabelText.SortedOn", comment: "Sorted on: " ) + sortTypeName + ( sortAscending ? GlobalConstants.sortAscending : GlobalConstants.sortDescending )
        
        sortButton.setTitle( title, for: .normal )
    }
    
    
    private func lastAccessedRecipe() -> IndexPath {
        guard let lastRecipeGuid = userDefaults.object(forKey: UserDefaultKeys.lastAccessedRecipesGuid ) as? String else {
            return GlobalIndexPaths.noSelection
        }
        
        for section in 0...navigatorCentral.recipeArrayOfArrays.count - 1 {
            let sectionArray = navigatorCentral.recipeArrayOfArrays[section]
            
            if !sectionArray.isEmpty {
                for row in 0...sectionArray.count - 1 {
                    let pin = sectionArray[row]
                    
                    if pin.guid == lastRecipeGuid {
                        return IndexPath(row: row, section: section )
                    }
                    
                }
                
            }
            
        }
        
        return GlobalIndexPaths.noSelection
    }
    
    
    private func loadBarButtonItems() {
//        logTrace()
        var leftBarButtonItems: [UIBarButtonItem] = []
        let searchImage       = UIImage(named: myTextField.isHidden ? "magnifyingGlass" : "hamburger" )
        let sortDescriptor    = navigatorCentral.sortDescriptor
        let sortType          = sortDescriptor.0
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let title             = "< " + NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
            let backBarButtonItem = UIBarButtonItem.init( title: title, style: .plain, target: self, action: #selector( backBarButtonTouched(_: ) ) )

            leftBarButtonItems.append( backBarButtonItem )
        }

        if sortType != SortOptions.byFilename {
            let arrowImage        = UIImage(named: showAllSections ? "arrowUp" : "arrowDown" )
            let leftBarButtonItem = UIBarButtonItem.init( image: arrowImage, style: .plain, target: self, action: #selector( showAllBarButtonTouched(_:) ) )
            
            leftBarButtonItems.append( leftBarButtonItem )
        }
        

        navigationItem.rightBarButtonItem = UIBarButtonItem.init( image: searchImage, style: .plain, target: self, action: #selector( searchToggleBarButtonTouched(_:) ) )
        navigationItem.leftBarButtonItems = leftBarButtonItems
    }
    
    
    private func presentSortOptions() {
        guard let sortOptionsVC: SortOptionsViewController = iPhoneViewControllerWithStoryboardId(storyboardId: StoryboardIds.sortOptions ) as? SortOptionsViewController else {
            logTrace( "ERROR: Could NOT load SortOptionsViewController!" )
            return
        }
        
        logTrace()
        sortOptionsVC.delegate = self
        
        sortOptionsVC.modalPresentationStyle = .popover
        sortOptionsVC.preferredContentSize   = CGSize(width: myTableView.frame.width, height: 300 )

        sortOptionsVC.popoverPresentationController!.delegate                 = self
        sortOptionsVC.popoverPresentationController?.permittedArrowDirections = .any
        sortOptionsVC.popoverPresentationController?.sourceRect               = sortButton.frame
        sortOptionsVC.popoverPresentationController?.sourceView               = sortButton
        
        present( sortOptionsVC, animated: true, completion: nil )
    }
    
    
    private func registerForNotifications() {
        logTrace()
        NotificationCenter.default.addObserver( self, selector: #selector( self.ready(                      notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready                      ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( self.recipeArrayReloaded(        notification: ) ), name: NSNotification.Name( rawValue: Notifications.recipeArrayReloaded        ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( self.viewerRecipesArrayReloaded( notification: ) ), name: NSNotification.Name( rawValue: Notifications.viewerRecipesArrayReloaded ), object: nil )
    }
    
    
    private func scrollToLastSelectedItem() {
        logTrace()
        let indexPath = lastAccessedRecipe()
        let sortType  = navigatorCentral.sortDescriptor.0
        
        if indexPath != GlobalIndexPaths.noSelection {
            if myTableView.numberOfRows(inSection: indexPath.section ) == 0 {
//                logVerbose( "Do nothing! The selected row is in a section[ %d ] that is closed!", indexPath.section )
                return
            }
            
            if sortType != SortOptions.byKeywords {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            else if showAllSections {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            else if indexPath.section == selectedSection {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            
//            logVerbose( "showAllSections[ %@ ]  section[ %d / %d ]", stringFor( showAllSections ), indexPath.section, selectedSection )
        }
        
    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension RecipeListViewController: NavigatorCentralDelegate {
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if didOpenDatabase {
            navigatorCentral.fetchRecipesWith( self )
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error",                comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes: Bool ) {
        logVerbose( "loaded [ %d ] recipes", navigatorCentral.numberOfRecipesLoaded )
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
        }

    }


    func navigatorCentralDidUpdateViewerRecipes(_ navigatorCentral: NavigatorCentral ) {
        logVerbose( "loaded [ %d ] viewerRecipes", navigatorCentral.viewerRecipeArray.count )
        myTableView.reloadData()
    }
    

}



// MARK: QuickLookViewControllerDelegate Methods

extension RecipeListViewController: QuickLookViewControllerDelegate {
    
    func quickLookViewControllerWantsToAddRecipeToViewer(_ quickLookViewController: QuickLookViewController, _ data: Data ) {
        logTrace()
        navigatorCentral.addViewerRecipe( quickLookViewController.recipe, self )
        navigatorCentral.saveFileDataFrom( quickLookViewController.recipe, data )
    }
    
    
}



// MARK: RecipeViewControllerSectionCellDelegate Methods

extension RecipeListViewController: RecipeListViewControllerSectionCellDelegate {
    
    func recipeListViewControllerSectionCell(_ recipeListViewControllerSectionCell: RecipeListViewControllerSectionCell, section: Int, isOpen: Bool) {
//        logVerbose( "section[ %d ]  isOpen[ %@ ]", section, stringFor( isOpen ) )
        selectedSection = ( selectedSection == section ) ? GlobalConstants.noSelection : section
        showAllSections = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.buildSectionTitleIndex()
            self.configureSortButtonTitle()
            self.loadBarButtonItems()
            
            self.myTableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.scrollToLastSelectedItem()
            }

        }

    }
    
    
}



// MARK: SortOptionsViewControllerDelegate Methods

extension RecipeListViewController: SortOptionsViewControllerDelegate {
    
    func sortOptionsViewController(_ sortOptionsViewController: SortOptionsViewController, didSelectNewSortOption: Bool) {
        logTrace()
        let sortType = navigatorCentral.sortDescriptor.0

        if sortType == SortOptions.byKeywords {
            showAllSections = true
            selectedSection = GlobalConstants.noSelection
        }
        
        configureSortButtonTitle()
        navigatorCentral.fetchRecipesWith( self )
    }
    
    
}



// MARK: - UIPopoverPresentationControllerDelegate method

extension RecipeListViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: - UITableViewDataSource Methods

extension RecipeListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchEnabled ? 1 : ( navigatorCentral.numberOfRecipesLoaded == 0 ) ? 0 : navigatorCentral.recipeArrayOfArrays.count
    }
    
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let     recipeListCell = cell as! RecipeListViewControllerCell
        let     recipe         = searchEnabled ? searchResults[indexPath.row] : navigatorCentral.recipeAt( indexPath )
        
        recipeListCell.initializeWith( recipe )

        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchEnabled {
            return searchResults.count
        }
        
        if navigatorCentral.numberOfRecipesLoaded == 0 {
            return 0
        }
        
        var numberOfRows = 0
        let sortType     = navigatorCentral.sortDescriptor.0

        if sortType == SortOptions.byFilename {
            numberOfRows = navigatorCentral.recipeArrayOfArrays[section].count
        }
        else {
            if showAllSections || ( selectedSection == section ) {
                numberOfRows = navigatorCentral.recipeArrayOfArrays[section].count
            }

        }
        
        return  numberOfRows
    }
    
    
}



    // MARK: UITableViewDelegate Methods

extension RecipeListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        if deviceAccessControl.byMe {
            promptForActionOnCellAt( indexPath )
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchEnabled {
            return CGFloat.leastNormalMagnitude
        }
        
        var isHidden = true
        let sortType = navigatorCentral.sortDescriptor.0

        if sortType != SortOptions.byFilename {
            if navigatorCentral.recipeArrayOfArrays.count > 1 {
                isHidden = navigatorCentral.recipeArrayOfArrays[section].count == 0
            }
            
        }

        return isHidden ? CGFloat.leastNormalMagnitude : Constants.sectionHeaderHeight
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight
    }
    
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let     row = sectionTitleIndexes[index]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle , animated: true )
        }
        
        return row
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchEnabled ? "" : navigatorCentral.sectionTitleArray[ section ]
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchEnabled {
            return UITableViewCell.init()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.sectionHeaderID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let isOpen     = selectedSection == section
        let headerCell = cell as! RecipeListViewControllerSectionCell
        
        headerCell.initializeFor( section, with: navigatorCentral.sectionTitleArray[ section ], isOpen: isOpen, self )

        return headerCell
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods

    private func launchQuickLookViewControllerWith(_ recipe: Recipe ) {
        guard let quickLookVC: QuickLookViewController = iPhoneViewControllerWithStoryboardId(storyboardId: StoryboardIds.quickLook ) as? QuickLookViewController else {
            logTrace( "ERROR: Could NOT load QuickLookViewController!" )
            return
        }
        
        logTrace()
        quickLookVC.delegate = self
        quickLookVC.recipe   = recipe
        
        navigationController?.pushViewController( quickLookVC, animated: true )
    }
    
    
    private func promptForActionOnCellAt(_ indexPath: IndexPath ) {
        logTrace()
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ActionForRecipe", comment: "What would you like to do with this recipe?" ), message: nil, preferredStyle: .alert)
        let     recipe = searchEnabled ? searchResults[indexPath.row] : navigatorCentral.recipeAt( indexPath )

        let quickLookAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.QuickLook", comment: "Quick Look" ), style: .default )
        { ( alertAction ) in
            logTrace( "Quick Look Action" )
            self.launchQuickLookViewControllerWith( recipe )
        }
        
        let removeFromViewerAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.RemoveFromViewer", comment: "Remove from Viewer" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Remove from Viewer Action" )
            self.navigatorCentral.removeViewerRecipe( recipe, self )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        if navigatorCentral.viewerRecipeArray.contains( recipe ) {
            alert.addAction( removeFromViewerAction )
        }
        else {
            alert.addAction( quickLookAction )
        }
        
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }


}



// MARK: UITextFieldDelegate Methods

extension RecipeListViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField ) {
        guard let searchText = textField.text else {
            return
        }
        
        if searchText.isEmpty {
            searchResults = []
            myTableView.reloadData()
        }
        else if searchText.count > 1 {
            scanFor( searchText )
        }
        
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if ( string == "\n" ) {
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    
    
    // MARK: UITextFieldDelegate Utility Methods
    
    private func scanFor(_ searchString: String ) {
        logVerbose( "[ %@ ]", searchString )
        searchResults = navigatorCentral.recipesWith( searchString.components(separatedBy: " " ) )

        let sortedRecipeArray = searchResults.sorted( by:
                    { (recipe1, recipe2) -> Bool in
                        recipe1.filename! < recipe2.filename!
                    } )

        searchResults = []
        
        // Discard duplicates
        for sortedRecipe in sortedRecipeArray {
            var saveIt = true
            
            for searchRecipe in searchResults {
                if searchRecipe.guid == sortedRecipe.guid {
                    saveIt = false
                    break
                }
                
            }
            
            if saveIt {
                searchResults.append( sortedRecipe )
            }
                
        }
            
        myTableView.reloadData()
    }
    
    
}
