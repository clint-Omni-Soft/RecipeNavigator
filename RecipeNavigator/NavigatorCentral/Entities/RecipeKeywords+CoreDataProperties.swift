//
//  RecipeKeywords+CoreDataProperties.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 6/21/24.
//
//

import Foundation
import CoreData


extension RecipeKeywords {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecipeKeywords> {
        return NSFetchRequest<RecipeKeywords>(entityName: "RecipeKeywords")
    }

    @NSManaged public var keywords: String?

}

extension RecipeKeywords : Identifiable {

}
