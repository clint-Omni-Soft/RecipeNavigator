//
//  NavigatorCentral.swift
//  Recipe Navigator
//
//  Created by Clint Shank on 4/8/24.
//

import UIKit
import CoreData


protocol NavigatorCentralDelegate: AnyObject {
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddRecipes      : Bool, count: Int )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteAllRecipes: Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetch imageNames: [String] )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetchImage      : Bool, filename: String, image: UIImage )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didImportCsvRecords: Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase    : Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes   : Bool )
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didSaveImageData   : Bool )
    func navigatorCentralDidUpdateRecipeKeywords(_ navigatorCentral: NavigatorCentral )
    func navigatorCentralDidUpdateViewerRecipes(_  navigatorCentral: NavigatorCentral )

}

// Now we provide a default implementation which makes them all optional
extension NavigatorCentralDelegate {
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didAddRecipes      : Bool, count: Int ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didDeleteAllRecipes: Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetch imageNames: [String] ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didFetchImage      : Bool, filename: String, image: UIImage ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didImportCsvRecords: Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didOpenDatabase    : Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didReloadRecipes   : Bool ) {}
    func navigatorCentral(_ navigatorCentral: NavigatorCentral, didSaveImageData   : Bool ) {}
    func navigatorCentralDidUpdateRecipeKeywords(_ navigatorCentral: NavigatorCentral ) {}
    func navigatorCentralDidUpdateViewerRecipes(_  navigatorCentral: NavigatorCentral ) {}
}



class NavigatorCentral: NSObject {
    
    
    // MARK: Public Variables & Definitions
    
    weak var delegate: NavigatorCentralDelegate?
    
    var didOpenDatabase                 = false
    var externalDeviceLastUpdatedBy     = ""
    var missingDbFiles: [String]        = []
    var numberOfRecipesLoaded           = 0
    var pleaseWaiting                   = false
    var recipeArrayOfArrays: [[Recipe]] = []
    var recipeArrayReloaded             = false
    var recipeKeywords: [String]        = []
    var recipeKeywordsObject            : RecipeKeywords!
    var resigningActive                 = false
    var restarting                      = true
    var sectionTitleArray: [String]     = []
    var stayOffline                     = false
    let userDefaults                    = UserDefaults.standard
    var viewerRecipeArray: [Recipe]     = []
    
