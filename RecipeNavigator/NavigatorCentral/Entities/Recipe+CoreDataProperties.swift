//
//  Recipe+CoreDataProperties.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 5/23/24.
//
//

import Foundation
import CoreData


extension Recipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: "Recipe")
    }

    @NSManaged public var filename: String?
    @NSManaged public var guid: String?
    @NSManaged public var keywords: String?
    @NSManaged public var relativePath: String?
    @NSManaged public var viewerRecipe: ViewerRecipes?

}

extension Recipe : Identifiable {

}
