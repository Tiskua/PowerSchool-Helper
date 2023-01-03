//
//  InfoViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/6/22.
//

import UIKit
import WebKit
import SwiftSoup
import GoogleMobileAds
import DropDown

struct inst1 {
    static var infoViewController: ClassListViewController = ClassListViewController()
}

class ClassListViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate {
    
    var selectedQuarter = 1
    let dropDown = DropDown()
    let quarterArray = ["Quarter 1", "Quarter 2", "Semester 1", "Quarter 3", "Final 1", "Quarter 4", "Semester2", "Year 1"]
    
    var selectedClass: [String:Any] = [:]
    
    let backgroundImage: UIImageView = {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.contentMode = .scaleAspectFill
        return backgroundImage
    }()
    
    private let banner: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-3940256099942544/6300978111"
        banner.load(GADRequest())
        return banner
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inst1.infoViewController = self
        
        if UserDefaults.standard.value(forKey: "quarter") != nil {selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")}
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        scrollView.delegate = self
        scrollView.indicatorStyle = .white
        view.insertSubview(backgroundImage, at: 0)
        setClassLabels(scrollView: scrollView, quater: selectedQuarter)
        if !Util.loadImage(imageView: backgroundImage) {scrollView.backgroundColor = UIColor(red: 22/255, green: 22/255, blue: 24/255, alpha: 1)}
        banner.rootViewController = self
        scrollView.addSubview(banner)
        addQuarterDropDown(scrollView: scrollView)
        banner.layer.cornerRadius = 5

    }

    
    func addQuarterDropDown(scrollView: UIScrollView) {
        let buttonWidth:CGFloat = view.frame.width/2
        let buttonYPos: CGFloat = 30
        
        let dropdownView = UIView(frame: CGRect(x: (view.frame.width/2)-(buttonWidth/2), y: buttonYPos, width: buttonWidth, height: 40))
        dropdownView.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
        dropdownView.layer.cornerRadius=15
        let dropdownLabel: UILabel = UILabel(frame: CGRect(x: (view.frame.width/2)-(buttonWidth/2), y: buttonYPos, width: buttonWidth, height: 40))
        dropdownLabel.backgroundColor = .clear
        dropdownLabel.textColor = Util.getThemeColor()
        dropdownLabel.font = UIFont(name: "Avenir Heavy", size: 25)
        dropdownLabel.textAlignment = .center

        dropDown.cellHeight = 70
        dropDown.anchorView = dropdownView
        dropDown.dataSource = quarterArray
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.topOffset = CGPoint(x: 0, y:-(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.direction = .bottom
        dropDown.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
        dropDown.textColor = .white
        dropDown.textFont = UIFont(name: "Avenir Heavy", size: 16)!
        dropDown.setupCornerRadius(15)
        dropDown.selectionAction = {(index: Int, item: String) in
            self.selectedQuarter = index+1
            UserDefaults.standard.set(self.selectedQuarter, forKey: "quarter")
            self.setQuarterLabel(label: dropdownLabel)
            self.clearInfo()
            self.setClassLabels(scrollView: scrollView, quater: self.selectedQuarter)
            self.showLoading(c_view: self.view)
        }
        self.setQuarterLabel(label: dropdownLabel)
        let dropdownButton = UIButton(frame: CGRect(x: (view.frame.width/2)-(buttonWidth/2), y: buttonYPos, width: buttonWidth, height: 40))
        dropdownButton.backgroundColor = .clear
        dropdownButton.addTarget(self, action: #selector(showDropDown), for: .touchUpInside)
        
        scrollView.addSubview(dropdownView)
        scrollView.addSubview(dropdownLabel)
        scrollView.addSubview(dropdownButton)
        view.addSubview(scrollView)
    }
    
    func setQuarterLabel(label: UILabel) {
        switch self.selectedQuarter {
            case 1: label.text = "Q1"
            case 2: label.text = "Q2"
            case 3: label.text = "S1"
            case 4: label.text = "Q3"
            case 5: label.text = "F1"
            case 6: label.text = "Q4"
            case 7: label.text = "S2"
            case 8: label.text = "Y1"
            default: label.text = "Q1"
        }
    }
    
    @objc func showDropDown() {
        dropDown.show()
    }

    @objc func clearInfo() {
        for _ in 0...15 {
            if let viewWithTag = self.view.viewWithTag(100) {viewWithTag.removeFromSuperview()}
            if let viewWithTag = self.view.viewWithTag(101) {viewWithTag.removeFromSuperview()}
            if let viewWithTag = self.view.viewWithTag(102) {viewWithTag.removeFromSuperview()}
            if let viewWithTag = self.view.viewWithTag(103) {viewWithTag.removeFromSuperview()}
            if let viewWithTag = self.view.viewWithTag(104) {viewWithTag.removeFromSuperview()}
            if let viewWithTag = self.view.viewWithTag(105) {viewWithTag.removeFromSuperview()}

        }
    }
    
    
    func openClass(href:String) {
        WebpageManager.shared.webView.evaluateJavaScript("window.location.href='\(href)'")
    }
    
    func showLoading(c_view: UIView) {
        let loadingBG = UIView(frame: CGRect(x: 0, y: 0, width: c_view.frame.width, height: c_view.frame.height))
        loadingBG.backgroundColor = .black
        loadingBG.layer.opacity = 0.8
        loadingBG.tag = 200
        c_view.addSubview(loadingBG)
        
        let spinningCircleView = RotatingCirclesView()
        spinningCircleView.frame = CGRect(x: view.center.x-50, y: view.center.y-50, width: 100, height: 100)
        view.addSubview(spinningCircleView)
        spinningCircleView.tag = 201
        spinningCircleView.animate()
    }
    
    func hideLoading() {
        if let viewWithTag = self.view.viewWithTag(200) {viewWithTag.removeFromSuperview()}
        if let viewWithTag = self.view.viewWithTag(201) {viewWithTag.removeFromSuperview()}
    }
    
    @objc func buttonAction(sender: UIButton!, c: Int) {
        if WebpageManager.shared.getPageLoadingStatus() != .main && NetworkMonitor.shared.isConnected {return}
        for c in ClassDataManager.shared.classes_info {
            if c["class_name"] as? String == sender.title(for: .normal) {
                
                let href: String = ClassDataManager.shared.getClassData(className: c["class_name"] as! String, type: "href") as! String
                selectedClass = c
                showLoading(c_view: self.view)
                if NetworkMonitor.shared.isConnected{ openClass(href: href)}
                else {
                    selectClass()
                }

                break
                
            }
        }
    }

    func selectClass() {
        guard let classViewController = self.storyboard?.instantiateViewController(withIdentifier: "ClassInfoController") as? ClassInfoController else {return}
        classViewController.modalPresentationStyle = .overFullScreen
        classViewController.modalTransitionStyle = .crossDissolve
        classViewController.loadViewIfNeeded()
        classViewController.setClassLabel(text: selectedClass["class_name"] as! String)
        classViewController.setGPALabel(grade: selectedClass["grade"] as! Int)
        classViewController.setPointsLabel()
        self.present(classViewController, animated: true, completion:nil)
        hideLoading()
    }
    
    func getClassName(text: String) -> String {
        let textArray = text.components(separatedBy: "Email")
        let className = textArray[0].trimmingCharacters(in: .whitespacesAndNewlines)
        return className
    }
    

    func setClassLabels(scrollView: UIScrollView, quater: Int) {
        clearInfo()
        if !NetworkMonitor.shared.isConnected {
            print(ClassDataManager.shared.classes_info.count)
            var ypos = 150
            for classData in ClassDataManager.shared.classes_info {
                if (classData["grade"] as! Int == -1) {
                    if UserDefaults.standard.bool(forKey: "hide-ug-class") {continue}
                }
                addLabels(className: classData["class_name"] as! String, grade: classData["grade"] as! Int, scrollView: scrollView, ypos: ypos)
                ypos += 120
            }
            setInfoLables(scrollView: scrollView, ypos: ypos)
            return
        }
       
        WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let trs: Elements = try doc.select("tr")
                let length = trs.size()-10
                
                var ypos = 150
                for i in 0...length {
                    let tds: Elements = try trs[2+i].select("td")
                    let text:String = try tds[11].text()
                    
                    let classname = getClassName(text: text)
                    
                    let quarterIndex = 11+quater
                    if tds[quarterIndex].hasClass("notInSession") {continue}
                    let link = try tds[quarterIndex].select("a").first()!
                    let href:String = try link.attr("href")
                    
                    var numGradeVal = -1
                    var numWeightedGradeVal = -1
                    
                    let gradeval = try tds[quarterIndex].text()
                    if (gradeval == "[ i ]") {
                        if UserDefaults.standard.bool(forKey: "hide-ug-class") {continue}
                    } else {
                        numGradeVal = Int(gradeval.split(separator: " ")[0]) ?? -1
                        numWeightedGradeVal = Int(gradeval.split(separator: " ")[1]) ?? -1
                    }

                    ClassDataManager.shared.setClassData(className: classname, grade: numGradeVal, weightedGrade: numWeightedGradeVal,  href: href)
                    addLabels(className: classname, grade: numGradeVal, scrollView: scrollView, ypos: ypos)
                    
                    ypos += 120
                    
                }
                setInfoLables(scrollView: scrollView, ypos: ypos)
                
        
            } catch {
                print("error")
            }
        }
    }
    
    func setInfoLables(scrollView: UIScrollView, ypos: Int) {
        let overallGPALabel = UILabel(frame: CGRect(x: 20, y: 90, width: view.frame.width-20, height: 40))
        overallGPALabel.textColor = Util.getThemeColor()
        overallGPALabel.font = UIFont(name: "Avenir Heavy", size: 30)
        overallGPALabel.tag = 105
        scrollView.addSubview(overallGPALabel)
        
        var grades: [Int] = []
        for c in ClassDataManager.shared.classes_info {
            if c["grade"] as! Int == -1 {continue}
            grades.append(c["grade"] as! Int)
        }
        let oGPA: String = Util.findOverallGPA(gradeList: grades).isNaN ? "Unknown" : String(Util.findOverallGPA(gradeList: grades))
        overallGPALabel.text = "Overall GPA: \(oGPA)"
        
        let buttonWidth:CGFloat = view.frame.width/2
    
        let logOutButton = UIButton(frame: CGRect(x: buttonWidth-(buttonWidth/2), y: CGFloat(ypos+10), width: buttonWidth, height: 40))
        logOutButton.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
        logOutButton.setTitle("Log Out", for: .normal)
        logOutButton.setTitleColor(.red, for: .normal)
        logOutButton.titleLabel?.font = UIFont(name: "Avenir Heavy", size: 18)
        logOutButton.addTarget(self, action: #selector(logOutAction), for: .touchUpInside)
        logOutButton.layer.cornerRadius = 15
        logOutButton.tag = 104
        scrollView.addSubview(logOutButton)
        banner.frame = CGRect(x: 0, y: CGFloat(ypos + 80), width: scrollView.frame.size.width, height: 50).integral
        scrollView.contentSize.height = view.frame.size.height+1
        
        if ypos > 150 {scrollView.contentSize.height = CGFloat(ypos) + 120}
        hideLoading()
    }
    
    
    func addLabels(className: String, grade: Int, scrollView: UIScrollView, href: String = "", ypos: Int) {
        let button_width = Int(view.frame.size.width-40)
        let xpos = Int(view.frame.size.width)/2-(button_width/2)
                
        let class_view = UIView(frame: CGRect(x: xpos, y: ypos, width: (button_width), height: 100))
        class_view.backgroundColor = Util.getThemeColor()
        class_view.layer.cornerRadius = 10
        class_view.tag = 100
        class_view.layer.shadowColor = UIColor.black.cgColor
        class_view.layer.shadowOpacity = 0.6
        class_view.layer.shadowOffset = CGSize(width: 5, height: 5)
        
        let button = UIButton(frame: CGRect(x: xpos, y: ypos, width: (button_width), height: 100))
        button.backgroundColor = .clear
        button.titleLabel?.layer.opacity = 0.0
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.tag = 101
        
        let classNameLabel = UILabel(frame: CGRect(x: xpos+10, y: ypos, width: (button_width/2)+50, height: 100))
        classNameLabel.font = UIFont(name: "Avenir Heavy", size: 24)
        classNameLabel.lineBreakMode = .byWordWrapping
        classNameLabel.numberOfLines = 2
        classNameLabel.tag = 102
        
        
        let classGradeLabel = UILabel(frame: CGRect(x: xpos+button_width-70, y: ypos, width: 70, height: 100))
        classGradeLabel.font = UIFont(name: "Avenir Heavy", size: 20)
        classGradeLabel.tag = 103
        
        
        if grade >= 93 {classGradeLabel.textColor = UIColor(red: 120/255, green: 190/255, blue: 33/255, alpha: 1)}
        else if grade >= 85 {classGradeLabel.textColor = UIColor(red: 191/255, green: 64/255, blue: 191/255, alpha: 1)}
        else if grade >= 75 {classGradeLabel.textColor = UIColor(red: 255/255, green: 191/255, blue: 0/255, alpha: 1)}
        else if grade >= 65 {classGradeLabel.textColor = UIColor(red: 24/255, green: 88/255, blue: 88/255, alpha: 1)}
        else if grade <= 64 && grade > -1 {classGradeLabel.textColor = UIColor(red: 182/255, green: 5/255, blue: 5/255, alpha: 1)}

        classNameLabel.text = String(className)
        classGradeLabel.text = grade > -1 ? "\(grade)%" : "__%"
        
        if Util.compareColor(color: Util.getThemeColor(), withColor: classGradeLabel.textColor, withTolerance: 0.15) {
            classGradeLabel.layer.shadowColor = UIColor.black.cgColor
            classGradeLabel.layer.shadowOpacity = 0.9
            classGradeLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        }
        button.setTitle(className, for: .normal)

        scrollView.addSubview(class_view)
        scrollView.addSubview(classNameLabel)
        scrollView.addSubview(classGradeLabel)
        scrollView.addSubview(button)
    }
    
    @objc func logOutAction() {
        WebpageManager.shared.setPageLoadingStatus(status: .signOut)
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('btnLogout').click()")
        self.dismiss(animated: true)
    }
}
