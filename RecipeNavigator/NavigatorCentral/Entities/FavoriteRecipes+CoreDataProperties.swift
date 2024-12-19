//
//  FavoriteRecipes+CoreDataProperties.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 10/23/24.
//
//

import Foundation
import CoreData


extension FavoriteRecipes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteRecipes> {
        return NSFetchRequest<FavoriteRecipes>(entityName: "FavoriteRecipes")
    }

    @NSManaged public var recipes: NSSet?

}

// MARK: Generated accessors for recipes
extension FavoriteRecipes {

    @objc(addRecipesObject:)
    @NSManaged public func addToRecipes(_ value: Recipe)

    @objc(removeRecipesObject:)
    @NSManaged public func removeFromRecipes(_ value: Recipe)

    @objc(addRecipes:)
    @NSManaged public func addToRecipes(_ values: NSSet)

    @objc(removeRecipes:)
    @NSManaged public func removeFromRecipes(_ values: NSSet)

}

extension FavoriteRecipes : Identifiable {

}
