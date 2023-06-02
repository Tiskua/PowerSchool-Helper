//
//  Util.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/28/22.
//

import UIKit
import SwiftSoup

class Util {
    public static func setThemeColor(color: UIColor) {
        UserDefaults.standard.set(color.colorToString(), forKey: "theme_color")
    }
    
    public static func getThemeColor() -> UIColor {
        let color =  UIColor(red: 22/255, green: 117/255, blue: 227/255, alpha: 1.0)
        guard let c = UserDefaults.standard.string(forKey: "theme_color") else {return color}
        return c.stringToColor()
    }
    
    public static func getFlagName(flag: String) -> String {
        if flag == "3" {return "Collected"
        } else if flag == "4" {return "Late"
        } else if flag == "5" {return "Missing"
        } else if flag == "6" {return "Exempt"
        } else if flag == "7" {return "Absent"
        } else if flag == "8" {return "Incomplete"
        } else if flag == "9" {return "Excluded" }
        return ""
    }
    
    public static func setFlagColor(flag: String) -> UIColor {
        if flag == "3" {return UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1)
        } else if flag == "4" {return UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        } else if flag == "5" {return UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)
        } else if flag == "6" {return UIColor.systemPurple
        } else if flag == "7" {return UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1)
        } else if flag == "8" {return UIColor(red: 173/255, green: 216/128, blue: 230/128, alpha: 1)
        } else if flag == "9" {return UIColor(red: 255/255, green: 140/255, blue: 0/255, alpha: 1)}
        return .white
    }
    
    
    public static func findGradeLetterSP(grade: Int) -> String {
        var grade_letter = "Unknown"
        if(grade >= 97) { grade_letter = "A+"}
        else if(grade >= 93) { grade_letter = "A"}
        else if(grade >= 90) { grade_letter = "A-"}
        else if(grade >= 87) { grade_letter = "B+"}
        else if(grade >= 83) {grade_letter = "B"}
        else if(grade >= 80) {grade_letter = "B-"}
        else if(grade >= 77) {grade_letter = "C+"}
        else if(grade >= 73) {grade_letter = "C"}
        else if(grade >= 70) {grade_letter = "C-"}
        else if(grade >= 67) {grade_letter = "D+"}
        else if(grade >= 65) {grade_letter = "D"}
        else if(grade < 65) {grade_letter = "F"}
        
        return grade_letter
    }
    public static func findGradeLetter(grade: Int) -> String {
        var grade_letter = "Unknown"
        if(grade >= 93) { grade_letter = "A"}
        else if(grade >= 83) {grade_letter = "B"}
        else if(grade >= 73) {grade_letter = "C"}
        else if(grade >= 65) {grade_letter = "D"}
        else if(grade < 65) {grade_letter = "F"}
        
        return grade_letter
    }
    
    public static func findGPA(grade: Int) -> Double {
        var GPA = 0.0
        if(grade >= 97){ GPA = 4.0}
        else if(grade >= 93) {GPA = 4.0}
        else if(grade >= 90) {GPA = 3.7}
        else if(grade >= 87) {GPA = 3.3}
        else if(grade >= 83) {GPA = 3.0}
        else if(grade >= 80) {GPA = 2.7}
        else if(grade >= 77) {GPA = 2.3}
        else if(grade >= 73) {GPA = 2.0}
        else if(grade >= 70) {GPA = 1.7}
        else if(grade >= 67) {GPA = 1.3}
        else if(grade >= 65) {GPA = 1.0}
        else if(grade < 65) {GPA = 0.0}
        return GPA
    }
    
    public static func findOverallGPA(gradeList: [Int]) -> Double {
        var points: Double = 0
        for grade in gradeList {
            let gpa: Double = findGPA(grade: grade)
            points += gpa
        }
        let GPA: Double = points/Double(gradeList.count)
        return round(100 * GPA) / 100
    }
    
    public static func saveImage(image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }
        let encoded = try! PropertyListEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: key)
    }

    public static func getImage(key: String) -> UIImage? {
        if let data = UserDefaults.standard.data(forKey: key) {
            let decoded = try! PropertyListDecoder().decode(Data.self, from: data)
            let image = UIImage(data: decoded)
            return image
        }
        return nil
    }
    
    public static func formatQuarterLabel() -> String {
        if let orderedList = UserDefaults.standard.array(forKey: "order-quarter-list") as? [String], orderedList.count > AccountManager.global.selectedQuarter  {
            return orderedList[AccountManager.global.selectedQuarter-1]
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "Quarter", with: "Q")
                .replacingOccurrences(of: "Year", with: "Y")
                .replacingOccurrences(of: "Semester", with: "S")
                .replacingOccurrences(of: "Final", with: "F")

        } else { return "UK"}
    }
    
    public static func showLoading(view: UIView) {
        let loadingBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        loadingBG.backgroundColor = .black
        loadingBG.layer.opacity = 0.8
        loadingBG.tag = 200
        view.addSubview(loadingBG)

        let loadingIndicator: ProgressView = {
            let progress = ProgressView(colors: [Util.getThemeColor()], lineWidth: 10)
                progress.translatesAutoresizingMaskIntoConstraints = false
                return progress
        }()
        loadingIndicator.frame = CGRect(x: view.center.x-50, y: view.center.y-50, width: 100, height: 100)
        loadingIndicator.animateStroke()
        loadingIndicator.animateRotation()
        loadingIndicator.tag = 201
        view.addSubview(loadingIndicator)
        view.isUserInteractionEnabled = false
    }
    
    public static func hideLoading(view: UIView) {
        while let viewWithTag = view.viewWithTag(200) {viewWithTag.removeFromSuperview()}
        while let viewWithTag = view.viewWithTag(201) {viewWithTag.removeFromSuperview()}
        view.isUserInteractionEnabled = true

    }
    
    public static func convertScoreToGrade(score: String) -> Double {
        let received = Double(score.split(separator: "/")[0]) ?? 0
        let total = Double(score.split(separator: "/")[1]) ?? 0
        let grade: Double = round(received / total * 10000) / 100
        if grade.isInfinite  { return received*100}
        return grade
    }
    
    public static func colorGrade(grade: Int) -> UIColor {
        var gradeColors: [[String : String]] = [["grade" : "A", "color" : UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1).colorToString()],
                                                     ["grade" : "B", "color" : UIColor(red: 100/255, green: 240/255, blue: 33/255, alpha: 1).colorToString()],
                                                     ["grade" : "C", "color" : UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1).colorToString()],
                                                     ["grade" : "D", "color" : UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1).colorToString()],
                                                     ["grade" : "F", "color" : UIColor(red: 182/255, green: 5/255, blue: 5/255, alpha: 1).colorToString()]]
        if let savedGradeColors = UserDefaults.standard.array(forKey: "grade-colors") as? [[String : String]] {
            gradeColors = savedGradeColors
        }
        if grade >= 93 { return gradeColors[0]["color"]!.stringToColor()}
        else if grade >= 85 { return gradeColors[1]["color"]!.stringToColor()}
        else if grade >= 75 { return gradeColors[2]["color"]!.stringToColor()}
        else if grade >= 65 { return gradeColors[3]["color"]!.stringToColor()}
        else if grade <= 64 && grade > -1 { return gradeColors[4]["color"]!.stringToColor()}
        
        return Util.getThemeColor().isLight()! ? .black : .white
    }
    
    public static func getTermOptions(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                guard let html = result as? String, error == nil else {return}
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let tr: Element = try doc.select("tr")[0]
                    let ths: Elements = try tr.select("th")
                    
                    let decimalCharacters = CharacterSet.decimalDigits
                    var newQuarterList: [String] = []
                    for th in ths {
                        let text = try th.text()
                        let decimalRange = text.rangeOfCharacter(from: decimalCharacters)
                        if decimalRange != nil {
                            newQuarterList.append(text.replacingOccurrences(of: "Q", with: "Quarter ")
                                .replacingOccurrences(of: "S", with: "Semester ")
                                .replacingOccurrences(of: "F", with: "Final ")
                                .replacingOccurrences(of: "Y", with: "Year "))
                        }
                    }
                    UserDefaults.standard.set(newQuarterList, forKey: "order-quarter-list")
                    completion(true)
                } catch {
                    print(error.localizedDescription)
                    completion(false)
                }
            }
        }
    }
}

