//
//  ClassManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/25/22.
//

import UIKit
import RealmSwift

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) var realm: Realm?
    
    enum StudentDataOptions: String {
        case username
        case firstName
        case lastName
        case lastReportDate
    }
    
    enum ClassDataOptions: String {
        case className
        case quarter
        case href
        case grade
        case weightedGrade
        case teacher
        case received
        case total
        case assignments
        case letterGrade
        case needPointsPercent
        case needPointsLetter
        case detailedGrade
        case credits
        case placement
        case reportGrade
        case reportPointsEarned
        case reportPointsTotal
        case reportAssignments
    }
    
    
    func initizialeSchema(username: String) {
    
        var config = Realm.Configuration(schemaVersion: 4)
        Realm.Configuration.defaultConfiguration = config
        do {
            config.fileURL?.deleteLastPathComponent()
            config.fileURL?.appendPathComponent(username)
            config.fileURL?.appendPathExtension("realm")
    
            realm = try Realm(configuration: config)
            getLocation()
        } catch {
            print("FAILED TO INITIALZE REALM DATABASE: \(error.localizedDescription)")
        }
    }
    
    func getLocation() {
        print(realm!.configuration.fileURL ?? "COULD NOT FIND REALM DATABASE LOCATION")
    }
    
    func addStudentToDatabase(username: String) {
        if checkIfStudentExists(username: username) {return}
        
        do {
            try realm?.write() {
                realm?.add(PowerschoolAccount(username: username))
            }
        } catch {
            print("FAILED TO ADD STUDENT: \(error.localizedDescription)")
        }
    }
    
    func checkIfStudentExists(username:String) -> Bool {
        guard let students = realm?.objects(PowerschoolAccount.self) else { return false }
        for student in students {
            if student.username == username {
                return true
            }
        }
        return false
    }
    
    
    func checkIfClassExists(username:String, classType: ClassType) -> Bool {
        guard let students = realm?.objects(PowerschoolAccount.self) else { return false }
        for student in students {
            if student.username == username {
                for cl in student.classData {
                    if cl.className == classType.className && cl.quarter == classType.quarter && cl.href == classType.href {
                        return true
                    } 
                }
            }
        }
        return false
    }
    
    func getClassesData(username: String) -> [StudentClassData] {
        guard let students = realm?.objects(PowerschoolAccount.self) else { return [] }
        for student in students {
            if student.username != username {continue}
            return Array(student.classData)
        }
        return []
    }
    
    private func getClassInfo(classType: ClassType) -> StudentClassData {
        guard let students = realm?.objects(PowerschoolAccount.self) else { return StudentClassData()}
        for student in students {
            if student.username != classType.username {continue}
            for cl in student.classData {
                if cl.className != classType.className {continue}
                if cl.quarter != classType.quarter {continue}
                if cl.href != classType.href {continue}
                return cl
            }
        }
        return StudentClassData()
    }
    
    
    private func getStudent(username: String) -> PowerschoolAccount {
        guard let students = realm?.objects(PowerschoolAccount.self) else { return PowerschoolAccount()}
        for student in students {
            if student.username != username {continue}
            return student
        }
        return PowerschoolAccount()
    }
    
    
    
    
    func addClass(username: String, classType: ClassType) {
        let student = getStudent(username: username)
        if checkIfClassExists(username: username, classType: classType) {return}

        do {
            try realm?.write() {
                student.classData.append(StudentClassData(className: classType.className, quarter: classType.quarter, href: classType.href))
            }
        } catch {
            print("FAILED TO ADD CLASS: \(error.localizedDescription)")
        }
            
        
    }
    
    func setStudentInfo(username: String, type: StudentDataOptions, value: String) {
        let student = getStudent(username: username)
        do {
            try realm?.write() {
                switch type {
                    case .username: student.username = value
                    case.firstName: student.firstName = value
                    case.lastName: student.lastName = value
                    case .lastReportDate: student.lastReportDate = value

                }
            }
        } catch {
            print("FAILED TO SET STUDENT INFO: \(error.localizedDescription)")
        }
    
    }
    
    func getStudentInfo(username: String, type: StudentDataOptions) -> Any {
        let student = getStudent(username: username)
        
        switch type {
            case .username: return student.username
            case .firstName: return student.firstName
            case .lastName: return student.lastName
            case .lastReportDate: return student.lastReportDate
        }
    }
    
    
    
    func setClassData(classType: ClassType, type: ClassDataOptions, value: Any) {
        let cl = getClassInfo(classType: classType)
        do {
            try realm?.write() {
                switch type {
                    case .className: cl.className = value as! String
                    case .quarter: cl.quarter = value as! Int
                    case .href: cl.href = value as! String
                    case .grade: cl.grade = value as! Int
                    case .weightedGrade: cl.weighted_grade = value as! Int
                    case .teacher: cl.teacher = value as! String
                    case .received: cl.received = value as! Float
                    case .total: cl.total = value as! Float
                    case .assignments: cl.assignments.append(value as! Assignments)
                    case .letterGrade: cl.letterGrade = value as! String
                    case .needPointsLetter: cl.needPointsLetter = value as! Float
                    case .needPointsPercent: cl.needPointsPercent = value as! Float
                    case .detailedGrade: cl.detailedGrade = value as! Float
                    case .credits: cl.credits = value as! Float
                    case .placement: cl.placement = value as! String
                    case .reportGrade: cl.reportGrade = value as! Int
                    case .reportPointsEarned: cl.reportPointsEarned = value as! Float
                    case .reportPointsTotal: cl.reportPointsTotal = value as! Float
                    case .reportAssignments: cl.reportAssignments = value as! Int
                }
            }
        } catch {
            print("ERROR")
        }

    }
    
    func getClassData(classType: ClassType, type: ClassDataOptions) -> Any {
        let cl = getClassInfo(classType: classType)
        
        switch type {
            case .className: return cl.className
            case .quarter: return cl.quarter
            case .href: return cl.href
            case .grade: return cl.grade
            case .weightedGrade: return cl.weighted_grade
            case .teacher: return cl.teacher
            case .received: return cl.received
            case .total: return cl.total
            case .assignments: return cl.assignments
            case .letterGrade: return cl.letterGrade
            case .needPointsLetter: return cl.needPointsLetter
            case .needPointsPercent: return cl.needPointsPercent
            case .detailedGrade: return cl.detailedGrade
            case .credits: return cl.credits
            case .placement: return cl.placement
            case .reportGrade: return cl.reportGrade
            case .reportPointsTotal: return cl.reportPointsTotal
            case .reportPointsEarned: return cl.reportPointsEarned
            case .reportAssignments: return cl.reportAssignments
        }
    }
    
    func updateAssignment(classType: ClassType, customid: String, newScore: String, flags: String, date: String, category: String) {
        let cl = getClassInfo(classType: classType)
        for assignment in cl.assignments {
            if assignment.customid == customid {
                do {
                    try realm?.write() {
                        assignment.score = newScore
                        assignment.flags = flags
                        assignment.date = date
                        assignment.category = category

                    }
                } catch {
                    print("FAILED TO UPDATE ASSIGNMENT: \(error.localizedDescription)")
                }
                
            }
        }
    }
    
    func getAllAssignments() -> List<Assignments> {
        let list = List<Assignments>()
        guard let assignments = realm?.objects(Assignments.self) else { return List<Assignments>() }
        for assignment in assignments {
            list.append(assignment)
        }
        return list
    }
    
    func getNumberOfClasses() -> Int {
        guard let classes = realm?.objects(StudentClassData.self) else { return 0 }
        var clist: [String] = []
        
        for c in classes {
            if clist.contains(c.className) { continue }
            clist.append(c.className)
        }
        
        return clist.count
    }
    
    
    func resetDatabase() {
        do {
            try realm?.write {
              realm?.deleteAll()
            }
        } catch {
            return
        }
    }
    
    
    
    func updateReportValues() {
        guard let classes = realm?.objects(StudentClassData.self) else { return }
        let student = getStudent(username: AccountManager.global.username)
        do {
            try realm?.write() {
                for c in classes {
                    if c.quarter != AccountManager.global.selectedQuarter { continue }
                    c.reportGrade = c.weighted_grade
                    c.reportPointsEarned = c.received
                    c.reportPointsTotal = c.total
                    c.reportAssignments = c.assignments.count
                }
                let current = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy (h:mm a)"
                student.lastReportDate = formatter.string(from: current)

            }
        } catch {
            print(error.localizedDescription)
        }
    
    }
    
    func containsOldClasses(currentClasses: [[String : String]]) -> Bool {
        let student = getStudent(username: AccountManager.global.username)
        var classNames: [String] = []
        
        currentClasses.forEach { classNames.append($0["className"] ?? "") }
        for cl in student.classData {
            if !classNames.contains(cl.className) { return true }
        }
        return false
    }
    
    func deleteClasses() {
        do {
            let student = getStudent(username: AccountManager.global.username)
            try realm?.write {
                let removeClasses = student.classData
                removeClasses.forEach { realm?.delete($0)}
                guard let assignments = realm?.objects(Assignments.self) else { return }
                realm?.delete(assignments)
            }
        } catch {
            return
        }
    }
    
}

