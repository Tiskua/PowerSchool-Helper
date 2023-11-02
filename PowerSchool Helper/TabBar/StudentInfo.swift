//
//  StudentInfo.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 7/26/23.
//

import Foundation
import RealmSwift

class StudentInfoViewController: UIViewController {
    
    @IBOutlet weak var GPALbl: UILabel!
    @IBOutlet weak var studentNameLbl: UILabel!
    @IBOutlet weak var numberClassesLbl: UILabel!
    @IBOutlet weak var totalAssignmentsLbl: UILabel!
    @IBOutlet weak var totalPointsLbl: UILabel!
    @IBOutlet weak var totalPointsEarnedLbl: UILabel!
    @IBOutlet weak var GPA100Lbl: UILabel!
    
    var circularProgressBarView: GPACircleView!
    var assignments = DatabaseManager.shared.getAllAssignments()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberClassesLbl.text = "Number of Classes: \(DatabaseManager.shared.getNumberOfClasses())"
        totalAssignmentsLbl.text = "Total Assignments: \(DatabaseManager.shared.getAllAssignments().count)"
        
        let pointsData = getPointData()
        totalPointsEarnedLbl.text = "Total Earned Points: \(pointsData[0])"
        totalPointsLbl.text = "Total Points: \(pointsData[1])"
        
        GPA100Lbl.text = "GPA (100): \(String(format: "%.2f", getGPA100()))"
        
        WebpageManager.shared.getStudentName() { name in
            self.studentNameLbl.text = "\(name[1]) \(name[0])"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setupCircularProgressBarView(GPA: getWeightedGPA())
        GPALbl.text = String(format: "%.1f", getWeightedGPA())
    }

    func getPointData() -> [Double] {
        var totalPoints = 0.0
        var earnedPoints = 0.0
        for a in assignments {
            let score = a.score.components(separatedBy: "/")
            if score[0] == "--" { continue }
            totalPoints += Double(score[1]) ?? 0
            earnedPoints += Double(score[0]) ?? 0
        }
        return [earnedPoints, totalPoints]
    }
    
    func setupCircularProgressBarView(GPA: Double) {
        let circularViewDuration: TimeInterval = 1
        let percentage = GPA*25/100
        circularProgressBarView = GPACircleView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), color: .green, percentage: percentage)
        circularProgressBarView.center = CGPoint(x: view.center.x, y: GPALbl.center.y)
        circularProgressBarView.progressAnimation(duration: circularViewDuration)
        view.addSubview(circularProgressBarView)
    }
    
    func getGPA100() -> Double {
        var points: Float = 0.0
        var classes: Float = 0.0
        for c in DatabaseManager.shared.getClassesData(username: AccountManager.global.username) {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            if (c.grade == -1) { continue }
            classes += 1
            points += Float(c.weighted_grade)
        
        }
        return Double(points/classes)
    }
    
    func getWeightedGPA() -> Double {
        var points: Float = 0.0
        var classes: Float = 0.0
        for c in DatabaseManager.shared.getClassesData(username: AccountManager.global.username) {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            if (c.grade == -1) { continue }
            let credits = Util.findGPA(grade: c.grade) + Util.addWeightofClass(c: c)
            classes += 1
            points += Float(credits)
        
        }
        return Double(points/classes)
    }
    
    @IBAction func signOutButtonAction(_ sender: Any) {
        WebpageManager.shared.setPageLoadingStatus(status: .signOut)
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('btnLogout').click()")
        WebpageManager.shared.clearBrowserData()
        UserDefaults.standard.removeObject(forKey: "sign-in-type")
        UserDefaults.standard.removeObject(forKey: "login-username")
        self.dismiss(animated: true)
    }
}
