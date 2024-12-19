//
//  DataSourceCentral.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 10/24/24.
//

import UIKit


protocol DataSourceCentralDelegate: AnyObject {
    func dataSourceCentral(_ dataSourceCentral: DataSourceCentral, didFetch: Bool, data: Data, from recipe: Recipe )
}


// Now we provide a default implementation which makes them all optional
extension DataSourceCentralDelegate {
    func dataSourceCentral(_ dataSourceCentral: DataSourceCentral, didFetch: Bool, data: Data, from recipe: Recipe ) {}
}



class DataSourceCentral: NSObject {
    
    // MARK: Private Variables & Definitions
    
    private var connectedShare      : SMBShare!
    private var delegate            : DataSourceCentralDelegate!
    private var deviceDocumentUrl   = URL.init( fileURLWithPath: "" )
    private var deviceRepoUrl       = URL.init( fileURLWithPath: "" )
    private var deviceViewerDataUrl = URL.init( fileURLWithPath: "" )
    private let fileManager         = FileManager.default
    private let nasCentral          = NASCentral.sharedInstance
    private let navigatorCentral    = NavigatorCentral.sharedInstance
    private var recipe              : Recipe!
    private let userDefaults        = UserDefaults.standard

        
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = DataSourceCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: Public Interfaces (Viewer Data)
    
    func requestViewerDataFor(_ recipe: Recipe, _ delegate: DataSourceCentralDelegate ) {
        if !deviceUrlsHaveBeenSet() {
            return
        }
        
        logTrace()
        if navigatorCentral.dataSourceLocation == .device {
            let fetchRequestTuple = fetchFromDeviceRepo( recipe.filename! )
            
            delegate.dataSourceCentral( self, didFetch: fetchRequestTuple.0, data: fetchRequestTuple.1, from: recipe )
        }
        else {  // Must be NAS
            self.delegate = delegate
            self.recipe   = recipe
            
            nasCentral.canSeeNasDataSourceFolders( self )
        }

    }
    
    
    func removeViewerDataFile(_ filename: String ) {
        if !deviceUrlsHaveBeenSet() {
            return
        }
        
        let fileDataURL  = deviceViewerDataUrl.appendingPathComponent( filename )
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
    
    
    func saveViewerDataFileFrom(_ recipe: Recipe, _ fileData: Data ) {
        if !deviceUrlsHaveBeenSet() {
            return
        }
        
        let fileDataURL  = deviceViewerDataUrl.appendingPathComponent( recipe.filename! )
        let fileDataPath = fileDataURL.path + GlobalConstants.dataFileExtension
        
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

    

    // MARK: Device Methods
    
    func removeFromDeviceRepo(_ filename: String ) {        // When on device we allow the user to delete files from the repo, but ONLY when on the device
        if !deviceUrlsHaveBeenSet() {
            return
        }
        
        logTrace()
        let fileURL = deviceRepoUrl.appendingPathComponent( filename )

        if fileManager.fileExists(atPath: fileURL.path ) {
            do {
                try fileManager.removeItem(atPath: fileURL.path )
                logVerbose( "Removed [ %@ ]", filename )
            }

            catch let error as NSError {
                logVerbose( "ERROR!  Failed to delete data for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }

        }
        
    }
    
    
    func scanDeviceRepo() -> [FileDescriptor] {
        if !deviceUrlsHaveBeenSet() {
            return []
        }
        
        logTrace()
        var contentsArray = [FileDescriptor]()
        var filenameArray = [String]()

        relocateDeviceDocumentDirectoryRecipes()
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: deviceRepoUrl.path )
            
            for filename in filenameArray {
                let fileExtension = extensionFrom( filename )
                
                if !fileExtension.isEmpty &&  GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                    let fileUrl = deviceRepoUrl.appendingPathComponent( filename )
                    
                    contentsArray.append( FileDescriptor.init( filename, "", fileUrl, DescriptorFileTypes.other ) )
                }
                
            }
            
            contentsArray = contentsArray.sorted(by:
            { fileDescriptor1, fileDescriptor2 in
                return fileDescriptor1.name < fileDescriptor2.name
            })
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
        return contentsArray
    }
    
    

    // MARK: Device Utility Methods
    
    private func deviceUrlsHaveBeenSet() -> Bool {
        logTrace()
        if deviceDocumentUrl.path == "/" {
            if let documentUrl = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
                if let repoDirectory = userDefaults.string( forKey: UserDefaultKeys.repoDirectory ) {
                    deviceDocumentUrl   = documentUrl
                    deviceRepoUrl       = documentUrl.appendingPathComponent( repoDirectory )
                    deviceViewerDataUrl = documentUrl.appendingPathComponent( DirectoryNames.viewerData )
                }
                else {
                    logTrace( "ERROR:  Unable to load repoDirectory URL" )
                    return false
                }
                
            }
            else {
                logTrace( "ERROR:  Unable to load documentDirectory URL" )
                return false
            }

        }
        
        return true
    }
    
    
    private func fetchFromDeviceDocumentDirectory(_ filename: String ) -> (Bool, Data) {
        logTrace()
        var didFetchData = false
        var fetchedData  = Data.init()

        if let url = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let fileUrl = url.appendingPathComponent( filename )
            
            do {
                try fetchedData = Data(contentsOf: fileUrl )
                
                didFetchData = true
            }
            
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to read [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }
            
        }

        return ( didFetchData, fetchedData )
    }
    

