//
//  CloudCentral.swift
//  WineStock
//
//  Created by Clint Shank on 3/24/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol CloudCentralDelegate: AnyObject {
    
    // Discovery Methods
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud           : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCreateDirectoryTree: Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool )

    // Session Methods
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles         : Int, lastUpdatedBy: String )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyATOSFromCloudToDevice       : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyATOSFromDeviceToCloud       : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice   : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud   : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didMoveSharedFilesFromDeviceToCloud: Bool, fileUrlArray: [URL] )
    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteRepoFile  : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession      : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchRepoNames  : Bool, _ filenames: [String] )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchRepoData   : Bool, _ filename: String, _ data: Data )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage      : Bool, _ filename: String, _ image: UIImage )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImageNames : Bool, _ filenames: [String] )
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchSharedFiles: Bool, _ filenames: [String] )
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud       : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveFileData    : Bool, filename: String )
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession    : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud     : Bool )
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles     : [String] )
}

// Now we supply we provide a default implementation which makes them all optional
extension CloudCentralDelegate {
    
    // Discovery Methods
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud           : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCreateDirectoryTree: Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool ) {}

    // Session Methods
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles         : Int, lastUpdatedBy: String ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyATOSFromCloudToDevice       : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyATOSFromDeviceToCloud       : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice   : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud   : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didMoveSharedFilesFromDeviceToCloud: Bool, fileUrlArray: [URL] ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteRepoFile  : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession      : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchRepoData   : Bool, _ filename: String, _ data: Data ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchRepoNames  : Bool, _ filenames: [String] ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage      : Bool, _ filename: String, _ image: UIImage ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImageNames : Bool, _ filenames: [String] ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchSharedFiles: Bool, _ filenames: [String] ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud       : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveFileData    : Bool, filename: String ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession    : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud     : Bool ) {}
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles     : [String] ) {}
}



class CloudCentral: NSObject {
    
    
    // MARK: Public Definitions
    
    var repoDirectory: String {
        get {
            var directoryName = repoDirectoryBacking
            
            if repoDirectoryBacking.isEmpty {
                if let directory = userDefaults.string( forKey: UserDefaultKeys.repoDirectory ) {
                    repoDirectoryBacking = directory
                    directoryName = repoDirectoryBacking
                }
                
            }
            
            return directoryName
        }
        
        // This is set by the AppDelegate
    }
    
    
    
    // MARK: Private Variables & Definitions
    
    private enum Command {
        // Discovery Methods
        case CanSeeCloud
        case CreateDrirectoryTree
        case IsRootDirectoryPresent
        
        // Session Methods
        case CompareLastUpdatedFiles
        case CopyATOSFromCloudToDevice
        case CopyATOSFromDeviceToCloud
        case CopyDatabaseFromCloudToDevice
        case CopyDatabaseFromDeviceToCloud
        case MoveSharedFilesFromDeviceToCloud
        case DeleteFromRepo
        case EndSession
        case FetchDataFromRepo
        case FetchDbFiles
        case FetchImage
        case FetchImageNames
        case FetchRepoFilenames
        case FetchSharedFiles
        case LockCloud
        case SaveFileData
        case StartSession
        case UnlockCloud
    }
    
    private struct Constants {  // NOTE: lastUpdated needs to be first (which is processed last) to prevent trashing the database in the event that the update fails
        static let databaseFilenameArray = [ Filenames.lastUpdated, Filenames.database, Filenames.databaseShm, Filenames.databaseWal ]
    }
    
    private var cloudAppPicturesUrl: URL {   // Sub-directory of root
        get {
            return cloudAppRootUrl.appendingPathComponent( DirectoryNames.pictures )
        }
        
    }
    
    private var cloudAppRepoUrl: URL {   // Sub-directory of root
        get {
            return cloudAppRootUrl.appendingPathComponent( repoDirectory )
        }
        
    }
    
    private var cloudAppRootUrl: URL {
        get {
            return cloudDefaultUrl.appendingPathComponent( DirectoryNames.root )
        }
        
    }
    
    private var cloudDefaultUrl: URL {
        get {
            return FileManager.default.url( forUbiquityContainerIdentifier: nil )!
        }
        
    }
    
    private var deviceName: String {
        get {
            var     name = UIDevice.current.name

            if let deviceNameString = UserDefaults.standard.string( forKey: UserDefaultKeys.deviceName ) {
                if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                    name = deviceNameString
                }

            }
            
            return name
        }
        
    }
    
    private var cloudImageFileArray    : [String] = []
    private var currentCommand         : Command!
    private var currentFilename        = ""
    private var delegate               : CloudCentralDelegate!
    private var deviceAccessControl    = DeviceAccessControl.sharedInstance
    private var documentDirectoryURL   = URL( fileURLWithPath: "" )
    private var repoDirectoryBacking   = ""
    private var fileManager            = FileManager.default
    private var reEstablishConnection  = false
    private var requestQueue           : [[Any]] = []
    private var sessionActive          = false
    private let userDefaults           = UserDefaults.standard
    


    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = CloudCentral()        // Prevents anyone else from creating an instance
}



