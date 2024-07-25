//
//  ViewerRecipes+CoreDataProperties.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 5/23/24.
//
//

import Foundation
import CoreData


extension ViewerRecipes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ViewerRecipes> {
        return NSFetchRequest<ViewerRecipes>(entityName: "ViewerRecipes")
    }

    @NSManaged public var recipes: NSSet?

}

// MARK: Generated accessors for recipes
extension ViewerRecipes {

    @objc(addRecipesObject:)
    @NSManaged public func addToRecipes(_ value: Recipe)

    @objc(removeRecipesObject:)
    @NSManaged public func removeFromRecipes(_ value: Recipe)

    @objc(addRecipes:)
    @NSManaged public func addToRecipes(_ values: NSSet)

    @objc(removeRecipes:)
    @NSManaged public func removeFromRecipes(_ values: NSSet)

}

extension ViewerRecipes : Identifiable {

}