class ClassType {
    var username: String = ""
    var className: String = ""
    var quarter: Int = 0
    var href: String = ""
    
    init(username: String, className: String, quarter: Int, href: String) {
        self.username = username
        self.className = className
        self.quarter = quarter
        self.href = href 
    }
}

class PowerschoolAccount: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var username: String = ""
    @Persisted var classData = List<StudentClassData>()
    @Persisted var lastReportDate: String = ""
    
    convenience init(username:String) {
        self.init()
        self.username = username
    }
}



class StudentClassData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var className: String = ""
    @Persisted var quarter: Int = 0
    @Persisted var href: String = ""
    @Persisted var teacher: String = ""
    @Persisted var grade: Int = 0
    @Persisted var weighted_grade: Int = 0
    @Persisted var detailedGrade: Float = 0.0
    @Persisted var letterGrade: String = ""
    @Persisted var received: Float = 0.0
    @Persisted var total: Float = 0.0
    @Persisted var needPointsLetter: Float = 0.0
    @Persisted var needPointsPercent: Float = 0.0
    @Persisted var assignments: List<Assignments>
    @Persisted var credits: Float = 1
    @Persisted var placement: String = ""
    @Persisted var reportGrade: Int = 0
    @Persisted var reportPointsEarned: Float = 0
    @Persisted var reportPointsTotal: Float = 0
    @Persisted var reportAssignments: Int = 0
    
    convenience init(className: String, quarter: Int, href: String) {
        self.init()
        self.className = className
        self.quarter = quarter
        self.href = href
    }
}

class Assignments: Object {
    @Persisted(primaryKey: true)  var customid: String = ""
    @Persisted var name: String = ""
    @Persisted var score: String = ""
    @Persisted var flags: String = ""
    @Persisted var date: String = ""
    @Persisted var category: String = ""

    
    convenience init(name: String, score: String, flags: String, date: String, category: String) {
        self.init()
        self.name = name
        self.score = score
        self.flags = flags
        self.date = date
        self.category = category
        self.customid = "\(name)_\(date)"
    }

}

