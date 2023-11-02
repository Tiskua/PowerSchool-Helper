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
    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var needPercentLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    @IBOutlet weak var needLetterLabel: UILabel!
    @IBOutlet weak var gradeLetterLabel: UILabel!
    @IBOutlet weak var unweightedGradeLabel: UILabel!
    @IBOutlet weak var weightedGradeLabel: UILabel!
    @IBOutlet weak var decimalGradeLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedClass = ""
    var selectedhref = ""
    
    var username = ""
    var password = ""
    
    var classType = AccountManager.global.classType
    var doc = SwiftSoup.Document("")
    
    let KeyChainManager = KeychainManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        selectedClass = AccountManager.global.selectedClass
        selectedhref = AccountManager.global.selectedhref
        classLabel.textColor = Util.getThemeColor()
            
        if NetworkMonitor.shared.isConnected {
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
                guard let html = result as? String, error == nil else {return}
                doc = try! SwiftSoup.parseBodyFragment(html)
                setClassInfo(doc: doc)
            }
        } else {
            setClassInfo()
        }
        
        configureNavBar()
        configureScrollView()
    }
    
    func configureNavBar() {
        let backBtnImage = UIImage(systemName: "arrow.backward.circle.fill")
        self.navigationController?.navigationBar.backIndicatorImage = backBtnImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backBtnImage
    }
    
    func configureScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.layer.cornerRadius = 10
    }
    
    func setConstraintSize() {
        if UIScreen.main.bounds.size.height <= 1500 {
            view.frame.size.height = (2/5)*UIScreen.main.bounds.height
        }
    }

    
    func setClassInfo(doc: SwiftSoup.Document = SwiftSoup.Document("")) {
        let classType = ClassType(username: AccountManager.global.username, className: selectedClass, quarter: AccountManager.global.selectedQuarter, href: selectedhref)
        let classData = ClassInfoSetData(isUpdated: false, classType: classType, doc: doc)
        
        if AccountManager.global.updatedClasses.contains("\(selectedClass)_\(AccountManager.global.selectedQuarter)") {
            classData.isUpdated = true }

        self.title = selectedClass

        classLabel.text = selectedClass
        gradeLetterLabel.text = classData.getGradeLetter()

        let grades = classData.getGrade()
        weightedGradeLabel.text = grades[1] == -1 ? "--" : "\(grades[1])%"
        unweightedGradeLabel.text = grades[0] == -1 ? "--" : "\(grades[0])%"
        if UserDefaults.standard.bool(forKey: "color-grades") {
            weightedGradeLabel.textColor = Util.colorGrade(grade: grades[1])
        }

        teacherLabel.text = "\(classData.getTeacher())"
   
        let points = classData.getPoints()

        pointsLabel.text = "\(points[0]) / \(points[1])"
        let needPointsData = classData.getPointsNeeded(total: DatabaseManager.shared.getClassData(classType: classType, type: .total) as! Float,
                                                       received: DatabaseManager.shared.getClassData(classType: classType, type: .received) as! Float)
        needPercentLabel.text =  "\(needPointsData[1]) (\(needPointsData[0]))"
        needLetterLabel.text = "\(needPointsData[3]) (\(needPointsData[2]))"
        
        let _ = classData.getAssignments()
        let decimalGradeValues = classData.getDetailedGrade(recieved: points[0], total: points[1])
        decimalGradeLabel.text = String(decimalGradeValues[1])
        
        WebpageManager.shared.setPageLoadingStatus(status: .classList)
        AccountManager.global.updatedClasses.append("\(selectedClass)_\(AccountManager.global.selectedQuarter)")
        
    
    }
    
}


class ClassInfoSetData {
    
    var classType = ClassType(username: "", className: "", quarter: 0, href: "")
    var doc = SwiftSoup.Document("")
    var isUpdated = false
    
