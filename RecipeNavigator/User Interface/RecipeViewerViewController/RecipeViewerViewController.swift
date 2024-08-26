//
//  RecipeViewerViewController.swift
//  Recipe Navigator
//
//  Created by Clint Shank on 4/9/24.
//

import UIKit



class RecipeViewerViewController: UIViewController {

    // MARK: Public Variables
    
    @IBOutlet weak var myPageControl       : UIPageControl!
                   var myPageViewController: UIPageViewController?
    @IBOutlet weak var viewPort            : UIView!
 
    
    
    // MARK: Private Variables
    
    private struct StoryboardIds {
        static let recipeDisplay = "RecipeDisplayViewController"
    }
    
    private let appDelegate                 = UIApplication.shared.delegate as! AppDelegate
    private var changingOrientation         = false
    private var pageIndex                   = GlobalConstants.noSelection
    private var recipeDisplayViewControllers: [RecipeDisplayViewController] = []
    private var watingForViewWillAppear     = true
    private let navigatorCentral            = NavigatorCentral.sharedInstance
    private let notificationCenter          = NotificationCenter.default

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title  = NSLocalizedString( "Title.RecipeViewer", comment: "Recipe Viewer" )

        myPageControl.currentPage   = 0
        myPageControl.numberOfPages = 0
        myPageControl.isEnabled     = true
        myPageControl.isHidden      = false
    }
    

    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        watingForViewWillAppear = false

        loadBarButtonItems()
        registerForNotifications()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        logTrace()
        super.viewDidAppear( animated )
 
         setupPageViewController()

        if UIDevice.current.userInterfaceIdiom == .phone {
            setupPageControl()
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        notificationCenter.removeObserver( self )
    }

    
    override func viewWillTransition( to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator ) {
        logTrace()
        super.viewWillTransition( to: size, with: coordinator )
        
        if !watingForViewWillAppear  {
            changingOrientation = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.setupPageViewController()
                self.setupPageControl()
            }
            
        }

    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        setupPageViewController()
        setupPageControl()
    }

    
    @objc func splitViewChanged( notification: NSNotification ) {
        logTrace()
        loadBarButtonItems()
    }
    
    
    @objc func viewerRecipesUpdated( notification: NSNotification ) {
        logTrace()
        myPageViewController!.view.frame = viewPort.frame
        setupPageControl()
    }


    
    
    // MARK: Target/Action Methods
    
    @IBAction func pageControlValueChanged(_ sender: UIPageControl ) {
        logVerbose( "[ %d ]", sender.currentPage )
        pageIndex = sender.currentPage
        setupPageControl()
    }
    
    
    @IBAction func questionBarButtonTouched(_ sender: UIBarButtonItem ) {
        presentAlert( title  : NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a Question?" ),
                      message: NSLocalizedString( "InfoText.Viewer",         comment: "Hit the trash icon to remove this recipe from the viewer.  This will NOT delete the file in your repo." ) )
    }

    
    @IBAction func showPrimaryBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( false )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.loadBarButtonItems()
        }
        
    }
    
    
    @IBAction func trashBarButtonItemTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        let recipe = navigatorCentral.viewerRecipeArray[myPageControl.currentPage]

        promptToRemove( recipe )
    }
    
       

    // MARK: Utility Methods
    
    private func configureForRecipeAt(_ index: Int ) {
        let     recipe = navigatorCentral.viewerRecipeArray[index]

        logVerbose( "[ %d ][ %@ ]", index, recipe.filename! )
        myPageControl.currentPage = index
    }
    
    
    private func loadBarButtonItems() {
        let trashBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: #selector( trashBarButtonItemTouched(_:) ) )
        var rightBarButtonItemArray: [UIBarButtonItem] = []
        
        if recipeDisplayViewControllers.count > 0 {
            rightBarButtonItemArray.append( trashBarButtonItem )
        }
        
        if appDelegate.hidePrimary && UIDevice.current.userInterfaceIdiom == .pad {
            logTrace( "Adding showPrimary button" )
            rightBarButtonItemArray.append( UIBarButtonItem.init(barButtonSystemItem: .organize, target: self, action: #selector( showPrimaryBarButtonItemTouched(_:) ) ) )
        }
        else {
            logTrace()
        }
        
        navigationItem.leftBarButtonItem   = UIBarButtonItem.init( image: UIImage(named: "question" ), style: .plain, target: self, action: #selector( questionBarButtonTouched(_:) ) )
        navigationItem.rightBarButtonItems = rightBarButtonItemArray
    }
    

    private func loadPageAt(_ index: Int ){
        logVerbose( "[ %d ]", index )
        configureForRecipeAt( index )
        myPageViewController!.setViewControllers( [ recipeDisplayViewControllers[index] ], direction: .forward, animated: false, completion: nil )
    }
    
    
    private func loadRecipeDisplayViewControllers() {
        if recipeDisplayViewControllers.count == navigatorCentral.viewerRecipeArray.count && !changingOrientation {
            logTrace( "recipeDisplayViewControllers initialized... do nothing!" )
            return
        }
        
        var     index = 0
        
        if changingOrientation {
            changingOrientation = false
            pageIndex = myPageControl.currentPage
        }
        
        recipeDisplayViewControllers.removeAll()
        
        for recipe in navigatorCentral.viewerRecipeArray {
            guard let recipeDisplayVC : RecipeDisplayViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.recipeDisplay ) as? RecipeDisplayViewController else {
                logTrace( "Error!  Unable to load RecipeDisplayViewController!" )
                return
            }
            
            recipeDisplayVC.pageIndex = index
            recipeDisplayVC.recipe    = recipe
            index += 1
            
            recipeDisplayViewControllers.append( recipeDisplayVC )
        }
        
        self.myPageControl.numberOfPages = self.recipeDisplayViewControllers.count
        logVerbose( "setup [ %d ] displayVCs", recipeDisplayViewControllers.count )
    }
    
    
    private func promptToRemove(_ recipe: Recipe ) {
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.RemoveRecipeFromViewer", comment: "Do you really want to remove this recipe from the viewer?" ), message: nil, preferredStyle: .alert)

        let yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "YES Action" )
            self.navigatorCentral.removeViewerRecipe( recipe, self )
        }
        
        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No!" ), style: .cancel, handler: nil )

        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true, completion: nil )
    }

    
    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( ready(                notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready                      ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( splitViewChanged(     notification: ) ), name: NSNotification.Name( rawValue: Notifications.splitViewChanged           ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( viewerRecipesUpdated( notification: ) ), name: NSNotification.Name( rawValue: Notifications.viewerRecipesArrayReloaded ), object: nil )
    }
    
    
    private func setupPageControl() {
        logTrace()
        loadRecipeDisplayViewControllers()

        myPageControl.isHidden = recipeDisplayViewControllers.isEmpty || recipeDisplayViewControllers.count == 1
        
        if pageIndex != GlobalConstants.noSelection {
            loadPageAt( pageIndex )
            pageIndex = GlobalConstants.noSelection
        }
        else if recipeDisplayViewControllers.count != 0 {
            loadPageAt( 0 )
        }
        
        if recipeDisplayViewControllers.count <= 0 {
            presentAlert( title:   NSLocalizedString( "AlertTitle.NoViewerRecipes",   comment: "No Viewer Recipes" ),
                          message: NSLocalizedString( "AlertMessage.NoViewerRecipes", comment: "Go to Recipes then tap on an item in the list and select Quick Look.  Touch the add button (+) to send one to the recipe viewer." ) )

            setupPageViewController()
        }

        loadBarButtonItems()
    }
    
    
    private func setupPageViewController() {
        logTrace()
        if let pageController = myPageViewController {
            pageController.view.removeFromSuperview()
            pageController.removeFromParent()
            
            myPageViewController = nil
        }
        
        myPageViewController = UIPageViewController( transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil )
        
        myPageViewController!.delegate   = self
        myPageViewController!.dataSource = self
        myPageViewController!.view.frame = viewPort.frame
        
        addChild( myPageViewController! )
        view.addSubview( myPageViewController!.view )

        myPageViewController!.didMove( toParent: self )
    }
    
    
}



