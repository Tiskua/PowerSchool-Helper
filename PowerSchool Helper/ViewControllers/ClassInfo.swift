//
//  ClassViewController.swift
//
//  PowerSchool Helper
//
//  Created by Branson Campbell on 10/2/22.
//


import RealmSwift
import UIKit
import SwiftSoup
import SwiftUI

class ClassInfoController: UIViewController {
    
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var GPALabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var needPercentLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    @IBOutlet weak var needLetterLabel: UILabel!
    @IBOutlet weak var assignmentsLabel: UILabel!
    @IBOutlet weak var myTable: UITableView!
    @IBOutlet weak var gradeLetterLabel: UILabel!
    @IBOutlet weak var gradeLetterPlusLabel: UILabel!
    @IBOutlet weak var detailedGradeLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    
    var selectedClass = ""
    var selectedhref = ""
    
    var username = ""
    var password = ""
    
    var classType = AccountManager.global.classType
    var doc = SwiftSoup.Document("")
    
    let KeyChainManager = KeychainManager()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedClass = AccountManager.global.selectedClass
        selectedhref = AccountManager.global.selectedhref
        classLabel.textColor = Util.getThemeColor()
        assignmentsLabel.textColor = Util.getThemeColor()
    
        username = UserDefaults.standard.string(forKey: "login-username") ?? "ERROR"
        password = KeyChainManager.getPassword(username: username)
        
        if NetworkMonitor.shared.isConnected {
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
                guard let html = result as? String, error == nil else {return}
                doc = try! SwiftSoup.parseBodyFragment(html)
                setClassInfo(doc: doc)
            }
        }
        
        if UserDefaults.standard.bool(forKey: "nate-mode") {
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: "Nate")
            view.insertSubview(imageView, at: 0)
        }
        myTable.delegate = self
        myTable.dataSource = self
        myTable.layer.cornerRadius = 10
        myTable.backgroundColor = .black
    }
    func setClassInfo(doc: SwiftSoup.Document) {
        let classType = ClassType(username: AccountManager.global.username, className: selectedClass, quarter: AccountManager.global.selectedQuarter, href: selectedhref)
        let classData = ClassData(isUpdated: false, classType: classType, doc: doc)
        if AccountManager.global.updatedClasses.contains("\(selectedClass)_\(AccountManager.global.selectedQuarter)") {
            classData.isUpdated = true }

        classLabel.text = selectedClass
        gradeLetterLabel.text = classData.getGradeLetter()
        
        let grades = classData.getGrade()
        gradeLabel.text = "\(grades[0])% | \(grades[1])%"

        GPALabel.text = "GPA: " + String(Util.findGPA(grade: classData.getGrade()[0]))
        teacherLabel.text = "Teacher: \(classData.getTeacher())"
   
        let points = classData.getPoints()

        pointsLabel.text = "Points: \(points[0]) / \(points[1])"
        let needPointsData = classData.getPointsNeeded(total: ClassInfoManager.shared.getClassData(classType: classType, type: .total) as! Float,
                                                       received: ClassInfoManager.shared.getClassData(classType: classType, type: .received) as! Float)
        needPercentLabel.text = "Need (\(needPointsData[0])%): \(needPointsData[1])"
        needLetterLabel.text = "Need (\(needPointsData[2])): \(needPointsData[3])"
        
        let _ = classData.getAssignments()
        
        myTable.reloadData()
        
        let detailedGrades = classData.getDetailedGrade(recieved: points[0],
                                                        total: points[1])
        detailedGradeLabel.text = "\(detailedGrades[0])% | \(detailedGrades[1])%"

        WebpageManager.shared.setPageLoadingStatus(status: .classList)
        AccountManager.global.updatedClasses.append("\(selectedClass)_\(AccountManager.global.selectedQuarter)")
        
        if WebpageManager.shared.wasLoopingClasses {
            WebpageManager.shared.isLoopingClasses = true
            WebpageManager.shared.loopThroughClasses(index: AccountManager.global.classIndexToUpdate)
        }
    }
}


class ClassData {
    init(isUpdated: Bool, classType: ClassType, doc: SwiftSoup.Document) {
        self.isUpdated = isUpdated
        self.classType = classType
        self.doc = doc
    }
    
