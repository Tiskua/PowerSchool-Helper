//
//  ClassManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/25/22.
//

import Foundation


class ClassDataManager {
    static let shared = ClassDataManager()
    var classes_info: [[String : Any]] = []

    
    public func addData(className:String, type: String, data: Any) {
        var selectedData: [String : Any] = [:]
        var dataIndex = -1
        for (index, classData) in classes_info.enumerated() {
            if classData["class_name"] as! String == className {
                selectedData = classData
                dataIndex = index
                break
            }
        }
        if dataIndex > -1 {
            classes_info.remove(at: dataIndex)
            selectedData[type] = data
            classes_info.insert(selectedData, at: dataIndex)

        }
    }
    
    public func setClassData(className: String, grade: Int, weightedGrade: Int, href: String) {
        var updatedList: [String : Any] = [:]
        var dataIndex = -1
        for (index, c) in classes_info.enumerated() {
            if c["class_name"] as! String == className {
                updatedList = c
                dataIndex = index
                break
            }
        }
        if dataIndex > -1 {
            updatedList["grade"] = grade
            updatedList["weighted_grade"] = weightedGrade
            updatedList["hred"] = href
            classes_info.remove(at: dataIndex)
            classes_info.insert(updatedList, at: dataIndex)
            return
        }
        
        
        let classData: [String : Any] = [
            "class_name" : className,
            "href" : href,
            "grade" : grade,
            "weighted_grade" : 0.0,
            "teacher" : "",
            "received" : 0,
            "total" : 0,
            "assignments" : [:]
        ]
        classes_info.append(classData)
        let formatedClass_name = className.lowercased().replacingOccurrences(of: " ", with: "_")
        UserDefaults.standard.set(classData, forKey: "class_data_" + formatedClass_name)
    }
    
    public func getClassData(className: String, type: String) -> Any {
        for classData in classes_info {
            if classData["class_name"] as! String == className {
                return classData[type] ?? "nil"
            }
        }
        return ""
    }
}
