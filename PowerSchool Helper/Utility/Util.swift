//
//  Util.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/28/22.
//

import UIKit

class Util {
    public static func setThemeColor(color: UIColor) {
        UserDefaults.standard.set(UIColorToString(color: color), forKey: "theme_color")
    }
    
    public static func getThemeColor() -> UIColor {
        if UserDefaults.standard.string(forKey: "theme_color") == nil {return UIColor(red: 22/255, green: 117/255, blue: 227/255, alpha: 1.0)}
        return StringToUIColor(color: UserDefaults.standard.string(forKey: "theme_color")!)
    }
    
    public static func setFlagColor(flag: String) -> UIColor {
        if flag == "4" {return UIColor(red: 235/255, green: 33/255, blue: 46/255, alpha: 1)
        } else if flag == "5" {return UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)
        } else if flag == "6" {return UIColor(red: 191/255, green: 64/255, blue: 191/255, alpha: 1)
        } else if flag == "8" {return UIColor(red: 191/255, green: 64/128, blue: 191/128, alpha: 1)}
        return .white
    }
    
    public static func UIColorToString(color: UIColor) -> String {
        let components = color.cgColor.components
        return "[\(components?[0] ?? 0), \(components?[1] ?? 0), \(components?[2] ?? 0), \(components?[3] ?? 0)"
    }
    
    public static func StringToUIColor(color: String) -> UIColor {
        let componentsString = color.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        let components = componentsString.components(separatedBy: ", ")
        return UIColor(
            red: CGFloat((components[0] as NSString).floatValue),
            green: CGFloat((components[1] as NSString).floatValue),
            blue: CGFloat((components[2] as NSString).floatValue),
            alpha: CGFloat((components[3] as NSString).floatValue))
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
        else if(grade >= 93) {GPA = 3.0}
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
    
    public static func clearBackgroundImage(imageView: UIImageView) {
        imageView.image = nil
    }
    
    public static func saveImage(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }
        let encoded = try! PropertyListEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: "bg-image")
    }

    @discardableResult public static func loadImage(imageView: UIImageView) -> Bool {
         guard let data = UserDefaults.standard.data(forKey: "bg-image") else { return false}
         let decoded = try! PropertyListDecoder().decode(Data.self, from: data)
         let image = UIImage(data: decoded)
        imageView.image = image
        return true
    }
    
    public static func getMainVC() -> ViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as! ViewController
    }
    public static func getInfoVC() -> ClassInfoController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ClassInfoController") as! ClassInfoController
    }
    public static func getSettingsVC() -> SettingsViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
    }
    
    public static func compareColor(color: UIColor, withColor: UIColor, withTolerance: CGFloat) -> Bool {

        var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0;
        var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0;

        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1);
        withColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2);

        return abs(r1 - r2) <= withTolerance &&
            abs(g1 - g2) <= withTolerance &&
            abs(b1 - b2) <= withTolerance &&
            abs(a1 - a2) <= withTolerance;
    }
    
}
