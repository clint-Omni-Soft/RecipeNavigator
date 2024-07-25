//
//  TransferProgressViewController.swift
//  WineStock
//
//  Created by Clint Shank on 3/17/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class TransferProgressViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var pleaseWaitLabel   : UILabel!
    @IBOutlet weak var titleLabel        : UILabel!


    
    // MARK: Private Variables
    
    private let navigatorCentral = NavigatorCentral.sharedInstance
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        pleaseWaitLabel.text = NSLocalizedString( "LabelText.PleaseWait",    comment: "This may take a few minutes.\nPlease wait..." )
        titleLabel     .text = NSLocalizedString( "Title.TransferringFiles", comment: "Transferring files" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        activityIndicator.startAnimating()
        
        if navigatorCentral.dataStoreLocation == .iCloud || navigatorCentral.dataStoreLocation == .shareCloud {
            CloudCentral.sharedInstance.startSession( self )
        }
        else {
            NASCentral.sharedInstance.startSession( self )
        }
        
    }
    
    
    
    // MARK: Utility Methods
    
    private func presentReadyToRestartPrompt() {
        let     alert = UIAlertController.init( title:   NSLocalizedString( "AlertTitle.TransferComplete", comment: "Transfer Complete!" ),
                                                message: NSLocalizedString( "AlertMessage.ReadyToRestart", comment: "Ready to Restart"   ), preferredStyle: .alert )

        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "OK Action" )
            
            exit( 0 )
        }

        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}



// MARK: CloudCentralDelegate Methods

extension TransferProgressViewController : CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromCloudToDevice: Bool) {
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromCloudToDevice ) )
        cloudCentral.endSession( self )
    }


    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromDeviceToCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromDeviceToCloud ) )
        cloudCentral.endSession( self )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToCloud ) )
        
        if didCopyDatabaseFromDeviceToCloud {
            cloudCentral.copyAllImagesFromDeviceToCloud( self )
        }
        else {
            cloudCentral.endSession( self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice: Bool) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromCloudToDevice ) )

        if didCopyDatabaseFromCloudToDevice {
            cloudCentral.copyAllImagesFromCloudToDevice( self )
        }
        else {
            cloudCentral.endSession( self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession: Bool) {
        logVerbose( "[ %@ ] ... ready to exit", stringFor( didEndSession ) )
        
        DispatchQueue.main.asyncAfter( deadline: .now() + 1.0 ) {
            self.presentReadyToRestartPrompt()
        }

    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession: Bool) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if navigatorCentral.dataStoreLocation == .iCloud {
            cloudCentral.copyDatabaseFromDeviceToCloud( self )
        }
        else {
            let _ = navigatorCentral.imageExistsWith( "BogusName" ) // This will create the pictures sub-Directory
            
            cloudCentral.copyDatabaseFromCloudToDevice( self )
        }
        
    }
    
    
}



// MARK: NASCentralDelegate Session Methods

extension TransferProgressViewController : NASCentralDelegate {
        
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromDeviceToNas : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromDeviceToNas ) )
        nasCentral.unlockNas( self )
    }
    
    
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromNasToDevice : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyAllImagesFromNasToDevice ) )
        nasCentral.unlockNas( self )
    }
    
    
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromDeviceToNas : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToNas ) )

        if didCopyDatabaseFromDeviceToNas {
            nasCentral.copyAllImagesFromDeviceToNas( self )
        }
        else {
            nasCentral.endSession( self )
        }
        
    }

    
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromNasToDevice : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromNasToDevice ) )

        if didCopyDatabaseFromNasToDevice {
            nasCentral.copyAllImagesFromNasToDevice( self )
        }
        else {
            nasCentral.endSession( self )
        }
        
    }

    
    func nasCentral(_ nasCentral: NASCentral, didEndSession: Bool) {
        logVerbose( "[ %@ ] ... ready to exit", stringFor( didEndSession ) )
        
        DispatchQueue.main.asyncAfter( deadline: .now() + 1.0 ) {
            self.presentReadyToRestartPrompt()
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didStartSession: Bool) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if navigatorCentral.dataStoreLocation == .nas {
            nasCentral.copyDatabaseFromDeviceToNas( self )
        }
        else {
            let _ = navigatorCentral.imageExistsWith( "BogusName" ) // This will create the pictures sub-Directory
            
            nasCentral.copyDatabaseFromNasToDevice( self )
        }
        
    }

    
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas: Bool) {
        logVerbose( "[ %@ ]", stringFor( didUnlockNas ) )
        nasCentral.endSession( self )
    }
    
    
}