    var dataSourceDescriptor: NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = userDefaults.string( forKey: UserDefaultKeys.dataSourceDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    descriptor.host         = components[0]
                    descriptor.netbiosName  = components[1]
                    descriptor.group        = components[2]
                    descriptor.userName     = components[3]
                    descriptor.password     = components[4]
                    descriptor.share        = components[5]
                    descriptor.path         = components[6]
                }
                
            }
            
            return descriptor
        }
        
        set ( newDescriptor ){
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               newDescriptor.host,      newDescriptor.netbiosName, newDescriptor.group,
                                               newDescriptor.userName,  newDescriptor.password,
                                               newDescriptor.share,     newDescriptor.path )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.dataSourceDescriptor )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataSourceLocation: DataLocation {
        get {
            if dataSourceLocationBacking != .notAssigned {
                return dataSourceLocationBacking
            }
            
            if let locationString = userDefaults.string( forKey: UserDefaultKeys.dataSourceLocation ) {
                return dataLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( location ) {
            var     oldLocation = DataLocationName.device
            var     newLocation = ""
            
            if let savedLocation = userDefaults.string( forKey: UserDefaultKeys.dataSourceLocation ) {
                oldLocation = savedLocation
            }
            
            switch location {
            case .device:       newLocation = DataLocationName.device
            case .iCloud:       newLocation = DataLocationName.iCloud
            case .nas:          newLocation = DataLocationName.nas
            case .shareCloud:   newLocation = DataLocationName.shareCloud
            case .shareNas:     newLocation = DataLocationName.shareNas
            default:            newLocation = DataLocationName.notAssigned
            }
            
            logVerbose( "[ %@ ] -> [ %@ ]", oldLocation, newLocation )
            
            dataSourceLocationBacking = location
            
            userDefaults.set( newLocation, forKey: UserDefaultKeys.dataSourceLocation )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataStoreLocation: DataLocation {
        get {
            if dataStoreLocationBacking != .notAssigned {
                return dataStoreLocationBacking
            }
            
            if let locationString = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                return dataLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( location ) {
            var     oldLocation = DataLocationName.device
            var     newLocation = ""
            
            if let lastLocation = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                oldLocation = lastLocation
            }
            
            switch location {
            case .device:       newLocation = DataLocationName.device
            case .iCloud:       newLocation = DataLocationName.iCloud
            case .nas:          newLocation = DataLocationName.nas
            case .shareCloud:   newLocation = DataLocationName.shareCloud
            case .shareNas:     newLocation = DataLocationName.shareNas
            default:            newLocation = DataLocationName.device
            }
            
            logVerbose( "[ %@ ] -> [ %@ ]", oldLocation, newLocation )
            
            dataStoreLocationBacking = location
            
            userDefaults.set( newLocation, forKey: UserDefaultKeys.dataStoreLocation )
            userDefaults.synchronize()
        }
        
    }
    
    
    var dataStoreDescriptor: NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = userDefaults.string( forKey: UserDefaultKeys.dataStoreDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    descriptor.host         = components[0]
                    descriptor.netbiosName  = components[1]
                    descriptor.group        = components[2]
                    descriptor.userName     = components[3]
                    descriptor.password     = components[4]
                    descriptor.share        = components[5]
                    descriptor.path         = components[6]
                }
                
            }
            
            return descriptor
        }
        
        set ( newDescriptor ){
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               newDescriptor.host,      newDescriptor.netbiosName, newDescriptor.group,
                                               newDescriptor.userName,  newDescriptor.password,
                                               newDescriptor.share,     newDescriptor.path )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.dataStoreDescriptor )
            userDefaults.synchronize()
        }
        
    }
    
    
    var deviceName: String {
        get {
            var     nameOfDevice = ""
            
            if let deviceNameString = userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
                if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                    nameOfDevice = deviceNameString
                }
                
            }
            
            return nameOfDevice
        }
        
        
        set( newName ) {
            self.userDefaults.set( newName, forKey: UserDefaultKeys.deviceName )
            self.userDefaults.synchronize()
        }
        
    }
    
    
    var sortDescriptor: (String, Bool) {
        get {
            if let descriptorString = userDefaults.string(forKey: UserDefaultKeys.currentSortOption ) {
                let sortComponents = descriptorString.components(separatedBy: GlobalConstants.separatorForSorts )
                
                if sortComponents.count == 2 {
                    let     option    = sortComponents[0]
                    let     direction = ( sortComponents[1] == GlobalConstants.sortAscendingFlag )
                    
                    return ( option, direction )
                }
                
            }
            
            return ( SortOptions.byFilename, true )
        }
        
        set ( sortTuple ) {
            let descriptorString = sortTuple.0 + GlobalConstants.separatorForSorts + ( sortTuple.1 ? GlobalConstants.sortAscendingFlag : GlobalConstants.sortDescendingFlag )
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.currentSortOption )
            userDefaults.synchronize()
        }
        
    }
    
    
    
    // MARK: Private Variables & Definitions
    
    private var databaseUpdated             = false
    private var dataSourceLocationBacking   = DataLocation.notAssigned
    private var dataStoreLocationBacking    = DataLocation.notAssigned
    private var updateTimer                 : Timer!
    private var viewerRecipesObject         : ViewerRecipes!
    
    private let sampleRecipeArray = [ "Halibut with Fennel F&W 2001.JPG",
                                      "How to Make a Sourdough Starter from Scratch.txt",
                                      "Mushroom Gravy from Scratch.rtf",
                                      "Pumpkin Mousse W-T Crunch.pdf" ,
                                      "TexasRed.htm" ]
    
    
    
    // MARK: Definitions shared with CommonExtensions
    
    struct Constants {
        static let databaseModel  = "NavigatorCentral"
        static let primedFlag     = "Primed"
        static let recipeKeywords = "Apple,Asparagus,Bacon,Beans,Beef,Bread,Buns,Burger,Chicken,Chili,Chop,Corn,Couscous,Croissant,Curry,Filet,Fish,Fried,Drink,Gravy,Halibut,Ham,Indian,Lamb,Lobster,Mexican,Mousse,Mushroom,Pasta,Peach,Pizza,Pork,Potato,Pumpkin,Rib,Roast,Salsa,Saltimbocca,Salmon,Shrimp,Sourdough,Steak,Stuffing,Swordfish,Tuna,Tenderloin,Tomato,Turkey,Veal,Zucchini"
        static let timerDuration  = Double( 300 )
    }
    
    struct OfflineImageRequestCommands {
        static let delete = 1
        static let fetch  = 2
        static let save   = 3
    }
    
    var backgroundTaskID        : UIBackgroundTaskIdentifier = .invalid
    var cloudCentral            = CloudCentral.sharedInstance
    let deviceAccessControl     = DeviceAccessControl.sharedInstance
    let fileManager             = FileManager.default
    var imageRequestQueue       : [(String, NavigatorCentralDelegate)] = []      // This queue is used to serialize transactions while online (both iCloud and NAS)
    var managedObjectContext    : NSManagedObjectContext!
    var nasCentral              = NASCentral.sharedInstance
    var notificationCenter      = NotificationCenter.default
    var offlineImageRequestQueue: [ImageRequest] = []                             // This queue is used to flush offline NAS image transactions to disk after we reconnect
    var openInProgress          = false
    var persistentContainer     : NSPersistentContainer!
    
    var updatedOffline: Bool {
        get {
            return flagIsPresentInUserDefaults( UserDefaultKeys.updatedOffline )
        }
        
        set ( setFlag ) {
            if setFlag {
                setFlagInUserDefaults( UserDefaultKeys.updatedOffline )
            }
            else {
                removeFlagFromUserDefaults( UserDefaultKeys.updatedOffline )
            }
            
        }
        
    }
    
    
    
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = NavigatorCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: AppDelegate Methods
    
    func enteringBackground() {
        logTrace()
        resigningActive = true
        
        stopTimer()
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringBackground ), object: self )
    }
    
    
    func enteringForeground() {
        logTrace()
        resigningActive = false
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: self )
        canSeeExternalStorage()
    }
    
    
    
    // MARK: Database Access Methods (Public)
    
    func openDatabaseWith(_ delegate: NavigatorCentralDelegate ) {
        
        if openInProgress {
            logTrace( "openInProgress ... do nothing" )
            return
        }
        
        if deviceAccessControl.updating {
            logTrace( "transferInProgress ... do nothing" )
            return
        }
        
        logTrace()
        self.delegate        = delegate
        didOpenDatabase      = false
        openInProgress       = true
        recipeArrayReloaded  = false
        persistentContainer  = NSPersistentContainer( name: Constants.databaseModel )
        
        persistentContainer.loadPersistentStores( completionHandler:
                                                    { ( storeDescription, error ) in
            
            if let error = error as NSError? {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else {
                self.loadCoreData()
                
                if !self.didOpenDatabase  {     // This is just in case I screw up and don't properly version the data model
                    self.deleteDatabase()       // TODO: Figure out if this is the right thing to do
                    self.loadCoreData()
                }
                
                self.loadBasicData()
                
                self.startTimer()
            }
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ), execute:  {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                
                self.openInProgress = false
                delegate.navigatorCentral( self, didOpenDatabase: self.didOpenDatabase )
                
                if self.updatedOffline && !self.stayOffline {
                    self.persistentContainer.viewContext.perform {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
                
            } )
            
        } )
        
    }
    
    
    
    // MARK: Entity Access/Modifier Methods (Public)
    
    func addRecipesFrom(_ smbFileArray: [SMBFile], _ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            delegate.navigatorCentral( self, didAddRecipes: false, count: 0 )
            return
        }
        
        //        logTrace()
        persistentContainer.viewContext.perform {
            for smbFile in smbFileArray {
                let recipe  = NSEntityDescription.insertNewObject( forEntityName: EntityNames.recipe, into: self.managedObjectContext ) as! Recipe
                let pathUrl = URL(fileURLWithPath: smbFile.path, isDirectory: false )
                
                recipe.filename     = smbFile.name
                recipe.guid         = UUID().uuidString
                recipe.keywords     = self.keywordsIn( smbFile.name )
                recipe.relativePath = pathUrl.deletingLastPathComponent().path
                
                self.saveContext()
            }
            
            delegate.navigatorCentral( self, didAddRecipes: true, count: smbFileArray.count )
        }
        
    }
    
    
    func deleteAllRecipes(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            delegate.navigatorCentral( self, didDeleteAllRecipes: false )
            return
        }
        
        //        logTrace()
        persistentContainer.viewContext.perform {
            let flatArray = self.flatRecipeArray()

            for recipe in flatArray {
                self.managedObjectContext.delete( recipe )
            }
            
            self.saveContext()
            
            delegate.navigatorCentral( self, didDeleteAllRecipes: true )
        }
        
    }
    
    
    func fetchFromDevice(_ recipe: Recipe ) -> Data {
        var fetchedData = Data.init()
        
        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let fileUrl = url.appendingPathComponent( recipe.filename! )
            
            do {
                try fetchedData = Data(contentsOf: fileUrl )
            }
            
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to read [ %@ ] ... Error[ %@ ]", recipe.filename!, error.localizedDescription )
            }
            
        }

        return fetchedData
    }
    

    func fetchRecipesWith(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        //        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func mimeTypeFor(_ recipe: Recipe ) -> String {
        var mimeType = "text/plain"
        
        switch extensionFrom( recipe.filename! ) {
        case SupportedFilenameExtensions.jpg:   mimeType = FileMimeTypes.jpg
        case SupportedFilenameExtensions.jpeg:  mimeType = FileMimeTypes.jpg
        case SupportedFilenameExtensions.htm:   mimeType = FileMimeTypes.html
        case SupportedFilenameExtensions.html:  mimeType = FileMimeTypes.html
        case SupportedFilenameExtensions.pdf:   mimeType = FileMimeTypes.pdf
        case SupportedFilenameExtensions.png:   mimeType = FileMimeTypes.png
        case SupportedFilenameExtensions.rtf:   mimeType = FileMimeTypes.rtf
        case SupportedFilenameExtensions.txt:   mimeType = FileMimeTypes.txt
//        case SupportedFilenameExtensions.doc:   mimeType = FileMimeTypes.doc
//        case SupportedFilenameExtensions.docx:  mimeType = FileMimeTypes.docx
        default:                                break
        }
        
        return mimeType
    }
    
    
    func recipeAt(_ indexPath: IndexPath ) -> Recipe {
        let sectionArray = recipeArrayOfArrays[indexPath.section]
        
        return sectionArray[indexPath.row]
    }
    
    
    func reloadData(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func reloadRecipesFrom(_ fileDescriptorArray: [FileDescriptor], _ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        self.delegate = delegate
        
        var objectsCreated = 0
        var objectsDeleted = 0
        
        persistentContainer.viewContext.perform {
            let flatArray = self.flatRecipeArray()
            
            for recipe in flatArray {
                self.managedObjectContext.delete( recipe )
                objectsDeleted += 1
            }
            
            self.saveContext()
            
            for fileDescriptor in fileDescriptorArray {
                let recipe = NSEntityDescription.insertNewObject( forEntityName: EntityNames.recipe, into: self.managedObjectContext ) as! Recipe
                
                recipe.filename     = fileDescriptor.name
                recipe.guid         = UUID().uuidString
                recipe.keywords     = self.keywordsIn( fileDescriptor.name )
                recipe.relativePath = fileDescriptor.path
                
                objectsCreated += 1
            }
            
            self.saveContext()
            logVerbose( "Deleted [ %d ] and created [ %d ] recipe objects", objectsDeleted, objectsCreated )
            
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    

    
    // MARK: Keyword Methods (Public)
    
    func saveRecipeKeywords(_ keywordArray: [String] ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
//        logTrace()
        var keywordString = ""
        
        for keyword in keywordArray {
            if !keywordString.isEmpty {
                keywordString += GlobalConstants.separatorForRecipeKeywordString
            }
            
            keywordString += keyword
        }
        
        recipeKeywords = keywordArray
        logVerbose( "keywords[ %@ ]", keywordString )

        persistentContainer.viewContext.perform {
            self.recipeKeywordsObject.keywords = keywordString
            self.saveContext()
        }
        
    }
    
    
    func updateKeywordsInAllRecipes(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        persistentContainer.viewContext.perform {
            let flatArray = self.flatRecipeArray()
            
            for recipe in flatArray {
                let newKeywordString = self.keywordsIn( recipe.filename! )
                let oldKeywordString = recipe.keywords ?? ""
                
                if newKeywordString != oldKeywordString {
                    recipe.keywords = newKeywordString
                    logVerbose( "[ %@ ] [ %@ ] -> [ %@ ]", recipe.filename!, oldKeywordString, newKeywordString )
                    self.saveContext()
                }
                
            }
            
            delegate.navigatorCentralDidUpdateRecipeKeywords( self )
        }
        
    }
    
      

    // MARK: Viewer Methods
    
    func addViewerRecipe(_ recipe: Recipe, _ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
//        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.viewerRecipesObject.addToRecipes( recipe )
            
            self.saveContext()
            self.refetchViewerRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func accessoryTypeFor(_ recipe: Recipe ) -> UITableViewCell.AccessoryType {
        var accessory = UITableViewCell.AccessoryType.none
        
        for viewerRecipe in viewerRecipeArray {
            if recipe.guid == viewerRecipe.guid {
                accessory = .checkmark
                break
            }
            
        }
        
        return accessory
    }
    
    
    func fetchViewerDataFileFor(_ recipe: Recipe ) -> Data? {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return nil
        }
        
        let dataDirectoryURL = docURL.appendingPathComponent( DirectoryNames.viewerData )
        let fileDataURL      = dataDirectoryURL.appendingPathComponent( recipe.filename! )
        let fileDataPath     = fileDataURL.path + GlobalConstants.dataFileExtension

        if fileManager.fileExists(atPath: fileDataPath ) {
            do {
                let data = try Data( contentsOf: URL(fileURLWithPath: fileDataPath ) )
                logVerbose( "Read [ %d ] bytes for [ %@ ]", data.count, recipe.filename! )

                return data
            }

            catch let error as NSError {
                logVerbose( "ERROR!  Failed to read data for [ %@ ] ... Error[ %@ ]", recipe.filename!, error.localizedDescription )
            }

        }

        return nil
    }
    
    
    func fetchViewerRecipesObject(_ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
//        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchViewerRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func flushViewerRecipes() {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        for recipe in viewerRecipeArray {
            removeViewerDataFile( recipe.filename! )
        }

        persistentContainer.viewContext.perform {
            for recipe in self.viewerRecipeArray {
                self.viewerRecipesObject.removeFromRecipes( recipe )
            }
            
            self.saveContext()
            
            self.viewerRecipeArray = []
        }
        
    }
    
    
    func removeViewerRecipe(_ recipe: Recipe, _ delegate: NavigatorCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        removeViewerDataFile( recipe.filename! )
        
//        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.viewerRecipesObject.removeFromRecipes( recipe )
            self.saveContext()

            self.refetchViewerRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func saveFileDataFrom(_ recipe: Recipe, _ fileData: Data ) {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let dataDirectoryURL = docURL.appendingPathComponent( DirectoryNames.viewerData )
        let fileDataURL      = dataDirectoryURL.appendingPathComponent( recipe.filename! )
        let fileDataPath     = fileDataURL.path + GlobalConstants.dataFileExtension
        
        if !fileManager.fileExists(atPath: fileDataPath ) {
            do {
                try fileData.write(to: URL(fileURLWithPath: fileDataPath ), options: .atomic )
                logVerbose( "Wrote [ %d ] data bytes for [ %@ ]", fileData.count, recipe.filename! )
            }
            
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", recipe.filename!, error.localizedDescription )
            }

        }

    }

    
    
    // MARK: Viewer Utility Methods (Private)
    
    // Must be called from within persistentContainer.viewContext
    private func fetchViewerRecipes() {
        viewerRecipeArray = []
        
        do {
            let     request: NSFetchRequest<ViewerRecipes> = ViewerRecipes.fetchRequest()
            let     viewerRecipesObjectsArray = try managedObjectContext.fetch( request )
            
            
            if viewerRecipesObjectsArray.count == 1 {
                viewerRecipesObject = viewerRecipesObjectsArray[0]
                
                if viewerRecipesObject.recipes != nil {
                    if let recipeSet = viewerRecipesObject.recipes {
                        viewerRecipeArray = recipeSet.allObjects as! [Recipe]
                    }
                    
                }
                
            }
            
            logVerbose( "Retrieved [ %d ] container objects and [ %d ] viewer recipes", viewerRecipesObjectsArray.count, viewerRecipeArray.count )
        }
        
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    private func removeViewerDataFile(_ filename: String ) {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let dataDirectoryURL = docURL.appendingPathComponent( DirectoryNames.viewerData )
        let fileDataURL  = dataDirectoryURL.appendingPathComponent( filename )
        let fileDataPath = fileDataURL.path + GlobalConstants.dataFileExtension

        if fileManager.fileExists(atPath: fileDataPath ) {
            do {
                try fileManager.removeItem(atPath: fileDataPath )
                logVerbose( "Removed [ %@ ]", filename )
            }

            catch let error as NSError {
                logVerbose( "ERROR!  Failed to delete data for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }

        }
        
    }
    
    

    // MARK: Methods shared with CommonExtensions (Public)
    
    func nameForImageRequest(_ command: Int ) -> String {
        var     name = "Unknown"
        
        switch command {
        case OfflineImageRequestCommands.delete:    name = "Delete"
        case OfflineImageRequestCommands.fetch:     name = "Fetch"
        default:                                    name = "Save"
        }
        
        return name
    }
    
    
    func nameForSortType(_ sortType: String ) -> String {
        var name = "Unknown"
        
        switch sortType {
        case SortOptions.byFilename:        name = SortOptionNames.byFilename
        case SortOptions.byKeywords:        name = SortOptionNames.byKeywords
        case SortOptions.byRelativePath:    name = SortOptionNames.byRelativePath
        default:                             break
        }
        
        return name
    }
    
    
    func pictureDirectoryPath() -> String {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( "PinPictures" )
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                do {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return ""
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                logTrace( "ERROR!  photos directory does NOT exist!" )
                return ""
            }
            
            //            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
        //        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return ""
    }
    
    
    // Must be called from within persistentContainer.viewContext
    func processNextOfflineImageRequest() {
        
        if offlineImageRequestQueue.isEmpty {
            logTrace( "Done!" )
            updatedOffline = false
            
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                nasCentral.unlockNas( self )
            }
            
            deviceAccessControl.updating = false
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        else {
            guard let imageRequest = offlineImageRequestQueue.first else {
                logTrace( "ERROR!  Unable to remove request from front of queue!" )
                updatedOffline = false
                return
            }
            
            let command  = Int( imageRequest.command )
            let filename = imageRequest.filename ?? "Empty!"
            
            logVerbose( "pending[ %d ]  processing[ %@ ][ %@ ]", offlineImageRequestQueue.count, nameForImageRequest( command ), filename )
            
            switch command {
            case OfflineImageRequestCommands.delete:   nasCentral.deleteImage( filename, self )
                
                //           case OfflineImageRequestCommands.fetch:    imageRequestQueue.append( (filename, delegate! ) )
                //                                                      nasCentral.fetchImage( filename, self )
                
            case OfflineImageRequestCommands.save:     let result = fetchFromDiskImageFileNamed( filename )
                
                if result.0 {
                    nasCentral.saveImageData( result.1, filename: filename, self )
                }
                else {
                    logVerbose( "ERROR!  NAS does NOT have [ %@ ]", filename )
                    DispatchQueue.main.async {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
            default:    break
            }
            
            managedObjectContext.delete( imageRequest )
            offlineImageRequestQueue.remove( at: 0 )
            
            saveContext()
        }
        
    }
    
    
    func saveContext() {        // Must be called from within a persistentContainer.viewContext
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
                
                if dataStoreLocation != .device {
                    databaseUpdated = true
                    
                    if stayOffline {
                        updatedOffline = true
                    }
                    
                    createLastUpdatedFile()
                }
                
            }
            
            catch let error as NSError {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func canSeeExternalStorage() {
        if dataStoreLocation == .device {
            restarting = false
            deviceAccessControl.initForDevice()
            logVerbose( "on device ... %@", deviceAccessControl.descriptor() )
            return
        }
        
        logVerbose( "[ %@ ]", nameForDataLocation( dataStoreLocation ) )
        
        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            cloudCentral.canSeeCloud( self )
        }
        else {
            nasCentral.emptyQueue()
            nasCentral.canSeeNasFolders( self )
        }
        
    }
    
    
    private func copyFromBundleToDocumentsFolder(_ filename: String ) -> Bool {
        // This method is used to copy a sample recipe from the bundle to the documents directory when the app is primed
        var     fileCopied = false
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let components    = filename.components(separatedBy: "." )
            
            if components.count != 2 {
                logVerbose( "[ %@ ] is NOT properly formatted!", filename )
            }
            else {
                let rootFilename  = components.first
                let fileExtension = components.last
                
                if let bundleFileUrl = Bundle.main.url( forResource: rootFilename, withExtension: fileExtension ) {
                    var targetFileUrl = documentDirectoryURL
                    
                    targetFileUrl = targetFileUrl.appendingPathComponent( filename )
                    
                    do {
                        try fileManager.copyItem( at: bundleFileUrl, to: targetFileUrl )
                        fileCopied = true
                    }
                    
                    catch let error as NSError {
                        logVerbose( "ERROR!  Failed to copy [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
                    }
                    
                }
                else {
                    logVerbose( "[ %@ ] was NOT found!", filename )
                }
                
            }
            
        }
        
        return fileCopied
    }
    
    
    private func createViewerTempFolder() {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let viewerDataDirectoryURL = docURL.appendingPathComponent( DirectoryNames.viewerData )
        
        if !fileManager.fileExists( atPath: viewerDataDirectoryURL.path ) {
            do {
                try fileManager.createDirectory( atPath: viewerDataDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                logVerbose( "Created [ %@ ]", viewerDataDirectoryURL.path )
            }
            
            catch let error as NSError {
                logVerbose( "ERROR!  We Failed to create [ %@ ] ... Error[ %@ ]", viewerDataDirectoryURL.path, error.localizedDescription )
            }
            
        }

    }
    
    
    private func deleteDatabase() {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database )
        
        do {
            logVerbose( "attempting to delete database @ [ %@ ]", storeURL.path )
            try fileManager.removeItem( at: storeURL )
            
            userDefaults.removeObject( forKey: Constants.primedFlag )
            userDefaults.synchronize()
        }
        catch let error as NSError {
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", error.localizedDescription )
        }
        
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllImageRequestObjects() {
        offlineImageRequestQueue = []
        
        do {
            let     request         : NSFetchRequest<ImageRequest> = ImageRequest.fetchRequest()
            let     fetchedRequests = try managedObjectContext.fetch( request )
            
            offlineImageRequestQueue = fetchedRequests.sorted( by:
                                                                { (request1, request2) -> Bool in
                return request1.index < request2.index
            })
            
        }
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
        logVerbose( "Found [ %d ] requests", offlineImageRequestQueue.count )
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllRecipeObjects() {
        recipeArrayOfArrays   = []
        numberOfRecipesLoaded = 0
        
        do {
            let     request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
            let     fetchedRecipes = try managedObjectContext.fetch( request )
            
            numberOfRecipesLoaded = fetchedRecipes.count
            logVerbose( "Retrieved [ %d ] recipes ... sorting", numberOfRecipesLoaded )
            
            let sortTuple     = sortDescriptor
            let sortAscending = sortTuple.1
            let sortOption    = sortTuple.0
            
            switch sortOption {
            case SortOptions.byKeywords:    sortByKeywords(     fetchedRecipes, sortAscending )
            case SortOptions.byFilename:    sortByFilename(     fetchedRecipes, sortAscending )
            default:                        sortByRelativePath( fetchedRecipes, sortAscending )
            }
            
        }
        
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchRecipeKeywordsObject() {
        var objectFound = false
        
        recipeKeywords = []
        
        do {
            let request        : NSFetchRequest<RecipeKeywords> = RecipeKeywords.fetchRequest()
            let fetchedObjects = try managedObjectContext.fetch( request )
            
            if fetchedObjects.count == 1 {
                logTrace( "Found it!" )
                recipeKeywordsObject = fetchedObjects.first
                
                if let keywordString = recipeKeywordsObject.keywords {
                    recipeKeywords = keywordString.components(separatedBy: GlobalConstants.separatorForRecipeKeywordString )
                    objectFound = true
                }
                
            }
            else {
                logVerbose( "ERROR!!! We have invalid number [ %d ] of RecipeKeywords objects!", fetchedObjects.count )
            }
            
        }
        catch {
            logTrace( "Error!  Fetch failed!" )
        }
        
        if !objectFound {
            logTrace( "Object NOT found! ... using defaults" )
            createRecipeKeywordsObject()
        }
        
    }
    
    
    private func flatRecipeArray() -> [Recipe] {
        var flatArray: [Recipe] = []
        
        for array in recipeArrayOfArrays {
            for recipe in array {
                if !flatArray.contains( recipe ) {
                    flatArray.append( recipe )
                }
                
            }
            
        }
        
        return flatArray
    }
    
    
    private func keywordsIn(_ filename: String ) -> String {
        var keywordString = ""
        
        for keyword in recipeKeywords {
            if filename.contains( keyword ) {
                if !keywordString.isEmpty {
                    keywordString.append( "," )
                }
                
                keywordString.append( keyword )
            }
            
        }
        
        return keywordString
    }
    
    
    private func createRecipeKeywordsObject() {
        logTrace()
        let object = NSEntityDescription.insertNewObject( forEntityName: EntityNames.recipeKeywords, into: self.managedObjectContext ) as! RecipeKeywords
        
        // Pull in our default list
        var keywordString       = ""
        var sortedKeywordArray  = Constants.recipeKeywords.components(separatedBy: GlobalConstants.separatorForRecipeKeywordString )
        
        // Keep it in alpha order
        sortedKeywordArray = sortedKeywordArray.sorted(by: { (keyword1, keyword2) -> (Bool) in
            return keyword1.uppercased() < keyword2.uppercased()
        } )
        
        // Reconstruct the string (now sorted)
        for keyword in sortedKeywordArray {
            if !keywordString.isEmpty {
                keywordString += GlobalConstants.separatorForRecipeKeywordString
            }
            
            keywordString += keyword
        }
        
        // Stick it in our singleton object
        object.keywords = keywordString
        saveContext()
        
        recipeKeywords = sortedKeywordArray
    }
    
    
    private func loadBasicData() {
        let primedFlag = userDefaults.bool( forKey: Constants.primedFlag )
        logVerbose( "primedFlag[ %@ ]", stringFor( primedFlag ) )
        
        // Load and sort our public convenience arrays and sample data when priming
        self.persistentContainer.viewContext.perform {
            if !primedFlag {
                self.createRecipeKeywordsObject()
                
                for filename in self.sampleRecipeArray {
                    if self.copyFromBundleToDocumentsFolder( filename ) {
                        let recipe = NSEntityDescription.insertNewObject( forEntityName: EntityNames.recipe, into: self.managedObjectContext ) as! Recipe
                        
                        recipe.filename     = filename
                        recipe.guid         = UUID().uuidString
                        recipe.keywords     = self.keywordsIn( filename )
                        recipe.relativePath = ""
                        
                        self.saveContext()
                    }
                    
                }
                
                self.viewerRecipesObject = (NSEntityDescription.insertNewObject( forEntityName: EntityNames.viewerRecipes, into: self.managedObjectContext ) as! ViewerRecipes)
                
                self.saveContext()
                self.createViewerTempFolder()
                
                self.userDefaults.set( true, forKey: Constants.primedFlag )
                self.userDefaults.synchronize()
            }
            
            self.fetchRecipeKeywordsObject()    // Must be done first
            self.fetchAllRecipeObjects()
            self.fetchViewerRecipes()
            
            logVerbose( "Loaded Keywords[ %d ], Recipes[ %d ] & ViewerRecipe[ %d ] objects", self.recipeKeywords.count, self.numberOfRecipesLoaded, self.viewerRecipeArray.count )
        }
        
    }
    
    
    private func loadCoreData() {
        guard let modelURL = Bundle.main.url( forResource: Constants.databaseModel, withExtension: "momd" ) else {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )
        
        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )
        
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database  )
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options )
            
            self.didOpenDatabase = true
            logTrace( "added store to coordinator" )
        }
        catch {
            let     nsError = error as NSError
            
            logVerbose( "Error!  Unable migrate store[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    // Must be called from within a persistentContainer.viewContext
    private func refetchRecipesAndNotifyDelegate() {
        fetchAllRecipeObjects()
        
        DispatchQueue.main.async {
            self.delegate?.navigatorCentral( self, didReloadRecipes: ( self.recipeArrayOfArrays.count != 0 ) )
        }
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.recipeArrayReloaded ), object: self )
    }
    
    
    // Must be called from within a persistentContainer.viewContext
    private func refetchViewerRecipesAndNotifyDelegate() {
        fetchViewerRecipes()
        
        DispatchQueue.main.async {
            logTrace( "calling delegate" )
            self.delegate?.navigatorCentralDidUpdateViewerRecipes( self )
        }
        
        if .pad == UIDevice.current.userInterfaceIdiom {
            logTrace( "posting viewerRecipesArrayReloaded" )
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.viewerRecipesArrayReloaded ), object: self )
        }
        
    }
    
    
}



// MARK: Sorting Methods (Private)

extension NavigatorCentral {
    
    private func sortByKeywords(_ fetchedRecipes: [Recipe], _ sortAscending: Bool ){
        recipeArrayOfArrays = []
        sectionTitleArray   = []

        if fetchedRecipes.count == 0 {
            logVerbose( "sortAscending[ %@ ] ... we have zero recipes!  Do nothing!", stringFor( sortAscending ) )
            return
        }
        
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        var outputArrayOfArrays: [[Recipe]] = []
        let emptyArray:           [Recipe]  = []
        
        // First we construct an empty array of arrays to hold our results
        for _ in self.recipeKeywords {
            outputArrayOfArrays.append( emptyArray )
        }
        
        // Then we trundle through all of the recipes and dump them into the appropriate array in our outputArrayOfArrays
        for recipe in fetchedRecipes {
            // Retrieve the keywords from the recipe
            if let recipeKeywordString = recipe.keywords {
                let recipeKeywordArray = recipeKeywordString.components(separatedBy: GlobalConstants.separatorForRecipeKeywordString )
            
                // Then identify which array to copy the recipe into for each keyword
                for recipeKeyword in recipeKeywordArray {
                    for index in 0..<self.recipeKeywords.count {
                        if recipeKeyword.uppercased() == recipeKeywords[index].uppercased() {
                            outputArrayOfArrays[index].append( recipe )
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        // Sort recipeKeywords and sort recipeArrayOfArrays appropriately
        if sortAscending {
            recipeArrayOfArrays = outputArrayOfArrays
            sectionTitleArray   = recipeKeywords
        }
        else {
            var flippedArrayOfArrays: [[Recipe]] = []
            var flippedKeywordArray : [String]   = []
            var localKeywordArray                = self.recipeKeywords
            
            for _ in 0..<outputArrayOfArrays.count {
                flippedArrayOfArrays.append( outputArrayOfArrays.last! )
                outputArrayOfArrays.removeLast()
            }
            
            for _ in 0..<self.recipeKeywords.count {
                flippedKeywordArray.append( localKeywordArray.last! )
                localKeywordArray.removeLast()
            }
            
            recipeArrayOfArrays = flippedArrayOfArrays
            sectionTitleArray   = flippedKeywordArray
        }
        
        // Finally, we sort the contents of all of the arrays in the outputArrayOfArrays
        for index in 0..<outputArrayOfArrays.count {
            let sortedArray = outputArrayOfArrays[index].sorted(by: { (recipe1, recipe2) -> (Bool) in
                return sortAscending ? ( recipe1.filename!.uppercased() < recipe2.filename!.uppercased() ) : recipe1.filename!.uppercased() > recipe2.filename!.uppercased()
            })
            
            outputArrayOfArrays[index] = sortedArray
        }
        
    }

    
    private func sortByFilename(_ fetchedRecipes: [Recipe], _ sortAscending: Bool ) {
        recipeArrayOfArrays = []
        sectionTitleArray   = []

        if fetchedRecipes.count == 0 {
            logVerbose( "sortAscending[ %@ ] ... we have zero recipes!  Do nothing!", stringFor( sortAscending ) )
            return
        }
        
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedRecipes.sorted( by:
                    { (recipe1, recipe2) -> Bool in
                        if sortAscending {
                            recipe1.filename! < recipe2.filename!
                        }
                        else {
                            recipe1.filename! > recipe2.filename!
                        }
            
                    } )

        recipeArrayOfArrays = [sortedArray]
    }
    
    
    private func sortByRelativePath(_ fetchedRecipes: [Recipe], _ sortAscending: Bool ) {
        recipeArrayOfArrays = []
        sectionTitleArray   = []

        if fetchedRecipes.count == 0 {
            logVerbose( "sortAscending[ %@ ] ... we have zero recipes!  Do nothing!", stringFor( sortAscending ) )
            return
        }
        
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedRecipes.sorted( by:
                    { (recipe1, recipe2) -> Bool in
                        if sortAscending {
                            recipe1.relativePath! < recipe2.relativePath!
                        }
                        else {
                            recipe1.relativePath! > recipe2.relativePath!
                        }
            
                    } )
        
        // Now we create and load arrays for each new path
        var currentPath                     = ""
        var outputArrayOfArrays: [[Recipe]] = []
        var pathArray:            [String]  = []
        var workingArray:         [Recipe]  = []

        if let startingPath = sortedArray.first?.relativePath {
            currentPath = startingPath
        }

        for recipe in sortedArray {
            if currentPath == recipe.relativePath {
                workingArray.append( recipe )
            }
            else {
                if workingArray.count != 0 {
                    outputArrayOfArrays.append( workingArray )
                    pathArray          .append( removeRootPathFrom( currentPath ) )
                    
                    currentPath = recipe.relativePath ?? ""
                    workingArray = [recipe]
                }
                
            }
            
        }
        
        if workingArray.count != 0 {
            outputArrayOfArrays.append( workingArray )
            pathArray.append( removeRootPathFrom( currentPath ) )
        }
        
        // Finally, we sort the contents of all of the arrays in the outputArrayOfArrays
        for index in 0..<outputArrayOfArrays.count {
            let sortedArray = outputArrayOfArrays[index].sorted(by: { (recipe1, recipe2) -> (Bool) in
                return sortAscending ? ( recipe1.filename!.uppercased() < recipe2.filename!.uppercased() ) : recipe1.filename!.uppercased() > recipe2.filename!.uppercased()
            })
            
            outputArrayOfArrays[index] = sortedArray
        }
        
        recipeArrayOfArrays = outputArrayOfArrays
        sectionTitleArray   = pathArray
    }

    
    
    // MARK: Sorting Utility Methods (Private)

    private func removeRootPathFrom(_ path: String ) -> String {
        let rootPath       = dataSourceDescriptor.path + "/"
        let pathComponents = path.components(separatedBy: rootPath )
        var truncatedPath  = "."
        
        if pathComponents.count == 2 {
            truncatedPath = pathComponents[1]
        }

        return truncatedPath
    }
    
    
}



// MARK: Timer Methods (Public)

extension NavigatorCentral {
    
    func startTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            return
        }
        
        if stayOffline {
            logTrace( "stay offline" )
            return
        }
        
        logTrace()
        if let timer = updateTimer {
            timer.invalidate()
        }
        
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer( withTimeInterval: Constants.timerDuration, repeats: false ) {
                (timer) in
                
                if self.deviceAccessControl.updating {
                    logTrace( "We are updating ... do nothing!" )
                }
                else if self.databaseUpdated {
                    self.databaseUpdated = false
                    logVerbose( "databaseUpdated[ true ]\n    %@", self.deviceAccessControl.descriptor() )

                    if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                        logTrace( "copying database to iCloud" )
                        self.cloudCentral.copyDatabaseFromDeviceToCloud( self )
                    }
                    else {  // .nas
                        logTrace( "copying database to NAS" )
                        self.nasCentral.copyDatabaseFromDeviceToNas( self )
                    }

                }
                else {
                    if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                        logTrace( "ending iCloud session" )
                        self.cloudCentral.endSession( self )
                    }
                    else {  // .nas
                        logTrace( "ending NAS session" )
                        self.nasCentral.endSession( self )
                    }

                }
                
            }

        }
        
    }
    
    
    func stopTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            databaseUpdated = false
            return
        }
        
        if let timer = updateTimer {
            timer.invalidate()
        }

        logVerbose( "databaseUpdated[ %@ ]\n    %@", stringFor( databaseUpdated ), deviceAccessControl.descriptor() )
        
        if databaseUpdated {
            
            if !stayOffline {
                DispatchQueue.global().async {

                    // The OS calls this block if we don't finish in time
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Finish copying DB to External Device" ) {
                        if self.dataStoreLocation == .nas || self.dataStoreLocation == .shareNas {
                            logVerbose( "queueContents[ %@ ]", self.nasCentral.queueContents() )
                        }

                        logTrace( "We ran out of time!  Killing background task..." )
                        UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                        
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                    
                    if self.deviceAccessControl.updating {
                        logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                    }
                    else {
                        self.databaseUpdated = false
                        self.deviceAccessControl.updating = true
                        
                        if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                            logTrace( "copying database to iCloud" )
                            self.cloudCentral.copyDatabaseFromDeviceToCloud( self )
                        }
                        else {  // .nas
                            logTrace( "copying database to NAS" )
                            self.nasCentral.copyDatabaseFromDeviceToNas( self )
                        }
                        
                    }
                    
                }

            }
            
        }
        else {
            if !deviceAccessControl.byMe {
                logTrace( "do nothing!" )
                return
            }
            
            if !stayOffline {
                DispatchQueue.global().async {

                    // The OS calls this block if we don't finish in time
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Remove lock file" ) {
                        if self.dataStoreLocation == .nas || self.dataStoreLocation == .shareNas {
                            logVerbose( "queueContents[ %@ ]", self.nasCentral.queueContents() )
                        }

                        logTrace( "We ran out of time!  Ending background task #2..." )
                        UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                        
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                    
                    if self.deviceAccessControl.updating {
                        logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                    }
                    else {
                        logTrace( "removing lock file" )
                        if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                            self.cloudCentral.unlockCloud( self )
                        }
                        else {  // .nas
                            self.nasCentral.unlockNas( self )
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }

}