    var classType = ClassType(username: "", className: "", quarter: 0, href: "")
    var doc = SwiftSoup.Document("")
    var isUpdated = false
    
    func getGradeLetter() -> String {
        var unweightedGrade: Int = 0
        if isUpdated {
            unweightedGrade = ClassInfoManager.shared.getClassData(classType: classType, type: .grade) as! Int
        } else {
            do {
                let table: Element = try doc.select(".linkDescList")[0]
                let tds: Elements = try table.select("td")
                let grade: String = try tds[4].text()
                unweightedGrade = Int(grade.suffix(4).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } catch {
                print("Error")
            }
        }
        let letterGrade = Util.findGradeLetterSP(grade: unweightedGrade)
        ClassInfoManager.shared.setClassData(classType: classType, type: .letterGrade, value: letterGrade)
        return letterGrade
    }
    
    func getGrade() -> [Int] {
        var unweightedGrade: Int = 0
        var weightedGrade: Int = 0
        if isUpdated {
            unweightedGrade = ClassInfoManager.shared.getClassData(classType: classType, type: .grade) as! Int
            weightedGrade = ClassInfoManager.shared.getClassData(classType: classType, type: .weightedGrade) as! Int
        } else {
            do {
                let table: Element = try doc.select(".linkDescList")[0]
                let tds: Elements = try table.select("td")
                let grade: String = try tds[4].text()
                unweightedGrade = Int(grade.suffix(4).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                weightedGrade = Int(grade.prefix(3).trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                ClassInfoManager.shared.setClassData(classType: classType, type: .grade, value: unweightedGrade)
                ClassInfoManager.shared.setClassData(classType: classType, type: .weightedGrade, value: weightedGrade)
            } catch {
                print(error.localizedDescription)
            }
        }
        return [unweightedGrade, weightedGrade]
    }
    
    func getDetailedGrade(recieved: Float, total: Float) -> [Float] {
        let grade = ClassInfoManager.shared.getClassData(classType: classType, type: .grade) as! Int
        let weightedGrade = ClassInfoManager.shared.getClassData(classType: classType, type: .weightedGrade) as! Int
        let detailedGrade = round(recieved / total * 10000) / 100
        let weight = (weightedGrade-grade)%5 != 0 ? 0 : weightedGrade-grade
        ClassInfoManager.shared.setClassData(classType: classType, type: .detailedGrade, value: detailedGrade)
        return [Float(detailedGrade), Float(detailedGrade + Float(weight))]
    }
    
    func getTeacher() -> String {
        var teacherName = ""
        if isUpdated {
            teacherName = ClassInfoManager.shared.getClassData(classType: classType, type: .teacher) as! String
        } else {
            do {
                let table: Element = try doc.select(".linkDescList")[0]
                let tds: Elements = try table.select("td")
                let teacher: String = try tds[1].text()
                let teacher_first: String = teacher.components(separatedBy:",")[1]
                let teacher_last: String = teacher.components(separatedBy:",")[0]
                teacherName = "\(teacher_first) \(teacher_last)"
                ClassInfoManager.shared.setClassData(classType: classType, type: .teacher, value: teacherName)
            } catch {
                print("Error")
            }
        }
        return teacherName
    }
        
    func getPoints() -> [Float] {
        var received: Float = 0.0
        var total: Float = 0.0
        
        if isUpdated {
            received = ClassInfoManager.shared.getClassData(classType: classType, type: .received) as! Float
            total = ClassInfoManager.shared.getClassData(classType: classType, type: .total) as! Float
        } else {
            do {
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
                received = recivedPoints
                total = totalPoints
                ClassInfoManager.shared.setClassData(classType: classType, type: .received, value: received)
                ClassInfoManager.shared.setClassData(classType: classType, type: .total, value: total)
            } catch {
                print("error")
            }
        }
        return [received, total]
    }
    
    func getPointsNeeded(total: Float, received: Float) -> [String] {
        
        if (total/received).isNaN {return ["", "", "", ""]}
        
        let grade: Float = round(Float(received/total)*100)
        let initialGradeLetter = Util.findGradeLetter(grade: Int(grade))
        
        var tempGradeLetter = initialGradeLetter
        var tempgrade = Float(grade)
        
        var pointsAddedPercent: Float = 0.0
        var pointsAddedLetter: Float = 0.0
        
        if grade < 100 {
            while Int(grade) == Int(tempgrade) {
                pointsAddedPercent += 1.0
                tempgrade = round(Float((pointsAddedPercent + received)/(pointsAddedPercent + total))*100)
            }
        }
        
        if initialGradeLetter != "A" {
            while initialGradeLetter == tempGradeLetter {
                pointsAddedLetter += 1.0
                let tempgrade1 = round(Float((pointsAddedLetter + received)/(pointsAddedLetter + total))*100)
                tempGradeLetter = Util.findGradeLetter(grade: Int(tempgrade1))
            }
        }
        ClassInfoManager.shared.setClassData(classType: classType, type: .needPointsLetter, value: pointsAddedLetter)
        ClassInfoManager.shared.setClassData(classType: classType, type: .needPointsPercent, value: pointsAddedPercent)

        return [String(tempgrade), String(pointsAddedPercent), String(tempGradeLetter), String(pointsAddedLetter)]
    }
    
    
    func getAssignments() -> RealmSwift.List<Assignments> {
        if isUpdated == false {
            do {
                let main: Element = try doc.select(".xteContentWrapper")[0]
                let ngscope: Element = try main.select(".ng-scope")[0]
                let trs: Elements = try ngscope.select("tr")
                for tr in trs {
                    let tds: Elements = try tr.select("td")
                    if tds.size() < 10 {continue}
                    let date: String = try tds[0].text()
                    let category: String = try tds[1].text()
                    let name: String = try tds[2].select("span").text()
                    let score: String = try tds[10].text()
                    let customid = "\(name)_\(date)"
                    guard let dataAssignment = ClassInfoManager.shared.realm!.object(ofType: Assignments.self, forPrimaryKey: customid) else {
                        let assignment = Assignments(name: name, score: score, flags: getAssignemntFlags(tds: tds), date: date, category: category)
                        ClassInfoManager.shared.setClassData(classType: classType, type: .assignments, value: assignment)
                        continue
                    }
                    if dataAssignment.score != score || dataAssignment.flags != getAssignemntFlags(tds: tds) || dataAssignment.date != date || dataAssignment.category != category {
                        ClassInfoManager.shared.updateAssignment(classType: classType, customid: customid, newScore: score, flags: getAssignemntFlags(tds: tds), date: date, category: category)
                    }
                }
            } catch {
                print("Error")
            }
        }
        AccountManager.global.assignments = ClassInfoManager.shared.getClassData(classType: classType, type: .assignments) as? RealmSwift.List<Assignments> ?? RealmSwift.List<Assignments>()
        return ClassInfoManager.shared.getClassData(classType: classType, type: .assignments) as! RealmSwift.List<Assignments>
    }
   
    private func getAssignemntFlags(tds : Elements) -> String {
        var flags: String = ""
        do {
            for i in 3...9 {
                let div = try tds[i].select(".ps-icon")
                if div.count > 0 {flags += String(i)}
            }
        } catch {print("Error")}
        return flags
    }
}

extension ClassInfoController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let assignments = AccountManager.global.assignments
        if assignments.count < 3 {
            return assignments.count }
        else{return 3}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let assignments = AccountManager.global.assignments
        tableView.separatorColor = .darkGray
        let cell = myTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .black
    
        var cellConfig = cell.defaultContentConfiguration()
        cellConfig.textProperties.numberOfLines = 0
        cellConfig.textProperties.lineBreakMode = .byWordWrapping
        cellConfig.textProperties.color = .white
        cellConfig.textProperties.font = UIFont(name: "Verdana Bold", size: 15)!
        let assignment = assignments[indexPath.row]
        cellConfig.text = "\(assignment.name) (\(assignment.score))"
        cell.contentConfiguration = cellConfig
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tabController = Storyboards.shared.tabBarController() else { return }
        tabController.animateToTab(tab: self.tabBarController!, toIndex: 1)

    }
}

extension Float {
    var clean : String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
