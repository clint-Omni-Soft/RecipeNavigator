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
        static let settings    = "SettingsViewController"
        static let sortOptions = "SortOptionsViewController"
    }
    
    private let appDelegate         = UIApplication.shared.delegate as! AppDelegate
    private var application         = UIApplication.shared
    private let dataSourceCentral   = DataSourceCentral.sharedInstance
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var fileData            : Data!
    private var navigatorCentral    = NavigatorCentral.sharedInstance
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []
    private var showAllSections     = true
    private var showingFavorites    = false
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
        
        if navigatorCentral.didDeleteAddRecipes {
            navigatorCentral.didDeleteAddRecipes = false

            searchEnabled    = false
            showingFavorites = false
        }
        
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
        
        application.isIdleTimerDisabled = false
        logVerbose( "isIdleTimerDisabled[ %@ ]", stringFor( application.isIdleTimerDisabled ) )
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear( animated )
        
        application.isIdleTimerDisabled = UIDevice.current.userInterfaceIdiom == .pad
        logVerbose( "isIdleTimerDisabled[ %@ ]", stringFor( application.isIdleTimerDisabled ) )

        NotificationCenter.default.removeObserver( self )
    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        loadBarButtonItems()
        myTableView.reloadData()
    }


    @objc func recipeArrayReloaded( notification: NSNotification ) {
        logTrace()
        loadBarButtonItems()
        myTableView.reloadData()
    }


    @objc func viewerRecipesArrayReloaded( notification: NSNotification ) {
        logTrace()
        loadBarButtonItems()
        myTableView.reloadData()
    }



    // MARK: Target / Action Methods
    
    @IBAction func favoritesBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        if navigatorCentral.favoriteRecipesArray.count == 0 {
            presentAlert( title  : NSLocalizedString( "AlertTitle.NoFavoriteRecipes",   comment: "You don't have any Favorites yet" ),
                          message: NSLocalizedString( "AlertMessage.NoFavoriteRecipes", comment: "To create a Fovorite, just select a recipe from the list then select 'Add to Favorites' from the popup menu" ) )
            return
        }

        showingFavorites = !showingFavorites
        
        if showingFavorites {
            searchEnabled = false
        }
        
        loadBarButtonItems()
        myTableView.reloadData()
    }

    
    @IBAction func hidePrimaryBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( true )
    }

    
    @IBAction func questionBarButtonTouched(_ sender: UIBarButtonItem ) {
        let message = NSLocalizedString( "InfoText.RecipeList1", comment: "The navigation bar has Caret icons to open and close table sections, a Magnifying Glass to allow you to search recipes by name and, when you favorite recipes, a Book icon to view them.\n\n" )
                    + NSLocalizedString( "InfoText.RecipeList2", comment: "The iPad also has a Gear icon to get to Settings and a (X) icon to close the primary view.  \n\nTouching on a table section header will also open and close that section." )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a Question?" ), message: message )
    }

    
    @IBAction func searchToggleBarButtonTouched(_ sender : UIBarButtonItem ) {
        searchEnabled = !searchEnabled
        
        if searchEnabled {
            showingFavorites = false
        }
        
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
    
    
    @IBAction func settingsBarButtonTouched(_ sender : UIBarButtonItem ) {
        launchSettingsViewController()
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
        
        if !navigatorCentral.recipeArrayOfArrays.isEmpty {
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
    
    
    private func launchSettingsViewController() {
        guard let settingsVC: SettingsViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.settings ) as? SettingsViewController else {
            logTrace( "Error!  Unable to load SettingsViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( settingsVC, animated: true )
    }

    
    private func loadBarButtonItems() {
//        logTrace()
        let arrowImage         = UIImage(named: showAllSections      ? "arrowUp"         : "arrowDown" )
        let favoritesImage     = UIImage(named: showingFavorites     ? "closed-book"     : "open-book" )
        let searchImage        = UIImage(named: myTextField.isHidden ? "magnifyingGlass" : "magnifyingGlassXout" )
        let sortDescriptor     = navigatorCentral.sortDescriptor
        let sortType           = sortDescriptor.0
        var leftBarButtonItems : [UIBarButtonItem] = []
        var rightBarButtonItems: [UIBarButtonItem] = []
        let weHaveData         = navigatorCentral.numberOfRecipesLoaded > 0

        navigationItem.title = showingFavorites ? NSLocalizedString( "Title.Favorites", comment: "Favorites" ) : NSLocalizedString( "Title.Recipes", comment: "Recipes" )

        if UIDevice.current.userInterfaceIdiom == .pad {
            leftBarButtonItems.append( UIBarButtonItem.init( barButtonSystemItem: .close, target: self, action: #selector( hidePrimaryBarButtonTouched(_: ) ) ) )
       }

        if weHaveData && sortType != SortOptions.byFilename {
            leftBarButtonItems.append( UIBarButtonItem.init( image: arrowImage, style: .plain, target: self, action: #selector( showAllBarButtonTouched(_:) ) ) )
        }

        leftBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) ) )

        navigationItem.leftBarButtonItems  = leftBarButtonItems

        if UIDevice.current.userInterfaceIdiom == .pad {
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "gear" ), style: .plain, target: self, action: #selector( settingsBarButtonTouched(_:) ) ) )
        }
        
        if weHaveData {
            if !showingFavorites {
                rightBarButtonItems.append( UIBarButtonItem.init( image: searchImage, style: .plain, target: self, action: #selector( searchToggleBarButtonTouched(_:) ) ) )
            }
            
            if !searchEnabled {
                rightBarButtonItems.append( UIBarButtonItem.init( image: favoritesImage, style: .plain, target: self, action: #selector( favoritesBarButtonTouched(_: ) ) ) )
            }
            
        }

        navigationItem.rightBarButtonItems = rightBarButtonItems
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



// MARK: DataSourceCentralDelegate Methods

extension RecipeListViewController: DataSourceCentralDelegate {
    
    func dataSourceCentral(_ dataSourceCentral: DataSourceCentral, didFetch: Bool, data: Data, from recipe: Recipe ) {
        logVerbose( "[ %@ ]", stringFor( didFetch ) )
       
        if didFetch {
            dataSourceCentral.saveViewerDataFileFrom( recipe, data )
            navigatorCentral .addViewerRecipe(  recipe, self )
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                          message: NSLocalizedString( "AlertMessage.CannotReadFileData", comment: "We cannot the data from this recipe." ) )
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
        searchEnabled    = false
        showingFavorites = false
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
        }

    }


    func navigatorCentralDidUpdateFavoriteRecipes(_ navigatorCentral: NavigatorCentral ) {
        logVerbose( "loaded [ %d ] Favorite Recipes", navigatorCentral.favoriteRecipesArray.count )
        
        if navigatorCentral.favoriteRecipesArray.count == 0 {
            showingFavorites = false
        }
        
        loadBarButtonItems()
        myTableView.reloadData()
    }
    

    func navigatorCentralDidUpdateViewerRecipes(_ navigatorCentral: NavigatorCentral ) {
        logVerbose( "loaded [ %d ] Viewer Recipes", navigatorCentral.viewerRecipeArray.count )
        
        loadBarButtonItems()
        myTableView.reloadData()
    }
    
    
}



// MARK: QuickLookViewControllerDelegate Methods

extension RecipeListViewController: QuickLookViewControllerDelegate {
    
    func quickLookViewControllerWantsToAddRecipeToViewer(_ quickLookViewController: QuickLookViewController, _ data: Data ) {
        logTrace()
        dataSourceCentral.saveViewerDataFileFrom( quickLookViewController.recipe, data )
        navigatorCentral .addViewerRecipe(  quickLookViewController.recipe, self )
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
        if navigatorCentral.numberOfRecipesLoaded == 0 {
            return 0
        }
        
        return ( searchEnabled || showingFavorites ) ? 1 : navigatorCentral.recipeArrayOfArrays.count
    }
    
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return ( searchEnabled || showingFavorites ) ? [] : sectionIndexTitles
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let     recipeListCell = cell as! RecipeListViewControllerCell
        let     recipe: Recipe!
        
        if showingFavorites {
            recipe = navigatorCentral.favoriteRecipesArray[indexPath.row]
        }
        else {
            recipe = searchEnabled ? searchResults[indexPath.row] : navigatorCentral.recipeAt( indexPath )
        }
        
        recipeListCell.initializeWith( recipe )

        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if navigatorCentral.numberOfRecipesLoaded == 0 {
            return 0
        }
        
        if searchEnabled {
            return searchResults.count
        }
        
        if showingFavorites {
            return navigatorCentral.favoriteRecipesArray.count
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return navigatorCentral.dataStoreLocation == .device
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        logVerbose( "[ %d, %d ]", indexPath.section, indexPath.row )
        if editingStyle == .delete {
            navigatorCentral.deleteDeviceRecipeAt( indexPath, self )
        }
        
    }
    
    
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        if deviceAccessControl.byMe {
            promptForActionOnCellAt( indexPath )
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchEnabled || showingFavorites {
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
        var     recipe: Recipe!
        
        if showingFavorites {
            recipe = navigatorCentral.favoriteRecipesArray[indexPath.row]
        }
        else {
            recipe = searchEnabled ? searchResults[indexPath.row] : navigatorCentral.recipeAt( indexPath )
        }

        let addToFavoritesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.AddToFavorites", comment: "Add to Favorites" ), style: .default )
        { ( alertAction ) in
            logTrace( "Add to Favorites Action" )
            self.navigatorCentral.addToFavorites( recipe, self )
        }
        
        let addToViewerAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.AddToViewer", comment: "Add to Viewer" ), style: .default )
        { ( alertAction ) in
            logTrace( "Add to Viewer Action" )
            self.dataSourceCentral.requestViewerDataFor( recipe, self )
        }
        
        let quickLookAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.QuickLook", comment: "Quick Look" ), style: .default )
        { ( alertAction ) in
            logTrace( "Quick Look Action" )
            self.launchQuickLookViewControllerWith( recipe )
        }
        
        let removeFromFavoritesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.RemoveFromFavorites", comment: "Remove from Favorites" ), style: .default )
        { ( alertAction ) in
            logTrace( "Remove from Favorites Action" )
            self.navigatorCentral.removeFromFavorites( recipe, self )
        }
        
        let removeFromViewerAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.RemoveFromViewer", comment: "Remove from Viewer" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Remove from Viewer Action" )
            self.navigatorCentral.removeViewerRecipe( recipe, self )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        if recipe.viewerRecipe == nil {
            alert.addAction( addToViewerAction )
            alert.addAction( quickLookAction )
        }
        else {
            alert.addAction( removeFromViewerAction )
        }
        
        if recipe.favoriteRecipe == nil {
            alert.addAction( addToFavoritesAction )
        }
        else {
            alert.addAction( removeFromFavoritesAction )
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
