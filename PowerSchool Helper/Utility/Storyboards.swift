//
//  Storyboards.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/12/23.
//

import UIKit

class Storyboards {
    public static let shared = Storyboards()
    public let classInfoStoryboard =  UIStoryboard(name: "ClassInfo", bundle: nil)
    public let classListStoryboard = UIStoryboard(name: "ClassList", bundle: nil)
    public let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
    public let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
    public let helpStoryboard = UIStoryboard(name: "Help", bundle: nil)
    public let assignmentsStoryboard = UIStoryboard(name: "Assignments", bundle: nil)
    public let orderStoryboard = UIStoryboard(name: "Order", bundle: nil)
    public let studentInfoStoryboard = UIStoryboard(name: "StudentInfo", bundle: nil)

    
    public func loginViewController() -> LoginViewController? {
        return loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
    }
    public func classInfoViewController() -> ClassInfoController? {
        return classInfoStoryboard.instantiateViewController(withIdentifier: "ClassInfoController") as? ClassInfoController
    }
    public func settingsViewController() -> SettingsCategoryViewController? {
        return settingsStoryboard.instantiateViewController(withIdentifier: "SettingsCategoryViewController") as? SettingsCategoryViewController
    }
    public func classListViewController() -> ClassListViewController? {
        return classListStoryboard.instantiateViewController(withIdentifier: "ClassListViewController") as? ClassListViewController
    }
    public func classInfoTabbarController() -> ClassInfoTabBarController? {
        return classInfoStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? ClassInfoTabBarController
    }
    public func classListTabbarController() -> MainTabBar? {
        return classListStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? MainTabBar
    }
    public func orderViewController() -> OrderViewController? {
        return classListStoryboard.instantiateViewController(withIdentifier: "OrderViewController") as? OrderViewController
    }
    public func termSelectionViewController() -> QuarterSelectionController? {
        return orderStoryboard.instantiateViewController(withIdentifier: "QuarterSelectionController") as? QuarterSelectionController
    }
    public func assignmentCalculatorViewController() -> AssignmentCalculatorViewController? {
        return assignmentsStoryboard.instantiateViewController(withIdentifier: "AssignmentCalculatorViewController") as? AssignmentCalculatorViewController
    }
    public func assignmentDetailViewController() -> AssignmentDetailViewController? {
        return assignmentsStoryboard.instantiateViewController(withIdentifier: "AssignmentDetailViewController") as? AssignmentDetailViewController
    }
    public func assignmentViewController() -> AssignmentViewController? {
        return assignmentsStoryboard.instantiateViewController(identifier: "AssignmentViewController") as? AssignmentViewController
    }
    public func repeatViewController() -> RepeatViewController? {
        return settingsStoryboard.instantiateViewController(identifier: "RepeatViewController") as? RepeatViewController
    }
    public func helpViewController() -> HelpViewController? {
        return helpStoryboard.instantiateViewController(identifier: "HelpViewController") as? HelpViewController
    }
    public func studentInfoVC() -> StudentInfoViewController? {
        return studentInfoStoryboard.instantiateViewController(identifier: "StudentInfoViewController") as? StudentInfoViewController
    }
    public func classSettingsViewController() -> ClassSettingsViewController? {
        return classInfoStoryboard.instantiateViewController(identifier: "ClassSettingsViewController") as? ClassSettingsViewController
    }
    public func googleSigninViewController() -> GoogleSignInViewController? {
        return loginStoryboard.instantiateViewController(identifier: "GoogleSignInViewController") as? GoogleSignInViewController
    }
}