// MARK: NavigatorCentralDelegate Methods

extension RecipeViewerViewController: NavigatorCentralDelegate {
    
    func navigatorCentralDidUpdateViewerRecipes(_ navigatorCentral: NavigatorCentral ) {
        logVerbose( "loaded [ %d ] viewerRecipes", navigatorCentral.viewerRecipeArray.count )
        setupPageControl()
    }
    
    
}



// MARK: UIPageViewControllerDataSource

extension RecipeViewerViewController: UIPageViewControllerDataSource {
    
    // If you want to use the PageControl embedded in the PageVieweController, un-comment these methods
    // (Since we can't change the appearance of this control, we use a separate one, so these are instructional but un-necessary )
    
//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return recipeDisplayViewControllers.count
//    }
//    
//    
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
//        return currentPage
//    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        logTrace()
        if let recipeDisplayVC = viewController as? RecipeDisplayViewController {
            let     previousPageIndex = recipeDisplayVC.pageIndex - 1
            let     isValidIndex      = previousPageIndex >= 0
            
            if !isValidIndex {
                recipeDisplayVC.reload()
            }
            
            return !isValidIndex ? nil : recipeDisplayViewControllers[ previousPageIndex ]
        }
        
        return nil
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        logTrace()
        if let recipeDisplayVC = viewController as? RecipeDisplayViewController {
            let     nextPageIndex = recipeDisplayVC.pageIndex + 1
            let     isValidIndex  = nextPageIndex < recipeDisplayViewControllers.count
            
            if !isValidIndex {
                recipeDisplayVC.reload()
            }

            return !isValidIndex ? nil : recipeDisplayViewControllers[ nextPageIndex ]
        }
        
        return nil
    }
    
    
}



// MARK: UIPageViewControllerDelegate Methods

extension RecipeViewerViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        logTrace()
        myPageViewController!.setViewControllers( [myPageViewController!.viewControllers![0]], direction: .forward, animated: true, completion: {done in } )
        myPageViewController!.isDoubleSided = false
        
        return .min
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        logTrace()
        if finished && completed {
            if let currentViewController = pageViewController.viewControllers?.first {
                let recipeDisplayVC = currentViewController as! RecipeDisplayViewController
                let index           = recipeDisplayViewControllers.firstIndex( of: recipeDisplayVC )
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    recipeDisplayVC.reload()
                }

                configureForRecipeAt( index! )
            }
            
        }
        
    }


}