// MARK: External Interface Methods (Queued)

extension CloudCentral {
    
    // Discovery Methods
    func canSeeCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CanSeeCloud, delegate] )
    }
    
    
    func createDrirectoryTree(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CreateDrirectoryTree, delegate] )
    }

    
    func isRootDirectoryPresent(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.IsRootDirectoryPresent, delegate] )
    }


    // Session Methods
    func compareLastUpdatedFiles(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CompareLastUpdatedFiles, delegate] )
    }

    
    func copyATOSFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyATOSFromCloudToDevice, delegate] )
    }
    
    
    func copyATOSFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyATOSFromDeviceToCloud, delegate] )
    }
    
    
    func copyDatabaseFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromCloudToDevice, delegate] )
    }
    
    
    func copyDatabaseFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromDeviceToCloud, delegate] )
    }
    
    
    func moveSharedFilesFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.MoveSharedFilesFromDeviceToCloud, delegate] )
    }
    
    
    func deleteFromRepo(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.DeleteFromRepo, filename, delegate] )
    }
    
    
    func endSession(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.EndSession, delegate] )
    }
    
    
    func fetchDataFromRepo(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchDataFromRepo, filename, delegate] )
    }
    
    
    func fetchDbFiles(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchDbFiles, delegate] )
    }
    
    
    func fetchRepoFilenames(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchRepoFilenames, delegate] )
    }

    
    func fetchImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchImage, filename, delegate] )
    }
    
    
    func fetchImageNames(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchImageNames, delegate] )
    }
    
    
    func fetchSharedFiles(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.FetchSharedFiles, delegate] )
    }

    
    func lockCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.LockCloud, delegate] )
    }
    
    
    func saveFileData(_ fileData: Data, filename: String, _ delegate: CloudCentralDelegate ) {
        addRequest( [Command.SaveFileData, fileData, filename, delegate] )
    }
    
    
    func startSession(_ delegate: CloudCentralDelegate  ) {
        addRequest( [Command.StartSession, delegate] )
    }

    
    func unlockCloud(_ delegate: CloudCentralDelegate ) {
        addRequest( [Command.UnlockCloud, delegate] )
    }

    
    
    // MARK: Utility Methods (Private)
    
    private func addRequest(_ request: [Any] ) {
        let     requestQueueIdle = requestQueue.isEmpty
        
        logVerbose( "[ %@ ] ... queued requests[ %d ]", stringForCommand( request[0] as! Command ), requestQueue.count )
        requestQueue.append( request )
        
        if requestQueueIdle {
            DispatchQueue.global().async {
                self.processNextRequest( false )
            }
            
        }

    }
    
    
    private func isSessionCommand(_ command: Command ) -> Bool {
        var isSession = true
        
        switch command {
        case .CanSeeCloud, .CreateDrirectoryTree, .FetchDataFromRepo, .IsRootDirectoryPresent:
             isSession = false
        default:    break
        }
        
        return isSession
    }
    
    
    private func processNextRequest(_ popHeadOfQueue: Bool = true ) {

        if popHeadOfQueue {
            logTrace( "Popping head of requestQueue" )
            requestQueue.remove( at: 0 )
        }

        if requestQueue.isEmpty {
            logTrace( "going IDLE" )
            return
        }
        
        guard let request = requestQueue.first else {
            logTrace( "ERROR!  Unable to remove request from front of queue!" )
            return
        }

        let command = request[0] as! Command
        
        if !sessionActive && isSessionCommand( command ) && command != .StartSession {
            logTrace( "Re-establishing session" )
            reEstablishConnection = true
            _startSession( delegate )
            return
        }
        
        logVerbose( "[ %@ ]", stringForCommand( command ) )
        currentCommand = command
        
        switch currentCommand {
            
            // Discovery Methods
        case .CanSeeCloud:                      _canSeeCloud(            request[1] as! CloudCentralDelegate )
        case .CreateDrirectoryTree:             _createDrirectoryTree(   request[1] as! CloudCentralDelegate )
        case .IsRootDirectoryPresent:           _isRootDirectoryPresent( request[1] as! CloudCentralDelegate )
            
            // Session Methods
        case .CompareLastUpdatedFiles:          _compareLastUpdatedFiles(          request[1] as! CloudCentralDelegate )
        case .CopyATOSFromCloudToDevice:        _copyATOSFromCloudToDevice(        request[1] as! CloudCentralDelegate )
        case .CopyATOSFromDeviceToCloud:        _copyATOSFromDeviceToCloud(        request[1] as! CloudCentralDelegate )
        case .CopyDatabaseFromCloudToDevice:    _copyDatabaseFromCloudToDevice(    request[1] as! CloudCentralDelegate )
        case .CopyDatabaseFromDeviceToCloud:    _copyDatabaseFromDeviceToCloud(    request[1] as! CloudCentralDelegate )
        case .MoveSharedFilesFromDeviceToCloud: _moveSharedFilesFromDeviceToCloud( request[1] as! CloudCentralDelegate )
        case .DeleteFromRepo:                   _deleteFromRepo(        request[1] as! String, request[2] as! CloudCentralDelegate )
        case .EndSession:                       _endSession(            request[1] as! CloudCentralDelegate )
        case .FetchDataFromRepo:                _fetchDataFromRepo(     request[1] as! String, request[2] as! CloudCentralDelegate )
        case .FetchDbFiles:                     _fetchDbFiles(          request[1] as! CloudCentralDelegate )
        case .FetchImage:                       _fetchImage(            request[1] as! String, request[2] as! CloudCentralDelegate )
        case .FetchImageNames:                  _fetchImageNames(       request[1] as! CloudCentralDelegate )
        case .FetchRepoFilenames:               _fetchFilesFrom( true,  request[1] as! CloudCentralDelegate )
        case .FetchSharedFiles:                 _fetchFilesFrom( false, request[1] as! CloudCentralDelegate )
        case .LockCloud:                        _lockCloud(             request[1] as! CloudCentralDelegate )
        case .SaveFileData:                     _saveFileData(          request[1] as! Data, filename: request[2] as! String, request[3] as! CloudCentralDelegate )
        case .StartSession:                     _startSession(          request[1] as! CloudCentralDelegate )
        case .UnlockCloud:                      _unlockCloud(           request[1] as! CloudCentralDelegate )
            
        default:                               logTrace( "SBH!" )
        }
        
    }
    
    
    private func stringForCommand(_ command: Command ) -> String {
        var     description = "Unknown"
        
        switch command {
        case .CanSeeCloud:                      description = "CanSeeCloud"
        case .CompareLastUpdatedFiles:          description = "CompareLastUpdatedFiles"
        case .CopyATOSFromCloudToDevice:        description = "CopyATOSFromCloudToDevice"
        case .CopyATOSFromDeviceToCloud:        description = "CopyATOSFromDeviceToCloud"
        case .CopyDatabaseFromCloudToDevice:    description = "CopyDatabaseFromCloudToDevice"
        case .CopyDatabaseFromDeviceToCloud:    description = "CopyDatabaseFromDeviceToCloud"
        case .MoveSharedFilesFromDeviceToCloud: description = "moveSharedFilesFromDeviceToCloud"
        case .CreateDrirectoryTree:             description = "CreateDrirectoryTree"
        case .DeleteFromRepo:                   description = "DeleteFromRepo"
        case .EndSession:                       description = "EndSession"
        case .FetchDataFromRepo:                description = "FetchDataFromRepo"
        case .FetchDbFiles:                     description = "FetchDbFiles"
        case .FetchImage:                       description = "FetchImage"
        case .FetchImageNames:                  description = "FetchImageNames"
        case .FetchRepoFilenames:               description = "FetchRepoFilenames"
        case .FetchSharedFiles:                 description = "FetchSharedFiles"
        case .IsRootDirectoryPresent:           description = "IsRootDirectoryPresent"
        case .LockCloud:                        description = "LockCloud"
        case .SaveFileData:                     description = "SaveFileData"
        case .StartSession:                     description = "StartSession"
        case .UnlockCloud:                      description = "UnlockCloud"
        }
        
        return description
    }
    
    
}



