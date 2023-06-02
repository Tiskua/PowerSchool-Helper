//
//  Report.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/5/23.
//

import UIKit


class ReportVC: UIViewController, UIScrollViewDelegate {
    
    var scrollView = UIScrollView()
    var databaseClasses: [StudentClassData] = []
    var recentData: [[String : String]] = []
    var classListVC = ClassListViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AccountManager.global.selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        databaseClasses = ClassInfoManager.shared.getClassesData(username: AccountManager.global.username)
        if databaseClasses.isEmpty {
            self.dismiss(animated: true)
            return
        }
        for a in databaseClasses {
            if a.quarter != AccountManager.global.selectedQuarter { continue }
        }
        if let vc = Storyboards.shared.classListViewController() {
            classListVC = vc
        }
        scrollView.delegate = self
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        setMainLabels()
        setInfo()
        self.sheetPresentationController?.prefersGrabberVisible = true

    }


    func setMainLabels() {
        let gradeReportLabel = UILabel(frame: CGRect(x: 10, y: 30, width: view.frame.width, height: 50))
        gradeReportLabel.text = "Grade Report"
        gradeReportLabel.font = UIFont.systemFont(ofSize: 35, weight: .heavy)
        gradeReportLabel.textColor = .white
        
        let line = UIView(frame: CGRect(x: 0, y: 90, width: view.frame.width, height: 3))
        line.backgroundColor = .gray
        line.layer.cornerRadius = 3

        scrollView.addSubview(line)
        scrollView.addSubview(gradeReportLabel)
    }
    
    func setInfo() {
        classListVC.getClassesData() { gotData , data  in
            self.recentData = data
            self.setClassInfoLabels()
        }
    }
    func setClassInfoLabels() {
        var startY = 130
        for c in databaseClasses {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            let classBackground = UIView(frame: CGRect(x: 5, y: startY, width: Int(view.frame.width)-10, height: 100))
            classBackground.backgroundColor = Util.getThemeColor()
            classBackground.layer.cornerRadius = 10
            classBackground.alpha = 0.2
            
            let stringTapped = MyTapGesture.init(target: self, action: #selector(clickedClassButton(recognizer:)))
            stringTapped.className = c.class_name
            classBackground.addGestureRecognizer(stringTapped)

            let nameLabel = UILabel(frame: CGRect(x: 20, y: startY, width: Int(self.view.frame.width)/2+50, height: 100))
            nameLabel.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
            nameLabel.numberOfLines = 2
            nameLabel.textColor = .white
            nameLabel.text = c.class_name
            
            let gradeLabel = UILabel(frame: CGRect(x: Int(self.view.frame.width-self.view.frame.width/2)+100, y: startY, width: Int(self.view.frame.width/2)-60, height: 100))
            gradeLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            gradeLabel.textAlignment = .center
            gradeLabel.textColor = setGradeColor(c: c)
            for recent in recentData {
                if recent["className"] != c.class_name  { continue }
                gradeLabel.text = "\(recent["grade"]!)%"
                if gradeLabel.text == "-1" { gradeLabel.text = ""}
                break
            }
            if UserDefaults.standard.bool(forKey: "hide-ug-class") && gradeLabel.text == "" {
                continue
            }

            
            var symbolName = "line.diagonal"
            if setGradeColor(c: c) == UIColor.green { symbolName = "arrow.up" }
            else if setGradeColor(c: c) == UIColor.red { symbolName = "arrow.down" }
            
            let symbol = UIImage(systemName: symbolName)
            let symbolView = UIImageView(frame: CGRect(x: Int(self.view.frame.width-self.view.frame.width/2)+110, y: startY+35, width: 30, height: 30))
            symbolView.image = symbol
            symbolView.tintColor = setGradeColor(c: c)
            
            self.scrollView.addSubview(classBackground)
            self.scrollView.addSubview(symbolView)
            self.scrollView.addSubview(nameLabel)
            self.scrollView.addSubview(gradeLabel)
            startY += 130
        }
        setSrollHeight(ypos: startY)
    }
    
    func setGradeColor(c: StudentClassData) -> UIColor {
        for recent in recentData {
            if recent["className"] != c.class_name  { continue }
            let recentGrade = Int(recent["grade"]!) ?? -1
            if Int(recentGrade) < Int(c.grade) { return .red }
            else if Int(recentGrade) > Int(c.grade) { return .green }
            else { return .gray}
        }
        return .gray
    }
    
    func setSrollHeight(ypos: Int) {
        let bottomOffset: CGFloat = 200
        if CGFloat(ypos) + bottomOffset > view.frame.height {scrollView.contentSize.height = CGFloat(ypos) + bottomOffset}
        else {scrollView.contentSize.height = view.frame.height+20}
    }
    
    @objc func clickedClassButton(recognizer: MyTapGesture) {
        WebpageManager.shared.checkIfLoggedOut() { isLoggedOut in
            if isLoggedOut { return }
            for cl in ClassInfoManager.shared.getClassesData(username: AccountManager.global.username) {
                if cl.class_name == recognizer.className && cl.quarter == AccountManager.global.selectedQuarter {
                    WebpageManager.shared.isLoopingClasses = false
                    if AccountManager.global.updatedClasses.contains(cl.class_name) {
                        self.selectClass(className: cl.class_name, href: cl.href)
                        return
                    }
                    WebpageManager.shared.openClass(href: cl.href)
                    WebpageManager.shared.checkForAssignments() { success in
                        if success { self.selectClass(className: cl.class_name, href: cl.href) }
                    }
                    break
                }
            }
        }
    }
     
    func selectClass(className:String, href: String) {
        AccountManager.global.selectedClass = className
        AccountManager.global.selectedhref = href
        AccountManager.global.classType = ClassType(username: AccountManager.global.username, className: className, quarter: AccountManager.global.selectedQuarter, href: href)
        guard let tabBar = Storyboards.shared.tabBarController() else {return}
        self.present(tabBar, animated: true)
    }
}