    private func fetchFromDeviceRepo(_ filename: String ) -> (Bool, Data) {
        logTrace()
        var didFetchData = false
        var fetchedData  = Data()
        let fileUrl      = deviceRepoUrl.appendingPathComponent( filename )
        
        do {
            try fetchedData = Data( contentsOf: fileUrl )
            
            didFetchData = true
        }
        
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to read [ %@ ] ... Error[ %@ ]", fileUrl.path, error.localizedDescription )
        }
        
        return ( didFetchData, fetchedData )
    }
    

    private func relocateDeviceDocumentDirectoryRecipes() {
        logTrace()
        var filenameArray = [String]()
        
        do {
            try filenameArray = fileManager.contentsOfDirectory( atPath: deviceDocumentUrl.path )
            
//            logTrace()
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1)
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Don't show hidden files, database, Logs or the Library folder
                if startingString == "." || filename == "Library" || filename == "Logs" || filename.contains( "sqlite" ) {
                    continue
                }
                
                let fileExtension = extensionFrom( filename )
                
                if !fileExtension.isEmpty &&  GlobalConstants.supportedFilenameExtensions.contains( fileExtension ) {
                    let readResultTuple = fetchFromDeviceDocumentDirectory( filename )

                    if readResultTuple.0 {
                        let targetUrl = deviceRepoUrl.appendingPathComponent( filename )
                        
                        do {
                            try readResultTuple.1.write(to: targetUrl )
                            
                            if removeFromDeviceDocumentDirectory( filename ) {
                                logVerbose( "[ %@ ]", filename )
                            }
                            
                        }
                        
                        catch let error as NSError {
                            logVerbose( "Error: [ %@ ]", error )
                        }

                    }
                    
                }
                
            }
            
        }
        
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
        return
    }
    
    
    private func removeFromDeviceDocumentDirectory(_ filename: String ) -> Bool {
        logTrace()
        let fileUrl = deviceDocumentUrl.appendingPathComponent( filename )
        var result  = true

        if fileManager.fileExists(atPath: fileUrl.path ) {
            do {
                try fileManager.removeItem(atPath: fileUrl.path )
                logVerbose( "Removed [ %@ ]", filename )
            }

            catch let error as NSError {
                logVerbose( "ERROR!  Failed to delete data for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
                result = false
            }

        }
        
        return result
    }
    
    
}



// MARK: NASCentralDelegate Methods

extension DataSourceCentral: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasDataSourceFolders: Bool) {
        if navigatorCentral.stayOffline {
            logVerbose( "[ %@ ]  Stay Offline!", stringFor( canSeeNasDataSourceFolders ) )
            return
        }
        
        logVerbose( "[ %@ ]", stringFor( canSeeNasDataSourceFolders ) )
        
        if canSeeNasDataSourceFolders {
            nasCentral.startDataSourceSession( self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetchFile: Bool, _ data: Data ) {
        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        if didFetchFile {
            delegate?.dataSourceCentral( self, didFetch: true, data: data, from: recipe )
        }
        else {
            delegate?.dataSourceCentral( self, didFetch: false, data: Data.init(), from: recipe )
        }
        
    }

    
    func nasCentral(_ nasCentral: NASCentral, didOpenShare: Bool, _ share: SMBShare) {
        logVerbose( "[ %@ ]", stringFor( didOpenShare ) )
        if didOpenShare {
            var filePathAndName = ""
            
            if let relativePath = recipe.relativePath, let filename = recipe.filename {
                filePathAndName = relativePath + "/" + filename
            }

            nasCentral.fetchFileOn( connectedShare, filePathAndName, self )
        }
        else {
            delegate?.dataSourceCentral( self, didFetch: false, data: Data.init(), from: recipe )
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartDataSourceSession: Bool, share: SMBShare ) {
        logVerbose( "[ %@ ]", stringFor( didStartDataSourceSession ) )

        if didStartDataSourceSession {
            connectedShare = share
            nasCentral.openShare( share, self )
        }
        else {
            delegate?.dataSourceCentral( self, didFetch: false, data: Data.init(), from: recipe )
        }
        
    }
    
    
}
