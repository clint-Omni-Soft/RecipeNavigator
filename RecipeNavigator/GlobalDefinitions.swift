//
//  GlobalDefinitions.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 7/22/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


// MARK: Public Variables & Definitions

enum DataLocation {
    case device
    case iCloud
    case nas
    case notAssigned
    case shareCloud
    case shareNas
}

struct DataLocationName {
    static let device       = "device"
    static let iCloud       = "iCloud"
    static let nas          = "nas"
    static let notAssigned  = "notAssigned"
    static let shareCloud   = "shareCloud"
    static let shareNas     = "shareNas"
}

struct DirectoryNames {
    static let root       = "RecipeNavigator"
    static let pictures   = "Photos"
    static let viewerData = "ViewerData"
}

struct EntityNames {
    static let imageRequest   = "ImageRequest"
    static let recipe         = "Recipe"
    static let recipeKeywords = "RecipeKeywords"
    static let viewerRecipes  = "ViewerRecipes"
}

struct Filenames {
    static let database    = "RecipeNavigatorDB.sqlite"
    static let databaseShm = "RecipeNavigatorDB.sqlite-shm"
    static let databaseWal = "RecipeNavigatorDB.sqlite-wal"
    static let exportedCsv = "RecipeNavigator.csv"
    static let lastUpdated = "LastUpdated"
    static let lockFile    = "LockFile"
}

struct GlobalConstants {
    static let dataFileExtension                = ".dat"
    static let fileExtensionSeparator           = "."
    static let filePathSeparator                = "/"
    static let groupedTableViewBackgroundColor  = UIColor.init( red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0 )
    static let newRecipe                        = -1
    static let noGuid                           = "No GUID"
    static let noSelection                      = -1
    static let notSet                           = Int16( -4 )
    static let lightBlueColor                   = UIColor.init( red: 153/255, green: 204/255, blue: 255/255, alpha: 1.0 )
    static let offlineColor                     = UIColor.init( red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0 )
    static let onlineColor                      = UIColor.init( red: 204/255, green: 255/255, blue: 204/255, alpha: 1.0 )
    static let paleYellowColor                  = UIColor.init( red: 255/255, green: 255/255, blue: 204/255, alpha: 1.0 )
    static let separatorForLastUpdatedString    = ","
    static let separatorForLockfileString       = ","
    static let separatorForRecipeKeywordString  = ","
    static let separatorForSorts                = ";"
    static let sortAscending                    = "↑"    // "▴"
    static let sortAscendingFlag                = "A"
    static let sortDescending                   = "↓"    // "▾"
    static let sortDescendingFlag               = "D"
    static let supportedFilenameExtensions      = ["JPG", "JPEG", "HTM", "HTML", "PDF", "PNG", "RTF", "TXT"]    //, "DOC", "DOCX" ]
}

struct GlobalIndexPaths {
    static let newRecipe   = IndexPath(row: GlobalConstants.newRecipe,   section: GlobalConstants.newRecipe  )
    static let noSelection = IndexPath(row: GlobalConstants.noSelection, section: GlobalConstants.noSelection )
}

struct FileMimeTypes {
    static let html = "text/html"
    static let jpg  = "image/jpeg"
    static let pdf  = "application/pdf"
    static let png  = "image/png"
    static let rtf  = "text/richtext" // Also defined as "application/x-rtf" or "application/rtf"
    static let txt  = "text/plain"
//    static let doc  = "application/msword"
//    static let docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
}

struct Notifications {
    static let cannotReadAllDbFiles         = "CannotReadAllDbFiles"
    static let cannotSeeExternalDevice      = "CannotSeeExternalDevice"
    static let connectingToExternalDevice   = "ConnectingToExternalDevice"
    static let deviceNameNotSet             = "DeviceNameNotSet"
    static let enteringBackground           = "EnteringBackground"
    static let enteringForeground           = "EnteringForeground"
    static let externalDeviceLocked         = "ExternalDeviceLocked"
    static let recipeArrayReloaded          = "RecipeArrayReloaded"
    static let ready                        = "Ready"
    static let repoScanRequested            = "RepoScanRequested"
    static let transferringDatabase         = "TransferringDatabase"
    static let unableToConnect              = "UnableToConnect"
    static let updatingExternalDevice       = "UpdatingExternalDevice"
    static let viewerRecipesArrayReloaded   = "ViewerRecipesArrayReloaded"
}

struct SortOptions {
    static let byFilename     = "byFilename"
    static let byKeywords     = "byKeywords"
    static let byRelativePath = "byRelativePath"
}


struct SortOptionNames {
    static let byFilename     = NSLocalizedString( "SortOption.Filename",     comment: "Filename"      )
    static let byKeywords     = NSLocalizedString( "SortOption.Keywords",     comment: "Keywords"      )
    static let byRelativePath = NSLocalizedString( "SortOption.RelativePath", comment: "Relative Path" )
}

struct SupportedFilenameExtensions {
    static let jpg  = GlobalConstants.supportedFilenameExtensions[0]
    static let jpeg = GlobalConstants.supportedFilenameExtensions[1]
    static let htm  = GlobalConstants.supportedFilenameExtensions[2]
    static let html = GlobalConstants.supportedFilenameExtensions[3]
    static let pdf  = GlobalConstants.supportedFilenameExtensions[4]
    static let png  = GlobalConstants.supportedFilenameExtensions[5]
    static let rtf  = GlobalConstants.supportedFilenameExtensions[6]
    static let txt  = GlobalConstants.supportedFilenameExtensions[7]
//    static let doc  = GlobalConstants.supportedFilenameExtensions[8]
//    static let docx = GlobalConstants.supportedFilenameExtensions[9]
}

struct UserDefaultKeys {
    static let currentSortOption        = "CurrentSortOption"
    static let dataSourceDescriptor     = "DataSourceDescriptor"
    static let dataSourceLocation       = "DataSourceLocation"
    static let dataStoreDescriptor      = "DataStoreDescriptor"
    static let dataStoreLocation        = "DataStoreLocation"
    static let deviceName               = "DeviceName"
    static let dontRemindMeAgain        = "DontRemindMeAgain"
    static let howToUseShown            = "HowToUseShown"
    static let lastAccessedRecipesGuid  = "LastAccessedPinsGuid"
    static let lastTabSelected          = "LastTabSelected"
    static let networkPath              = "NetworkPath"
    static let networkAccessGranted     = "NetworkAccessGranted"
    static let updatedOffline           = "UpdatedOffline"
}

