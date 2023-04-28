//
//  ClassManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/25/22.
//

import UIKit
import RealmSwift


class ClassInfoManager {
    static let shared = ClassInfoManager()
    
    private(set) var realm: Realm?
    
    enum StudentDataOptions: String {
        case username
        case firstName
        case lastName
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
    }
    
    func initizialeSchema(username: String) {
    
        var config = Realm.Configuration(schemaVersion: 2)
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
            try realm!.write {
                realm!.add(PowerschoolAccount(username: username))
            }
        } catch {
            print("FAILED TO ADD STUDENT TO DATABASE: \(error.localizedDescription)")
        }
         
    }
    
    func checkIfStudentExists(username:String) -> Bool {
        let students = realm!.objects(PowerschoolAccount.self)
        for student in students {
            if student.username == username {
                return true
            }
        }
        return false
    }
    
    
    func checkIfClassExists(username:String, classType: ClassType) -> Bool {
        let students = realm!.objects(PowerschoolAccount.self)
        for student in students {
            if student.username == username {
                for cl in student.classData {
                    if cl.class_name == classType.className && cl.quarter == classType.quarter && cl.href == classType.href {
                        return true
                    } 
                }
            }
        }
        return false
    }
    
    func getClassesData(username: String) -> [StudentClassData] {
        let students = realm!.objects(PowerschoolAccount.self)
        for student in students {
            if student.username != username {continue}
            return Array(student.classData)
        }
        return [StudentClassData()]
    }
    
    private func getClassInfo(classType: ClassType) -> StudentClassData {
        let students = realm!.objects(PowerschoolAccount.self)
        for student in students {
            if student.username != classType.username {continue}
            for cl in student.classData {
                if cl.class_name != classType.className {continue}
                if cl.quarter != classType.quarter {continue}
                if cl.href != classType.href {continue}
                return cl
            }
        }
        return StudentClassData()
    }
    
    
    private func getStudent(username: String) -> PowerschoolAccount {
        let students = realm!.objects(PowerschoolAccount.self)
        for student in students {
            if student.username != username {continue}
            return student
        }
        return PowerschoolAccount()
    }
    
    
    
    
    func addClass(username: String, classType: ClassType) {
        let students = realm!.objects(PowerschoolAccount.self)
        if checkIfClassExists(username: username, classType: classType) {return}

        for student in students {
            if student.username != username {continue}
            do {
                try realm?.write {
                    student.classData.append(StudentClassData(className: classType.className, quarter: classType.quarter, href: classType.href))
                }
            } catch {
                print("FAILED TO ADD CLASS \(classType.className): \(error.localizedDescription)")
            }
           
        }
    }
    
    func setStudentInfo(username: String, type: StudentDataOptions, value: String) {
        let student = getStudent(username: username)
        do {
            try realm?.write {
                switch type {
                    case .username: student.username = value
                    case.firstName: student.firstName = value
                    case.lastName: student.lastName = value
                }
            }
        } catch {
            print("FAILED TO SET STUDENT INFO: \(error.localizedDescription)")
        }
        
    }
    
    
    func setClassData(classType: ClassType, type: ClassDataOptions, value: Any) {
        let cl = getClassInfo(classType: classType)
        do {
            try realm?.write {
                switch type {
                case .className: cl.class_name = value as! String
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
                    
                }
            }
        } catch {
            print("FAILED TO SET ClASS DATA: \(error.localizedDescription)")
        }
    }
    
    func getClassData(classType: ClassType, type: ClassDataOptions) -> Any {
        let cl = getClassInfo(classType: classType)
        
        switch type {
            case .className: return cl.class_name
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
        }
    }
    
    func updateAssignment(classType: ClassType, customid: String, newScore: String, flags: String, date: String) {
        let cl = getClassInfo(classType: classType)
        for assignment in cl.assignments {
            if assignment.customid == customid {
                try! realm!.write {
                    assignment.score = newScore
                    assignment.flags = flags
                    assignment.date = date
                }
            }
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
    @Persisted var firstName:String = ""
    @Persisted var lastName:String = ""
    @Persisted var username:String = ""
    @Persisted var classData = List<StudentClassData>()
    
    convenience init(username:String) {
        self.init()
        self.username = username
    }
}



class StudentClassData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId

    @Persisted var class_name: String = ""
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
    
    convenience init(className: String, quarter: Int, href: String) {
        self.init()
        self.class_name = className
        self.quarter = quarter
        self.href = href
    }
}

class Assignments: Object {
    @Persisted(primaryKey: true)  var customid: String = ""
    @Persisted var name: String = ""
    @Persisted var score:String = ""
    @Persisted var flags:String = ""
    @Persisted var date:String = ""
    
    convenience init(name: String, score: String, flags: String, date: String) {
        self.init()
        self.name = name
        self.score = score
        self.flags = flags
        self.date = date
        self.customid = "\(name)_\(date)"
    }

}

class AccountManager {
    public static let global = AccountManager()
    public var username: String = ""
    public var password: String = ""
    public var updatedClasses: [String] = []
    public var classIndexToUpdate = 0
    public var selectedQuarter = 1
    public var updatedClassInfoList: [StudentClassData] = []
    
    public var selectedClass = ""
    public var selectedhref = ""
    public var classType = ClassType(username: "", className: "", quarter: 1, href: "")
    public var assignments: List<Assignments> = List<Assignments>()
}
