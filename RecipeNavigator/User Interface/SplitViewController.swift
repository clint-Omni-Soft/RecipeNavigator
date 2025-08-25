//
//  SplitViewController.swift
//  RecipeNavigator
//
//  Created by Clint Shank on 7/28/25.
//

import UIKit

class SplitViewController: UISplitViewController {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // MARK: UIViewController Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        logTrace()
        
        appDelegate.splitViewController = self
        appDelegate.configureSplitViewController()
    }
    

}
