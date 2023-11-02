//
//  Report.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/5/23.
//

import UIKit
import RealmSwift

class ReportVC: UIViewController, UIScrollViewDelegate {
    
    var scrollView = UIScrollView()
    var databaseClasses: [StudentClassData] = []
    
    var isCheckingDate = false
    override func viewDidLoad() {
        super.viewDidLoad()
       
        AccountManager.global.selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        if AccountManager.global.username == "" { return }
        databaseClasses = DatabaseManager.shared.getClassesData(username: AccountManager.global.username)
        if databaseClasses.isEmpty { return }
        scrollView.delegate = self
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .clear
        view.addSubview(WebpageManager.shared.webView)
        view.addSubview(scrollView)
        self.sheetPresentationController?.prefersGrabberVisible = true
        
        guard let calendarString = DatabaseManager.shared.getStudentInfo(username: AccountManager.global.username, type: .lastReportDate) as? String
            else { return }
        if calendarString == "" {
            DatabaseManager.shared.updateReportValues()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isCheckingDate == false { 
            checkDate() }
    }
    
    func checkDate() {
        isCheckingDate = true
    
        NotificationManager.shared.getReportDate() { reportDate in
            DispatchQueue.main.async {
                let currentDate = Date()
                
                guard let currentReportDate = UserDefaults.standard.value(forKey: "reportDate") as? Date else {
                    UserDefaults.standard.setValue(reportDate, forKey: "reportDate")
                    self.checkDate()
                    return
                }
                            
                if currentDate > currentReportDate {
                    Util.showLoading(view: self.view, text: "Getting Latest Information...")
                    self.getLatestInfo()
                    UserDefaults.standard.setValue(reportDate, forKey: "reportDate")
                } else {
                    self.setLastReportLabel()
                    self.setInfo()
                }
            }
        }
    }
    
    func getLatestInfo() {
        if !WebpageManager.shared.isLoopingClasses {
            WebpageManager.shared.isLoopingClasses = true
            DispatchQueue.main.async {
                WebpageManager.shared.loopThroughClassData(index: 0, completion: {
                    DatabaseManager.shared.updateReportValues()
                    self.setLastReportLabel()
                    self.setInfo()
                    self.isCheckingDate = false
                    Util.hideLoading(view: self.view)
                    
                })
            }
        }
    }
    
    
    
    func setLastReportLabel() {
        while let label = view.viewWithTag(100) { label.removeFromSuperview() }
        guard let calendarString = DatabaseManager.shared.getStudentInfo(username: AccountManager.global.username, type: .lastReportDate) as? String
            else { return }
        let lastReportLabel = UILabel(frame: CGRect(x: 20, y: 10, width: view.frame.width-40, height: 40))
        lastReportLabel.text = "Last Report: \(calendarString)"
        lastReportLabel.textColor = .lightGray
        lastReportLabel.font = UIFont(name: "Avenir Next Bold", size: 18)
        lastReportLabel.tag = 100
        scrollView.addSubview(lastReportLabel)
    }
    
    func setInfo() {
        self.setClassInfoLabels()

    }
    func setClassInfoLabels() {
        while let classView = view.viewWithTag(101) { classView.removeFromSuperview() }
        let classHeight = 230
        let xPos = 10
        var yPos = 60
        
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            let reportClassView = ReportClassView(frame: CGRect(x: xPos, y: yPos, width: Int(view.frame.width)-20, height: classHeight))
            reportClassView.backgroundColor = Util.getThemeColor().withAlphaComponent(0.3)
            reportClassView.layer.cornerRadius = 20
            reportClassView.clipsToBounds = true
            reportClassView.layer.masksToBounds = true
                    
            reportClassView.layer.borderColor = Util.getThemeColor().withAlphaComponent(0.5).cgColor
            reportClassView.layer.borderWidth = 4
            
            let classType = ClassType(username: AccountManager.global.username, className: c.className, quarter: AccountManager.global.selectedQuarter, href: c.href)
            
            reportClassView.classNameLabel.text = c.className
            
            reportClassView.gradeChangeLabel.text = "Grade: \(getGradeChange(classType: classType))"
            reportClassView.earnedPointsLabel.text = "Earned: \(getPointEarnedChange(classType: classType))"
            reportClassView.totalPointsLabel.text = "Total: \(getPointTotalChange(classType: classType))"
            reportClassView.assignmentChangeLabel.text = "Assignments: \(getAssignmentsChanged(classType: classType))"
            reportClassView.tag = 101

            scrollView.addSubview(reportClassView)
            yPos += classHeight + 20
        }
        setSrollHeight(ypos: yPos)
    }
    
    func getGradeChange(classType: ClassType) -> String {
        var newGrade = -1
        var oldGrade = -1
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            newGrade = DatabaseManager.shared.getClassData(classType: classType, type: .weightedGrade) as! Int
            oldGrade = DatabaseManager.shared.getClassData(classType: classType, type: .reportGrade) as! Int

        }
        let difference = (newGrade-oldGrade)
        let sign = difference >= 0 ? "+" : "-"
        

        if newGrade == -1 {
            return "--% \u{2794} --% (--)"
        } else {
            return "\(oldGrade)% \u{2794} \(newGrade)% (\(sign)\(difference))"
        }
    }
    
    func getPointTotalChange(classType: ClassType) -> String {
        var newTotal: Float = -1
        var oldTotal: Float = -1
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            newTotal = DatabaseManager.shared.getClassData(classType: classType, type: .total) as! Float
            oldTotal = DatabaseManager.shared.getClassData(classType: classType, type: .reportPointsTotal) as! Float
        }
        let difference = (newTotal-oldTotal)
        let sign = difference >= 0 ? "+" : "-"
        
        let newText = "\(oldTotal) \u{2794} \(newTotal) (\(sign)\(difference))"

        return newText

    }
    
    func getPointEarnedChange(classType: ClassType) -> String {
        var newEarned: Float = -1
        var oldEarned: Float = -1
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            newEarned = DatabaseManager.shared.getClassData(classType: classType, type: .received) as! Float
            oldEarned = DatabaseManager.shared.getClassData(classType: classType, type: .reportPointsEarned) as! Float
        }
        let difference = (newEarned-oldEarned)
        let sign = difference >= 0 ? "+" : "-"
        
        if newEarned == -1 {
            return "--% \u{2794} --% (--)"
        } else {
            return "\(oldEarned) \u{2794} \(newEarned) (\(sign)\(difference))"
        }
    }
    
    func getAssignmentsChanged(classType: ClassType) -> String {
        var oldAssignments: Int = 0
        var newAssignments: Int = 0
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            oldAssignments = DatabaseManager.shared.getClassData(classType: classType, type: .reportAssignments) as! Int
            newAssignments = (DatabaseManager.shared.getClassData(classType: classType, type: .assignments) as? RealmSwift.List<Assignments>)?.count ?? 0
        }
        let difference = (newAssignments-oldAssignments)
        let sign = difference >= 0 ? "+" : "-"
        
        if newAssignments == -1 {
            return "--% \u{2794} --% (--)"
        } else {
            return "\(oldAssignments) \u{2794} \(newAssignments) (\(sign)\(difference))"
        }
    }
    
    func setSrollHeight(ypos: Int) {
        let bottomOffset: CGFloat = 200
        if CGFloat(ypos) + bottomOffset > view.frame.height { scrollView.contentSize.height = CGFloat(ypos) + bottomOffset}
        else {scrollView.contentSize.height = view.frame.height+20}
    }
}