// MARK: Discovery Methods (Private)

extension CloudCentral {
    
    private func _canSeeCloud(_ delegate: CloudCentralDelegate ) {
        let canSeeCloud = ( fileManager.ubiquityIdentityToken != nil )
        
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, canSeeCloud: canSeeCloud )
            self.processNextRequest()
        }

    }
    
    
    private func _createDrirectoryTree(_ delegate: CloudCentralDelegate ) {
        var     didCreateDirectoryTree = false

        if fileManager.fileExists( atPath: cloudAppRootUrl.path ) {
            logTrace( "[ true ] ... cloudAppRootUrl already present" )
            didCreateDirectoryTree = true
        }
        else {
            
            do {
                try fileManager.createDirectory( atPath: cloudAppRootUrl.path, withIntermediateDirectories: true, attributes: nil )
                logTrace( "     created root directory" )

                do {
                    try fileManager.createDirectory( atPath: cloudAppPicturesUrl.path, withIntermediateDirectories: true, attributes: nil )
                    logTrace( "     created pictures directory" )
                    
                    // ---- App Specific ----
                    do {
                        try fileManager.createDirectory( atPath: cloudAppRepoUrl.path, withIntermediateDirectories: true, attributes: nil )
                        didCreateDirectoryTree = true
                        logTrace( "     created repo directory" )
                    }
                    
                    catch let error as NSError {
                        logVerbose( "ERROR!  Failed to create repo directory ... Error[ %@ ]", error.localizedDescription )
                    }

                    // ----------------------
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create pictures directory ... Error[ %@ ]", error.localizedDescription )
                }

            }
            
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to create root directory ... Error[ %@ ]", error.localizedDescription )
            }

        }
            
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCreateDirectoryTree: didCreateDirectoryTree )
            self.processNextRequest()
        }
        
    }

    
    private func _isRootDirectoryPresent(_ delegate: CloudCentralDelegate ) {
        var     rootDirectoryIsPresent = false

        if fileManager.fileExists( atPath: cloudAppRootUrl.path, isDirectory: nil ) {
            // ---- App Specific ----
            if fileManager.fileExists( atPath: cloudAppRepoUrl.path, isDirectory: nil ) {
                rootDirectoryIsPresent = true
            }
            // ----------------------

        }
        
        logVerbose( "[ %@ ]", stringFor( rootDirectoryIsPresent ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, rootDirectoryIsPresent: rootDirectoryIsPresent )
            self.processNextRequest()
        }
        
    }
    
    
}




