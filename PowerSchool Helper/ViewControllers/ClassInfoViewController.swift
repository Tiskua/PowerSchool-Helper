//
//  ClassViewController.swift
//  
//
//  Created by Branson Campbell on 10/2/22.
//


import UIKit
import SwiftSoup
import SwiftUI

class ClassInfoController: UIViewController {
    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    @IBOutlet weak var GPALabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var needPercentLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var assignmentsLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var needLetterLabel: UILabel!
    @IBOutlet weak var gradeHistoryButton: UIButton!
    @IBOutlet weak var assignmentsBackground: UIView!
    @IBOutlet weak var showAllAssignmentsButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        classLabel.textColor = Util.getThemeColor()
        assignmentsLabel.textColor = Util.getThemeColor()
        backButton.tintColor = Util.getThemeColor()
        showAllAssignmentsButton.tintColor = Util.getThemeColor()
        gradeHistoryButton.tintColor = Util.getThemeColor()
        backgroundView.layer.cornerRadius = 10
        assignmentsBackground.layer.cornerRadius = 10
    }
    
    private var htmlString = ""
    private var selectedClass = ""
    
    @objc func tappedAssignments(_ gesture: UITapGestureRecognizer) {
        guard let assignmentVC = self.storyboard?.instantiateViewController(withIdentifier: "AssignmentViewController") as? AssignmentViewController else {return}
        assignmentVC.assignments = ClassDataManager.shared.getClassData(className: selectedClass, type: "assignments") as! [[String : String]]
        self.present(assignmentVC, animated: true, completion:nil)
    }
    
    @IBAction func dismissView(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    func goToMainPage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if (WebpageManager.shared.webView.canGoBack) {WebpageManager.shared.webView.goBack()}
        }
    }
        
    func setGPALabel(grade: Int) {
        GPALabel.text = "GPA: " + String(Util.findGPA(grade: grade))
    }
    func setClassLabel(text : String) {
        ClassDataManager.shared.addData(className: text, type: "class_name", data: text)
        classLabel.text = text
        selectedClass = text
    }
    func setGradeLabel() {
        if !NetworkMonitor.shared.isConnected {
            let grade: Int = ClassDataManager.shared.getClassData(className: selectedClass, type: "grade") as! Int
            let weightedGrade: Int = ClassDataManager.shared.getClassData(className: selectedClass, type: "weighted_grade") as! Int
            gradeLabel.text = "Grade: \(grade) | \(weightedGrade) (\(Util.findGradeLetterSP(grade: weightedGrade)))"
            return
        }
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(htmlString)
            let table: Element = try doc.select(".linkDescList")[0]
            let tds: Elements = try table.select("td")
            let grade: String = try tds[4].text()
            let regular_grade:Int = Int(grade.suffix(4).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let weighted_grade:Int = Int(grade.prefix(3).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            gradeLabel.text = "Grade: \(regular_grade) | \(weighted_grade) (\(Util.findGradeLetterSP(grade: weighted_grade)))"

        } catch {
            print("Error")
        }
    }
    
    func getLatestAssignments() {
        if !NetworkMonitor.shared.isConnected {
            let assignments = ClassDataManager.shared.getClassData(className: selectedClass, type: "assignments") as? [[String : String]] ?? []
            if !assignments.isEmpty {setLatestAssignmentLabels(assignments: assignments)}
            return
        }
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(htmlString)
            let main: Element = try doc.select(".xteContentWrapper")[0]
            let ngscope: Element = try main.select(".ng-scope")[0]
            let trs: Elements = try ngscope.select("tr")
            var assignmentList: [[String : String]] = []
            for tr in trs {
                let tds: Elements = try tr.select("td")
                if tds.size() < 10 {continue}
                let assignment: String = try tds[2].select("span").text()
                let score: String = try tds[10].text()
                let date: String = try tds[0].text()
                var assignmentInfo : [String : String] = [
                    "assignment" : assignment,
                    "score" : score,
                    "flags" : getAssignemntFlags(tds: tds),
                    "date" : date
                ]
                assignmentList.append(assignmentInfo)
            }
            setLatestAssignmentLabels(assignments: assignmentList)
            
            ClassDataManager.shared.addData(className: selectedClass, type: "assignments", data: assignmentList)
            UserDefaults.standard.set(ClassDataManager.shared.classes_info, forKey: "class_data_list")
            goToMainPage()
        } catch {
            print("Error")
        }
    }
    
    func setLatestAssignmentLabels(assignments: [[String : String]]) {
        let backgroundViewY: Int = Int(assignmentsBackground.frame.minY) + 10
        let maxAssignments = UIDevice.current.userInterfaceIdiom == .phone ? 5 : 20
        
        for i in 0...maxAssignments-1 {
            if i > assignments.count-1 {break}
            let assignment = assignments[i]
            let assignmentLabel: UILabel = UILabel(frame: CGRect(x: 15, y: 52*i + backgroundViewY, width: Int(assignmentsBackground.frame.width-10), height: 45))
            assignmentLabel.text = "• " + assignment["assignment"]! + " (" + assignment["score"]! + ")"
            assignmentLabel.textColor = Util.setFlagColor(flag: assignment["flags"]!)
            assignmentLabel.backgroundColor = .clear
            assignmentLabel.numberOfLines = 2
            assignmentLabel.font = UIFont(name: "Verdana Bold", size: 17)
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedAssignments(_:)))
            gestureRecognizer.numberOfTapsRequired = 1
            gestureRecognizer.numberOfTouchesRequired = 1
            assignmentLabel.addGestureRecognizer(gestureRecognizer)
            assignmentLabel.isUserInteractionEnabled = true
            
            backgroundView.addSubview(assignmentLabel)
        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedAssignments(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        assignmentsBackground.addGestureRecognizer(gestureRecognizer)
        assignmentsBackground.isUserInteractionEnabled = true
        
    }
    
    func getAssignemntFlags(tds : Elements) -> String {
        var flags: String = ""
        do {
            for i in 3...9 {
                let div = try tds[i].select(".ps-icon")
                if div.count > 0 {flags = String(i)}
            }
        } catch {print("Error")}
        return flags
    }
    
    func setPointsNeeded(total: Float, recieved: Float) {
        if (total/recieved).isNaN {return}
        
        let grade: Float = round(Float(recieved/total)*100)
        let initialGradeLetter = Util.findGradeLetter(grade: Int(grade))
        
        var tempGradeLetter = initialGradeLetter
        var tempgrade = Float(grade)
        
        var pointsAddedPercent: Float = 0.0
        var pointsAddedLetter: Float = 0.0

        if grade < 100 {
            while Int(grade) == Int(tempgrade) {
                pointsAddedPercent += 1.0
                tempgrade = round(Float((pointsAddedPercent + recieved)/(pointsAddedPercent + total))*100)
            }
        }
        
        if initialGradeLetter != "A" {
            while initialGradeLetter == tempGradeLetter {
                pointsAddedLetter += 1.0
                let tempgrade1 = round(Float((pointsAddedLetter + recieved)/(pointsAddedLetter + total))*100)
                tempGradeLetter = Util.findGradeLetter(grade: Int(tempgrade1))
            }
        }
        
        needPercentLabel.text = "Need (%): \(pointsAddedPercent) (\(Int(tempgrade))%)"
        needLetterLabel.text = "Need (L): \(pointsAddedLetter) (\(tempGradeLetter))"
    }
    
    
    
    func setPointsLabel() {
        if !NetworkMonitor.shared.isConnected {
            let received: Float = ClassDataManager.shared.getClassData(className: selectedClass, type: "received") as! Float
            let total: Float = ClassDataManager.shared.getClassData(className: selectedClass, type: "total") as! Float

            pointsLabel.text = "Points: \(received) / \(total)"
            self.setPointsNeeded(total: total, recieved: received)
            self.setGradeLabel()
            self.getLatestAssignments()
            self.setTeacherLabel()
            return
        }
        WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                htmlString = html
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                setTeacherLabel()

                let main: Element = try doc.select(".xteContentWrapper")[0]
                let ngscope: Element = try main.select(".ng-scope")[0]
                let trs: Elements = try ngscope.select("tr")
                
                var totalPoints: Float = 0.0
                var recivedPoints: Float = 0.0
                for tr in trs {
                    let tds: Elements = try tr.select("td")
                    if tds.size() < 10 {continue}
                    let pointTD: String = try tds[10].text()
                    if pointTD.contains("-"){continue}
                    
                    totalPoints += Float(pointTD.split(separator: "/")[1]) ?? 0.0
                    recivedPoints += Float(pointTD.split(separator: "/")[0]) ?? 0.0
                }
                ClassDataManager.shared.addData(className: selectedClass, type: "received", data: recivedPoints)
                ClassDataManager.shared.addData(className: selectedClass, type: "total", data: totalPoints)
                pointsLabel.text = "Points: " + String(recivedPoints) + "/" + String(totalPoints)
                self.setPointsNeeded(total: totalPoints, recieved: recivedPoints)
                self.setGradeLabel()
                self.getLatestAssignments()
                
            } catch {
                print("error")
            }
        }
    }
    func setTeacherLabel() {
        if !NetworkMonitor.shared.isConnected {
            let teacher: String = ClassDataManager.shared.getClassData(className: selectedClass, type: "teacher") as! String
            teacherLabel.text = "Teacher: \(teacher)"
            return
        }
        do {
            let doc: Document = try SwiftSoup.parseBodyFragment(htmlString)
            let table: Element = try doc.select(".linkDescList")[0]
            let tds: Elements = try table.select("td")
            let teacher: String = try tds[1].text()
            let teacher_first: String = teacher.components(separatedBy:",")[1]
            let teacher_last: String = teacher.components(separatedBy:",")[0]
            ClassDataManager.shared.addData(className: selectedClass, type: "teacher", data: "\(teacher_first) \(teacher_last)")
            teacherLabel.text = "Teacher: \(teacher_first) \(teacher_last)"
        } catch {
            print("Error")
        }
    }
    
    @IBAction func showGradeChart(_ sender: Any) {
        let nameScreenData = NameScreenData()
        var gradePointData: [[[String : String]]] = []

        let assignments = ClassDataManager.shared.getClassData(className: selectedClass, type: "assignments") as? [[String : String]] ?? []
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 7, assignments: assignments))
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 14, assignments: assignments))
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 30, assignments: assignments))
        
        nameScreenData.assignments = gradePointData
        
        let gradeChartVC = UIHostingController(rootView: GradeChartView().environmentObject(nameScreenData))
        gradeChartVC.modalPresentationStyle = .fullScreen
        self.present(gradeChartVC, animated: true)
    }
    
    
    @IBAction func showAllAssignments(_ sender: Any) {
        guard let assignmentVC = self.storyboard?.instantiateViewController(withIdentifier: "AssignmentViewController") as? AssignmentViewController else {return}
        assignmentVC.assignments = ClassDataManager.shared.getClassData(className: selectedClass, type: "assignments") as! [[String : String]]
        self.present(assignmentVC, animated: true, completion:nil)
    }
}
