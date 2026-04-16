//
//  FinderViewController.swift
//  WineStock
//
//  Created by Clint Shank on 3/09/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import CloudKit

class FinderViewController: UIViewController {
    
    // MARK: Public Variables
    
    var startingUrl : URL!      // Set by our parent
    

    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: Private Variables
    
    private let cellID = "FinderViewControllerCell"
    
    private var directoryContentsArray = [FileDescriptor].init()
    private let fileManager            = FileManager.default
    private var networkPath            = ""
    private var rootUrl                = URL.init( fileURLWithPath: "" )
    private var upBarButtonItem        : UIBarButtonItem!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = "Select Path"

        if let path = UserDefaults.standard.string( forKey: UserDefaultKeys.networkPath ) {
            networkPath = path
        }

        
        // TODO: Undo the if runningInSimulator()
//        if runningInSimulator() {

            if let url = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                rootUrl     = url
                startingUrl = url
            }

//        }
//        else {
//            rootUrl = startingUrl
//        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadDirectoryContentsArray()
        loadBarButtonItems()
        
        myTableView.reloadData()
        
        listMountedVolumes()
    }
    
    

    // MARK: Target/Action Methods
    
//    @IBAction func organizeBarButtonItemTouched( sender : UIBarButtonItem ) {
//        var accountState    = "???"
//        var containerStatus = "is NOT"
//        var tokenStatus     = "is NOT"
//
//        if let _ = fileManager.ubiquityIdentityToken {
//            tokenStatus = "IS"
//        }
//
//        if let _ = fileManager.url( forUbiquityContainerIdentifier: nil ) {
//            containerStatus = "IS"
//        }
//
//        CKContainer.default().accountStatus { (accountStatus, error) in
//            if error == nil {
//                switch accountStatus {
//                case .available:            accountState = "Available"
//                case .noAccount:            accountState = "No account"
//                case .restricted:           accountState = "Restricted"
//                case .couldNotDetermine:    accountState = "Unable to determine status"
//                default:                    accountState = "<Undefined>"
//                }
//
//            }
//            else {
//                let myError = error! as NSError
//                accountState = myError.localizedDescription
//            }
//            
//            logVerbose( "\n    [ token URL %@ available ][ container URL %@ available ][ account state - %@ ]", tokenStatus, containerStatus, accountState )
//        }
//
//    }
    
    
    @IBAction func upBarButtonItemTouched( sender : UIBarButtonItem ) {
        logTrace()
        startingUrl = startingUrl.deletingLastPathComponent()
        
        loadDirectoryContentsArray()
        loadBarButtonItems()

        myTableView.reloadData()
    }
    

    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
        logTrace()
        configureBackBarButtonItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .reply, target: self, action: #selector( upBarButtonItemTouched ) )
    }
    
    
    private func listMountedVolumes() {
        let keys  : [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
        let paths = FileManager.default.mountedVolumeURLs( includingResourceValuesForKeys: keys, options: [] )      // This only works for MacOS
        
        logTrace()
        if let urls = paths {
            
            for url in urls {
                let components = url.pathComponents
                
                if ( components.count > 1 ) && ( components[1] == "Volumes" ) {
                    logVerbose( "[ %@ ]", url.path )
                }
                
            }
            
        }
        
    }
    
    
    private func loadDirectoryContentsArray() {
        var     contentsArray = [FileDescriptor].init()
        var     filenameArray = [String].init()
        
        do {
            try filenameArray = FileManager.default.contentsOfDirectory( atPath: startingUrl.path )
            
//            logTrace()
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1)
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Don't show hidden files or the Library folder
                if startingString == "." || filename == "Library" {
                    continue
                }
                
                // Flag databases and directories
                var     fileType     = DescriptorFileTypes.other
                let     fileUrl      = startingUrl.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if FileManager.default.fileExists( atPath: fileUrl.path, isDirectory : &isaDirectory ) {
                    if isaDirectory.boolValue {
                        let     storeContentUrl = fileUrl.appendingPathComponent( "StoreContent" )
                        
                        fileType = FileManager.default.fileExists( atPath: storeContentUrl.path ) ? .database : .directory
                    }

                }
                
                contentsArray.append( FileDescriptor.init( filename, startingUrl.path, fileUrl, fileType ) )
            }

        }
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
        directoryContentsArray = contentsArray
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension FinderViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = directoryContentsArray.count

        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     cell       = tableView.dequeueReusableCell(withIdentifier: cellID ) ?? UITableViewCell.init()
        let     descriptor = directoryContentsArray[indexPath.row]
        
        cell.textLabel?.text      = descriptor.name
        cell.textLabel?.textColor = ( descriptor.type == .directory ) ? .blue : .black
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension FinderViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let     descriptor = directoryContentsArray[indexPath.row]

        tableView.deselectRow(at: indexPath, animated: false )
        
        if descriptor.type == .directory {
            startingUrl = descriptor.url
            
            loadDirectoryContentsArray()
            loadBarButtonItems()
            
            tableView.reloadData()
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let     currentPath = startingUrl.path
        let     headerView  = UITableViewHeaderFooterView.init()
        var     title       = "root"
        
        if currentPath != rootUrl.path {
            let     index     = currentPath.index( currentPath.startIndex, offsetBy: rootUrl.path.lengthOfBytes( using: .utf8 ) )
            let     substring = currentPath.suffix( from: index )

            title = String( substring )
        }
        
        headerView.textLabel?.text       = String( format: "Path = %@", title )
        headerView.contentView.tintColor = .gray
        
        return headerView
    }

    
}