    init(isUpdated: Bool, classType: ClassType, doc: SwiftSoup.Document) {
        self.isUpdated = isUpdated
        self.classType = classType
        self.doc = doc
    }
    
    
    
    
    func getGradeLetter() -> String {
        var unweightedGrade: Int = 0
        if isUpdated {
            unweightedGrade = DatabaseManager.shared.getClassData(classType: classType, type: .grade) as! Int
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
        DatabaseManager.shared.setClassData(classType: classType, type: .letterGrade, value: letterGrade)
        return letterGrade
    }
    
    func getGrade() -> [Int] {
        var unweightedGrade: Int = 0
        var weightedGrade: Int = 0
        if isUpdated {
            unweightedGrade = DatabaseManager.shared.getClassData(classType: classType, type: .grade) as! Int
            weightedGrade = DatabaseManager.shared.getClassData(classType: classType, type: .weightedGrade) as! Int
        } else {
            do {
                let table: Element = try doc.select(".linkDescList")[0]
                let tds: Elements = try table.select("td")
                let grade: String = try tds[4].text()
                unweightedGrade = Int(grade.suffix(4).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                weightedGrade = Int(grade.prefix(3).trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                
                DatabaseManager.shared.setClassData(classType: classType, type: .grade, value: unweightedGrade)
                DatabaseManager.shared.setClassData(classType: classType, type: .weightedGrade, value: weightedGrade)
            } catch {
                print(error.localizedDescription)
            }
        }
        return [unweightedGrade, weightedGrade]
    }
    
    func getDetailedGrade(recieved: Float, total: Float) -> [Float] {
        if (total/recieved).isNaN {return [0, 0]}
        let grade = DatabaseManager.shared.getClassData(classType: classType, type: .grade) as! Int
        let weightedGrade = DatabaseManager.shared.getClassData(classType: classType, type: .weightedGrade) as! Int
        let detailedGrade = round(recieved / total * 10000) / 100
        let weight = (weightedGrade-grade)%5 != 0 ? 0 : weightedGrade-grade
        DatabaseManager.shared.setClassData(classType: classType, type: .detailedGrade, value: detailedGrade)
        return [Float(detailedGrade), Float(detailedGrade + Float(weight))]
    }
    
    func getTeacher() -> String {
        var teacherName = ""
        if isUpdated {
            teacherName = DatabaseManager.shared.getClassData(classType: classType, type: .teacher) as! String
        } else {
            do {
                let table: Element = try doc.select(".linkDescList")[0]
                let tds: Elements = try table.select("td")
                let teacher: String = try tds[1].text()
                let teacher_first: String = teacher.components(separatedBy:",")[1]
                let teacher_last: String = teacher.components(separatedBy:",")[0]
                teacherName = "\(teacher_first) \(teacher_last)"
                DatabaseManager.shared.setClassData(classType: classType, type: .teacher, value: teacherName)
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
            received = DatabaseManager.shared.getClassData(classType: classType, type: .received) as! Float
            total = DatabaseManager.shared.getClassData(classType: classType, type: .total) as! Float
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
                DatabaseManager.shared.setClassData(classType: classType, type: .received, value: received)
                DatabaseManager.shared.setClassData(classType: classType, type: .total, value: total)
            } catch {
                print("error")
            }
        }
        return [received, total]
    }
    
    func getPointsNeeded(total: Float, received: Float) -> [String] {
        if (total/received).isNaN {return ["0", "0", "0", "0"]}
        
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
        DatabaseManager.shared.setClassData(classType: classType, type: .needPointsLetter, value: pointsAddedLetter)
        DatabaseManager.shared.setClassData(classType: classType, type: .needPointsPercent, value: pointsAddedPercent)

        return [String(tempgrade), String(pointsAddedPercent), String(tempGradeLetter), String(pointsAddedLetter)]
    }
    
    
    func getAssignments() -> RealmSwift.List<Assignments> {
        if isUpdated == false {
            do {
                let main: Element = try doc.select("tbody")[1]
                let trs: Elements = try main.select("tr")
                for tr in trs {
                    let tds: Elements = try tr.select("td")
                    if tds.size() < 10 {continue}
                    let date: String = try tds[0].text()
                    let category: String = try tds[1].text()
                    let name: String = try tds[2].select("span").text()
                    let score: String = try tds[10].text()
                    let customid = "\(name)_\(date)"

                    guard let dataAssignment = DatabaseManager.shared.realm!.object(ofType: Assignments.self, forPrimaryKey: customid) else {
                        let assignment = Assignments(name: name, score: score, flags: getAssignemntFlags(tds: tds), date: date, category: category)
                        DatabaseManager.shared.setClassData(classType: classType, type: .assignments, value: assignment)
                        continue
                    }
                    
                    if dataAssignment.score != score || dataAssignment.flags != getAssignemntFlags(tds: tds) || dataAssignment.date != date || dataAssignment.category != category {
                        DatabaseManager.shared.updateAssignment(classType: classType, customid: customid, newScore: score, flags: getAssignemntFlags(tds: tds), date: date, category: category)
                    }
                }
            } catch {
                print("Error")
            }
        }
        
        AccountManager.global.assignments = DatabaseManager.shared.getClassData(classType: classType, type: .assignments) as? RealmSwift.List<Assignments> ?? RealmSwift.List<Assignments>()
        
        return DatabaseManager.shared.getClassData(classType: classType, type: .assignments) as! RealmSwift.List<Assignments>
    }
   
    private func getAssignemntFlags(tds : Elements) -> String {
        var flags: String = ""
        do {
            for i in 3...9 {
                let div = try tds[i].select(".ps-icon")
                if div.count > 0 {flags += String(i)}
            }
        } catch { print("Error") }
        return flags
    }
}


extension Float {
    var clean : String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

class ClassSettingsViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var classNameLabel: UILabel!
    @IBOutlet weak var courseTypeTable: UITableView!
    
    let courseTypeOptions = ["Regular", "Honors/Advanced", "AP/IB", "College"]
    var currentCourseType = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentCourseType = DatabaseManager.shared.getClassData(classType: AccountManager.global.classType,
                                                                 type: .placement) as! String

        courseTypeTable.delegate = self
        courseTypeTable.dataSource = self
        courseTypeTable.layer.cornerRadius = 10

                
    }
}

extension ClassSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = courseTypeTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.text = courseTypeOptions[indexPath.row]
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        if currentCourseType == courseTypeOptions[indexPath.row] {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if currentCourseType != courseTypeOptions[indexPath.row] {
            cell?.accessoryType = .checkmark
            currentCourseType = courseTypeOptions[indexPath.row]
            DatabaseManager.shared.setClassData(classType: AccountManager.global.classType,
                                                 type: .placement,
                                                 value: courseTypeOptions[indexPath.row])
            courseTypeTable.reloadData()
        }
    }
}
