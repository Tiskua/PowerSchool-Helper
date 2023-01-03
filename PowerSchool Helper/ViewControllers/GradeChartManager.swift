//
//  GradeChartViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/17/22.
//

import Foundation
import UIKit
import SwiftUI
class GradeChartManager {
    
    func getGradePointDataList(timeBack: Int, assignments: [[String : String]]) -> [[String : String]]{
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        let assignmentsFromPast = getAssignmentsFromPast(days: timeBack)
        var gradeDataFromPast: [[String : String]] = []

        for i in 0...timeBack-1 {
            var pointsEarned: Double = 0.0
            var pointsTotal: Double = 0.0
            
            for assignment in assignments {
                if assignment["score"]!.contains("-") {continue}
                let gradeDateTime = formatter.date(from: assignment["date"]!)
                let lastWeekDateTime = formatter.date(from: assignmentsFromPast[i])
                if gradeDateTime! < lastWeekDateTime! {
                    let scoreParts = assignment["score"]!.split(separator: "/")
                    pointsEarned += Double(scoreParts[0])!
                    pointsTotal += Double(scoreParts[1])!
                }
            }
            let grade = (pointsEarned/pointsTotal) * 100

            let dateSplitter = assignmentsFromPast[i].split(separator: "/")
            let formattedDate = "\(dateSplitter[0])/\(dateSplitter[1])"
            gradeDataFromPast.append([
                "grade" : String(grade),
                "date" : formattedDate
            ])
        }
        return gradeDataFromPast
    }
    
    
    func getAssignmentsFromPast(days: Int) -> [String] {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        var dates = [String]()
        for _ in 1 ... days {
            let d = "\(cal.component(.month, from: date))/\(cal.component(.day, from: date))/\(cal.component(.year, from: date))"
            dates.append(d)
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        return dates
    }

}