class Storyboards {
    public static let shared = Storyboards()
    
    public let classInfoStoryboard =  UIStoryboard(name: "ClassInfo", bundle: nil)
    public let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    public let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
    public let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
    public let helpStoryboard = UIStoryboard(name: "Help", bundle: nil)
    public let assignmentsStoryboard = UIStoryboard(name: "Assignments", bundle: nil)

    public func loginViewController() -> LoginViewController? {
        return loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
    }
    public func classInfoViewController() -> ClassInfoController? {
        return classInfoStoryboard.instantiateViewController(withIdentifier: "ClassInfoController") as? ClassInfoController
    }
    public func settingsViewController() -> SettingsCategoryViewController? {
        return settingsStoryboard.instantiateViewController(withIdentifier: "SettingsCategoryViewController") as? SettingsCategoryViewController
    }
    public func classListViewController() -> ClassListViewController? {
        return mainStoryboard.instantiateViewController(withIdentifier: "ClassListViewController") as? ClassListViewController
    }
    public func tabBarController() -> TabBarController? {
        return classInfoStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController
    }
    public func orderViewController() -> OrderViewController? {
        return mainStoryboard.instantiateViewController(withIdentifier: "OrderViewController") as? OrderViewController
    }
    public func quarterSelectViewController() -> QuarterSelectionController? {
        return mainStoryboard.instantiateViewController(withIdentifier: "QuarterSelectionController") as? QuarterSelectionController
    }
    public func assignmentCalculatorViewController() -> AssignmentCalculatorViewController? {
        return assignmentsStoryboard.instantiateViewController(withIdentifier: "AssignmentCalculatorViewController") as? AssignmentCalculatorViewController
    }
    public func assignmentDetailViewController() -> AssignmentDetailViewController? {
        return assignmentsStoryboard.instantiateViewController(withIdentifier: "AssignmentDetailViewController") as? AssignmentDetailViewController
    }
    public func assignmentViewController() -> AssignmentViewController? {
        return assignmentsStoryboard.instantiateViewController(identifier: "AssignmentViewController") as? AssignmentViewController
    }
    public func repeatViewController() -> RepeatViewController? {
        return settingsStoryboard.instantiateViewController(identifier: "RepeatViewController") as? RepeatViewController
    }
    public func helpViewController() -> HelpViewController? {
        return helpStoryboard.instantiateViewController(identifier: "HelpViewController") as? HelpViewController
    }
    
    
}

extension UIColor {
    func isLight(threshold: Float = 0.5) -> Bool? {
        let originialCGColor = self.cgColor
        let RGBCGColor = originialCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else { return nil}
        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
            
    }
    
    func colorToString() -> String {
        let components = self.cgColor.components
        return "[\(components?[0] ?? 0), \(components?[1] ?? 0), \(components?[2] ?? 0), \(components?[3] ?? 0)"
    }
    
    func compareColor(withColor: UIColor, withTolerance: CGFloat) -> Bool {
        var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0;
        var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0;

        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1);
        withColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2);

        return abs(r1 - r2) <= withTolerance &&
            abs(g1 - g2) <= withTolerance &&
            abs(b1 - b2) <= withTolerance &&
            abs(a1 - a2) <= withTolerance;
    }
}

extension String {
    func stringToColor() -> UIColor {
        let componentsString = self.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        let components = componentsString.components(separatedBy: ", ")
        return UIColor(
            red: CGFloat((components[0] as NSString).floatValue),
            green: CGFloat((components[1] as NSString).floatValue),
            blue: CGFloat((components[2] as NSString).floatValue),
            alpha: CGFloat((components[3] as NSString).floatValue))
    }
}