// MARK: Session Methods

extension CloudCentral {
    
    private func _compareLastUpdatedFiles(_ delegate: CloudCentralDelegate ) {
//        let compareResult = compareLastUpdatedFiles()
//        
//        logVerbose( "[ %@ ] lastUpdatedBy: [ %@ ]", descriptionForCompare( compareResult.0 ), compareResult.1 )
//        
//        DispatchQueue.main.async {
//            delegate.cloudCentral( self, didCompareLastUpdatedFiles: compareResult.0, lastUpdatedBy: compareResult.1 )
//            self.processNextRequest()
//        }
        
    }

    
    private func _copyATOSFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        logTrace()
        var copySuccessful        = true
        var fileUrlArray          = contentsOf( cloudAppPicturesUrl )
        var filesToDeleteUrlArray = contentsOf( documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures ) )

        if !fileUrlArray.isEmpty {
            deleteFiles( filesToDeleteUrlArray )    // from device

            let     filesCopiedFromCloudToDevice = copyFilesFromCloudToDevice( DirectoryNames.pictures, fileUrlArray )

            copySuccessful = filesCopiedFromCloudToDevice == fileUrlArray.count
        }
        
        fileUrlArray          = contentsOf( cloudAppRepoUrl )
        filesToDeleteUrlArray = contentsOf( documentDirectoryURL.appendingPathComponent( DirectoryNames.recipes ) )

        if copySuccessful && !fileUrlArray.isEmpty {
            deleteFiles( filesToDeleteUrlArray )    // from device

            let     filesCopiedFromCloudToDevice = copyFilesFromCloudToDevice( DirectoryNames.recipes, fileUrlArray )

            copySuccessful = filesCopiedFromCloudToDevice == fileUrlArray.count
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyATOSFromCloudToDevice: copySuccessful )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyATOSFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        logTrace()
        var copySuccessful        = true
        var filesToDeleteUrlArray = contentsOf( cloudAppPicturesUrl )
        var fileUrlArray          = contentsOf( documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures ) )

        if !fileUrlArray.isEmpty {
            deleteFiles( filesToDeleteUrlArray )    // from cloud

            let     filesCopiedFromCloudToDevice = copyFilesFromCloudToDevice( DirectoryNames.pictures, fileUrlArray )

            copySuccessful = filesCopiedFromCloudToDevice == fileUrlArray.count
        }
        
        filesToDeleteUrlArray = contentsOf( cloudAppRepoUrl )
        fileUrlArray          = contentsOf( documentDirectoryURL.appendingPathComponent( DirectoryNames.recipes ) )

        if copySuccessful && !fileUrlArray.isEmpty {
            deleteFiles( filesToDeleteUrlArray )    //  from cloud

            let     filesCopiedFromCloudToDevice = copyFilesFromCloudToDevice( DirectoryNames.recipes, fileUrlArray )

            copySuccessful = filesCopiedFromCloudToDevice == fileUrlArray.count
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyATOSFromCloudToDevice: copySuccessful )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyDatabaseFromCloudToDevice(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let fileUrlArray = databaseUrlArrayForCloud( false )    // device URLs
        
        deleteFiles( fileUrlArray )
        
        let     didCopyDatabaseFromCloudToDevice = copyDatabaseFromCloudToDevice( fileUrlArray )
        
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromCloudToDevice ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyDatabaseFromCloudToDevice: didCopyDatabaseFromCloudToDevice )
            self.processNextRequest()
        }
        
    }
    
    
    private func _copyDatabaseFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let fileUrlArray = databaseUrlArrayForCloud( true )     // cloud URLs
        
        deleteFiles( fileUrlArray )

        let     didCopyDatabaseFromDeviceToCloud = copyDatabaseFromDeviceToCloud( fileUrlArray )
        
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToCloud ) )
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didCopyDatabaseFromDeviceToCloud: didCopyDatabaseFromDeviceToCloud )
            self.processNextRequest()
        }
        
    }
    
    
    private func _deleteFromRepo(_ filename: String, _ delegate: CloudCentralDelegate ) {
        var     didDeleteFile  = false
        let     fileUrl        = cloudAppRepoUrl.appendingPathComponent( filename )
        
        do {
            if fileManager.fileExists(atPath: fileUrl.path ) {
                try fileManager.removeItem( at: fileUrl )
                logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
            }
            else {
                logVerbose( "[ %@ ] Does NOT Exist", fileUrl.lastPathComponent )
            }
            
            didDeleteFile = true
        }
        
        catch let error as NSError {
            logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didDeleteRepoFile: didDeleteFile )
            self.processNextRequest()
        }
        
    }
    
    
    private func _endSession(_ delegate: CloudCentralDelegate ) {
        logTrace()
        sessionActive = false

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didEndSession: true )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchDataFromRepo(_ filename: String, _ delegate: CloudCentralDelegate ) {
        var     didFetchData = false
        let     fileUrl      = cloudAppRepoUrl.appendingPathComponent( filename )
        let     fileData     = fileManager.contents( atPath: fileUrl.path )
        var     returnData   = Data.init()

        if let data = fileData {
            didFetchData = true
            returnData   = data
        }
        else {
            logVerbose( "ERROR!  Failed to load data for [ %@ ]", fileUrl.path )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetchRepoData: didFetchData, filename, returnData )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchDbFiles(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let     dbFilenameArray = [Filenames.database, Filenames.databaseShm, Filenames.databaseWal, Filenames.lastUpdated]
        var     missingDbFiles  = [String].init()

        for filename in dbFilenameArray {
            let     dbFileUrl  = cloudAppRootUrl.appendingPathComponent( filename )
            let     dbFileData = fileManager.contents( atPath: dbFileUrl.path )

            if let _ = dbFileData {
                logVerbose( "Read contents of [ %@ ]!", filename )
            }
            else {
                logVerbose( "ERROR!!!  Could NOT read contents of [ %@ ]!", filename )
                missingDbFiles.append( filename )
            }
            
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, missingDbFiles: missingDbFiles )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchFilesFrom(_ repoDirectory: Bool, _ delegate :CloudCentralDelegate ) {
//        logTrace()
        var     didFetch      = true
        var     filenameArray = [String].init()
        var     filteredArray = [String].init()
        let     sourceUrl     = repoDirectory ? cloudAppRepoUrl : cloudAppRootUrl   // when using the root, we are looking for shared files
        
        if !fileManager.fileExists( atPath: sourceUrl.path ) {
            logVerbose( "Directory does NOT exist!\n    [ %@ ] ", sourceUrl.path )
            return
        }
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: sourceUrl.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files, the Library folder & database files
                if startingString == "." || filename == "Library" || filename.contains( "sqlite" ){
                    continue
                }
                
                // Filter out sub-directories
                let     fileUrl      = sourceUrl.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        filteredArray.append( filename )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
            didFetch = false
        }

        DispatchQueue.main.async {
            if repoDirectory {
                delegate.cloudCentral( self, didFetchRepoNames: didFetch, filteredArray )
            }
            else {
                delegate.cloudCentral( self, didFetchSharedFiles: didFetch, filteredArray )
            }

            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchImage(_ filename: String, _ delegate: CloudCentralDelegate ) {
        var     didFetchImage  = false
        var     image          = UIImage.init()
        let     imageFileUrl   = cloudAppPicturesUrl.appendingPathComponent( filename )
        let     imageFileData  = fileManager.contents( atPath: imageFileUrl.path )

        if let imageData = imageFileData {
            if let imageFromData = UIImage.init( data: imageData ) {
                logVerbose( "Loaded image [ %@ ]", filename )
                
                image         = imageFromData
                didFetchImage = true
            }
            else {
                logVerbose( "ERROR!  Unable to convert data into image for [ %@ ]", filename )
            }

        }
        else {
            logVerbose( "ERROR!  Failed to load data for image! [ %@ ]", filename )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetchImage: didFetchImage, filename, image )
            self.processNextRequest()
        }
        
    }
    
    
    private func _fetchImageNames(_ delegate :CloudCentralDelegate ) {
//        logTrace()
        var     didFetch         = true
        var     filenameArray    = [String].init()
        var     filteredArray    = [String].init()
        
        if !fileManager.fileExists( atPath: cloudAppPicturesUrl.path ) {
            logVerbose( "Directory does NOT exist!\n    [ %@ ] ", cloudAppPicturesUrl.path )
            return
        }
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: cloudAppPicturesUrl.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files and the Library folder
                if startingString == "." || filename == "Library" {
                    continue
                }
                
                // Filter out sub-directories
                let     fileUrl      = cloudAppPicturesUrl.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        filteredArray.append( filename )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
            didFetch = false
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didFetchImageNames: didFetch, filteredArray )
            self.processNextRequest()
        }
        
    }
    
    
    private func _lockCloud(_ delegate: CloudCentralDelegate ) {
        logTrace()
        let     lockFileUrl     = cloudAppRootUrl.appendingPathComponent( Filenames.lockFile )
        let     thisDeviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     thisDeviceName  = UIDevice.current.name

        deviceAccessControl.reset()
        deviceAccessControl.locked = true

        if !fileManager.fileExists( atPath: lockFileUrl.path, isDirectory: nil ) {
            createLockFile()
        }
        else {
            
            do {
                var     fileData: Data!
                
                try fileData = Data( contentsOf: lockFileUrl )
                
                let     lockMessage  = String( decoding: fileData, as: UTF8.self )
                let     components   = lockMessage.components( separatedBy: "," )
                
                if components.count == 2 {
                    let     lockDeviceId   = components[1]
                    let     lockDeviceName = components[0]
                    let     byMe           = ( thisDeviceName == lockDeviceName ) && ( thisDeviceId == lockDeviceId )

                    deviceAccessControl.byMe      = byMe
                    deviceAccessControl.ownerName = lockDeviceName
                    logVerbose( "From existing lock file ... %@", deviceAccessControl.descriptor() )
                }
                else {
                    logVerbose( "ERROR!  lockMessage NOT properly formatted\n    [ %@ ]", lockMessage )

                    if lockMessage.count == 0 {
                        createLockFile()

                        deviceAccessControl.byMe      = true
                        deviceAccessControl.locked    = true
                        deviceAccessControl.ownerName = thisDeviceName
                        logVerbose( "Overriding ... %@", deviceAccessControl.descriptor() )
                    }
                    
                }

            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to read from lock file ... Error[ %@ ]", error.localizedDescription )
            }

        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didLockCloud: self.deviceAccessControl.byMe )
            self.processNextRequest()
        }
        
    }
    
    
    private func _moveSharedFilesFromDeviceToCloud(_ delegate: CloudCentralDelegate ) {
        logTrace()
        var didMoveAll   = true
        var filesMoved   = 0
        let fileUrlArray = sharedFilesUrlArray()
        
        if fileUrlArray.count > 0 {
            filesMoved = copyFilesFromDeviceToCloud( DirectoryNames.recipes, fileUrlArray )
            didMoveAll = fileUrlArray.count == filesMoved
        }
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didMoveSharedFilesFromDeviceToCloud: didMoveAll, fileUrlArray: fileUrlArray )
            self.processNextRequest()
        }
        
    }
    
    
    private func _saveFileData(_ fileData: Data, filename: String, _ delegate: CloudCentralDelegate ) {
        let     cloudAppRepoUrl    = cloudAppRootUrl.appendingPathComponent( repoDirectory )
        var     didSaveFileData = false
        let     fileFileUrl     = cloudAppRepoUrl.appendingPathComponent( filename )
                    
        do {
            try fileData.write( to: fileFileUrl, options: .atomic )
            
            didSaveFileData = true
            logVerbose( "Saved to file named[ %@ ]", filename )
        }
        
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to write data ... Error[ %@ ]", error.localizedDescription )
        }

        DispatchQueue.main.async {
            delegate.cloudCentral( self, didSaveFileData: didSaveFileData, filename: filename )
            self.processNextRequest()
        }
        
    }
    
    
    private func _startSession(_ delegate: CloudCentralDelegate ) {
        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            documentDirectoryURL = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectoryURL" )
        }
        
        sessionActive = ( fileManager.ubiquityIdentityToken != nil )
        
        logVerbose( "didStartSession[ %@ ]", stringFor( sessionActive ) )
        
        if reEstablishConnection {
            reEstablishConnection = false
            processNextRequest()
        }
        else {
            DispatchQueue.main.async {
                delegate.cloudCentral( self, didStartSession: self.sessionActive )
                self.processNextRequest()
            }
            
        }
        
    }

    
    private func _unlockCloud(_ delegate: CloudCentralDelegate ) {
        var     didUnlockCloud = false
        let     lockFileUrl    = cloudAppRootUrl.appendingPathComponent( Filenames.lockFile )

        if !fileManager.fileExists( atPath: lockFileUrl.path, isDirectory: nil ) {
            didUnlockCloud = true
            logTrace( "ERROR!  Lock file does NOT exist!" )
        }
        else {
            
            do {
                try fileManager.removeItem(at: lockFileUrl )

                didUnlockCloud = true
                logTrace( "Lock file removed" )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  [ %@ ]", error.localizedDescription )
            }
            
        }
        
        DispatchQueue.main.async {
            delegate.cloudCentral( self, didUnlockCloud: didUnlockCloud )
            self.processNextRequest()
        }
        
    }
    
    
    
    // MARK: Session Utility Methods (Private)
    
