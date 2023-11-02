//
//  AccountManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/12/23.
//

import UIKit
import RealmSwift


class AccountManager {
    public static let global = AccountManager()
    public var username: String = ""
    public var password: String = ""
    public var updatedClasses: [String] = []
    public var classIndexToUpdate = 0
    public var selectedQuarter = 1
    
    public var selectedClass = ""
    public var selectedhref = ""
    public var classType = ClassType(username: "", className: "", quarter: 1, href: "")
    public var assignments: List<Assignments> = List<Assignments>()
    public var updateClassLabelsOnLoad = false
}