//     private func compareLastUpdatedFiles() -> (Int, String) {
//         var     compareResult = LastUpdatedFileCompareResult.fileNotFound
//         let     deviceFileUrl = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
//         let     formatter     = DateFormatter()
//         var     updatedBy     = NSLocalizedString( "Title.Unknown", comment: "Unknown" )
//
//         formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//         
//         if fileManager.fileExists( atPath: deviceFileUrl.path ) {
//             
//             if let deviceFileData = fileManager.contents( atPath: deviceFileUrl.path ) {
//                 let     cloudAppRepoUrl     = cloudAppRootUrl.appendingPathComponent( Filenames.lastUpdated )
//                 let     deviceDateString = String( decoding: deviceFileData, as: UTF8.self )
//                 let     deviceComponents = deviceDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
//                 let     deviceDate       = formatter.date( from: deviceComponents[0] )
//
//                 if let cloudFileData = fileManager.contents( atPath: cloudAppRepoUrl.path ) {
//                     let    cloudDateString = String( decoding: cloudFileData, as: UTF8.self )
//                     let    cloudComponents = cloudDateString.components(separatedBy: GlobalConstants.separatorForLastUpdatedString )
//                     let    cloudDate       = formatter.date( from: cloudComponents[0] )
//                     
//                     if let dateOnCloud = cloudDate?.timeIntervalSince1970, let dateOnDevice = deviceDate?.timeIntervalSince1970 {
//                         if dateOnCloud < dateOnDevice {
//                             compareResult = LastUpdatedFileCompareResult.deviceIsNewer
//                         }
//                         else if dateOnDevice < dateOnCloud {
//                             compareResult = LastUpdatedFileCompareResult.cloudIsNewer
//                         }
//                         
//                         if cloudComponents.count == 2 {
//                             updatedBy = cloudComponents[1]
//                         }
//                         
//                     }
//                     else {
//                         logTrace( "ERROR!  Could NOT unwrap dateOnCloud or dateOnDevice!" )
//                     }
//
//                 }
//                 else {
//                     logTrace( "ERROR!  Could NOT unwrap cloudFileData!" )
//                 }
//
//             }
//             else {
//                 logTrace( "ERROR!  Could NOT unwrap deviceFileData!" )
//             }
//             
//         }
//         else {
//             logTrace( "LastUpdated file does NOT Exist on Device" )
//         }
//             
//        return (compareResult, updatedBy)
//    }
    
    
    private func contentsOf(_ sourceUrl: URL ) -> [URL] {
        var fileUrlArray = [URL]()
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: sourceUrl, includingPropertiesForKeys: nil )
            
            fileUrlArray = fileURLs
        }
        
        catch {
            logVerbose("ERROR!  Unable to enumerate files [ %@ ][ %@ ]", sourceUrl.path, error.localizedDescription )
        }

        return fileUrlArray
    }
    
    
    private func copyDatabaseFromCloudToDevice(_ fileUrlArray: [URL] ) -> Bool {
        var     weDoneIt = true
        
        for fileUrl in fileUrlArray {
            let     cloudUrl = cloudAppRootUrl.appendingPathComponent( fileUrl.lastPathComponent )
            
            if let cloudFileData = fileManager.contents( atPath: cloudUrl.path ) {
                
                do {
                    try cloudFileData.write( to: fileUrl, options: .atomic )
                    logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
                    weDoneIt = false
                }
                
            }
            else {
                logVerbose( "ERROR!  Unable to read cloud file [ %@ ] ", cloudUrl.lastPathComponent )
                weDoneIt = false
            }
            
        }
        
        return weDoneIt
    }
    
    
    private func copyDatabaseFromDeviceToCloud(_ fileUrlArray: [URL] ) -> Bool {
        var     index    = 0
        var     weDoneIt = true

        for fileUrl in fileUrlArray {
            if let deviceFileData = fileManager.contents( atPath: fileUrl.path ) {
                let     cloudUrl = cloudAppRootUrl.appendingPathComponent( fileUrl.lastPathComponent )
                
                index += 1

                do {
                    try deviceFileData.write( to: cloudUrl, options: .atomic )
                    logVerbose( "[ %@ ]", cloudUrl.lastPathComponent )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", cloudUrl.lastPathComponent, error.localizedDescription )
                    weDoneIt = false
                }

            }
            else {
                logVerbose( "ERROR!  Unable to read device file[ %@ ] ", fileUrl.lastPathComponent )
                weDoneIt = false
            }

        }
        
      return weDoneIt
    }
    
    
    private func copyFilesFromCloudToDevice(_ targetDirectory: String, _ fileUrlArray: [URL] ) -> Int {
        let     baseDeviceUrl = documentDirectoryURL.appendingPathComponent( targetDirectory )
        var     numberCopied  = 0

        for cloudUrl in fileUrlArray {
            if let cloudFileData = fileManager.contents( atPath: cloudUrl.path ) {
                let deviceFileUrl = baseDeviceUrl.appendingPathComponent( cloudUrl.lastPathComponent )
                
                do {
                    try cloudFileData.write( to: deviceFileUrl, options: .atomic )
                    
                    numberCopied += 1
                    logVerbose( "[ %@ ]", deviceFileUrl.lastPathComponent )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", deviceFileUrl.lastPathComponent, error.localizedDescription )
                }
                
            }
            else {
                logVerbose( "ERROR!  Unable to read cloud file [ %@ ]", cloudUrl.lastPathComponent )
            }
            
        }
        
        logVerbose( "copied %d of %d files to %@ directory", numberCopied, fileUrlArray.count, targetDirectory )
        
        return numberCopied
    }
    
    
    private func copyFilesFromDeviceToCloud(_ targetDirectory: String, _ fileUrlArray: [URL] ) -> Int {
        let     baseCloudUrl = cloudAppRootUrl.appendingPathComponent( targetDirectory )
        var     numberCopied = 0

        for deviceFileUrl in fileUrlArray {
            if let deviceFileData = fileManager.contents( atPath: deviceFileUrl.path ) {
                let cloudFileUrl = baseCloudUrl.appendingPathComponent( deviceFileUrl.lastPathComponent )
                
                do {
                    try deviceFileData.write( to: cloudFileUrl, options: .atomic )
                    
                    numberCopied += 1
                    logVerbose( "[ %@ ]", deviceFileUrl.lastPathComponent )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  [ %@ ] -> [ %@ ]", deviceFileUrl.lastPathComponent, error.localizedDescription )
                }
                
            }
            else {
                logVerbose( "ERROR!  Unable to read cloud file [ %@ ]", deviceFileUrl.lastPathComponent )
            }
            
        }
        
        logVerbose( "copied %d of %d files to %@ directory", numberCopied, fileUrlArray.count, targetDirectory )
        
        return numberCopied
    }
    
    
    private func createLockFile() {
        let     lockFileUrl     = cloudAppRootUrl.appendingPathComponent( Filenames.lockFile )
        let     thisDeviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     lockMessage     = String( format: "%@,%@", deviceName, thisDeviceId )
        let     fileData        = Data( lockMessage.utf8 )
        
        do {
            try fileData.write( to: lockFileUrl )
            
            deviceAccessControl.byMe      = true
            deviceAccessControl.ownerName = deviceName
            logVerbose( "Created lock file ... %@", deviceAccessControl.descriptor() )
        }
        catch let error as NSError {
            deviceAccessControl.ownerName = "Unknown"
            logVerbose( "ERROR!!!  Lock file create failed! ... [ %@ ]", error.localizedDescription )
        }

    }
    
    
    private func databaseUrlArrayForCloud(_ cloud: Bool ) -> [URL] {
        logTrace()
        let baseUrl      = cloud ? cloudAppRootUrl : documentDirectoryURL
        var fileUrlArray = [URL]()

        for filename in Constants.databaseFilenameArray {
            let     fileUrl = baseUrl.appendingPathComponent( filename )
            
            fileUrlArray.append( fileUrl )
//            logVerbose( "[ %@ ]", fileUrl.path )
        }
        
        return fileUrlArray
    }
        
    
    private func deleteFiles(_ urlArray: [URL] ) {
        var numberDeleted = 0
        
        for fileUrl in urlArray {
            do {
                if fileManager.fileExists(atPath: fileUrl.path ) {
                    try fileManager.removeItem( at: fileUrl )
                    
                    numberDeleted += 1
                    logVerbose( "[ %@ ]", fileUrl.lastPathComponent )
                }
                else {
                    logVerbose( "[ %@ ] Does NOT Exist", fileUrl.lastPathComponent )
                }
                
            }
            catch let error as NSError {
                logVerbose( "Error: [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
            }
            
        }
        
        logVerbose( "deleted %d of %d files", numberDeleted, urlArray.count )
    }
    
    
    private func sharedFilesUrlArray() -> [URL] {
        logTrace()
        var     filenameArray = [String]()
        var     fileUrlArray  = [URL]()
        
        if !fileManager.fileExists( atPath: documentDirectoryURL.path ) {
            logVerbose( "Document directory does NOT exist!\n    [ %@ ] ", documentDirectoryURL.path )
            return fileUrlArray
        }
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: documentDirectoryURL.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files and the Library folder
                if startingString == "." || filename == "Library" || filename.contains( "sqlite" ) {
                    continue
                }
                
                // Filter out databases and directories
                let     fileUrl      = documentDirectoryURL.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if fileManager.fileExists( atPath: fileUrl.path, isDirectory: &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        fileUrlArray.append( fileUrl )
                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
        return fileUrlArray
    }
    
        
}



