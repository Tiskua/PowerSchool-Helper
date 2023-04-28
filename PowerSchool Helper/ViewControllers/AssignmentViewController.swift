//
//  AssignmentViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 10/22/22.
//

import UIKit
import RealmSwift

class AssignmentViewController: UIViewController, UIScrollViewDelegate {
    var scrollView = UIScrollView()
    var assignments = List<Assignments>()
    var tableSortedList: [AssignmentFormat] = []
    var classType = ClassType(username: "", className: "", quarter: 1, href: "")

    @IBOutlet weak var assignmentTable: UITableView!
    
    override func viewDidLoad() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Assignments", style: .plain, target: nil, action: nil)
        classType = AccountManager.global.classType
        assignments = AccountManager.global.assignments
        sort()
        assignmentTable.delegate = self
        assignmentTable.dataSource = self
        assignmentTable.backgroundColor = UIColor(red: 29/255, green: 29/255, blue: 32/255, alpha: 1)
    }

    func sort() {
        
        let sortedList = assignments.sorted {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let date1 = dateFormatter.date(from: $0.date)
            let date2 = dateFormatter.date(from: $1.date)
            return date1! < date2!
        }.reversed()
        
        
        var dates: [String] = []
        for assignment in sortedList {
            if !dates.contains(assignment.date) {
                dates.append(assignment.date)
            }
        }
        for date in dates {
            let assignmentList = List<Assignments>()
            for assignment in assignments {
                if assignment.date == date {
                    assignmentList.append(assignment)
                }
            }
            tableSortedList.append(AssignmentFormat(date: date, assignments: assignmentList))
        }
        tableSortedList.insert(AssignmentFormat(date: "-1/-1/-1", assignments: List<Assignments>()), at: 0)
    }
}


class AssignmentAdd: UIViewController, UIScrollViewDelegate {
    var assignments = RealmSwift.List<Assignments>()
    var scrollView = UIScrollView()
    var labelList: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = UIScrollView(frame: view.frame)
        scrollView.delegate = self
        view.addSubview(scrollView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assignments = AccountManager.global.assignments
        addPointCalculator()

    }
    
    func addPointCalculator() {
        let yPos:CGFloat = 0
        let pointTextField = UITextField(frame: CGRect(x: 10, y: yPos, width: view.frame.width-200, height: 35))
        pointTextField.backgroundColor = .white
        pointTextField.placeholder = "Points of Assignment"
        pointTextField.borderStyle = UITextField.BorderStyle.roundedRect
        pointTextField.font = UIFont(name: "Avenir Next Bold", size: 18)

        let action = UIAction(title: "title") { _ in
            
            self.clearLabels()
            let points = Int(pointTextField.text ?? "") ?? 0
            if points == 0 { return}
            self.calculate(value: points)
            
            pointTextField.text = ""
        }
        
        let addButton = UIButton(frame: CGRect(x: view.frame.width-170-10, y: yPos, width: 170, height: 35), primaryAction: action)
        addButton.setTitle("Calculate", for: .normal)
        addButton.backgroundColor = .black
        addButton.titleLabel?.textColor = .white
        addButton.titleLabel?.font = UIFont(name: "Avenir Next Bold", size: 18)
        addButton.layer.cornerRadius = 10
        scrollView.addSubview(addButton)
        scrollView.addSubview(pointTextField)
    }
    
    func calculate(value: Int) {
        let total = ClassInfoManager.shared.getClassData(classType: AccountManager.global.classType, type: .total) as! Float + Float(value)
        let recieved = ClassInfoManager.shared.getClassData(classType: AccountManager.global.classType, type: .received) as! Float
        
        let xpos: CGFloat = 10
        var ypos: CGFloat = CGFloat(70 + (50*value))
    
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: ypos + 200)
        for score in 0...value {
            let newRecieved = recieved + Float(score)
            let newGrade = (newRecieved/total) * 100
            let scoreLabel = UILabel(frame: CGRect(x: xpos, y: ypos, width: view.frame.width/3, height: 40))
            let pointsLabel = UILabel(frame: CGRect(x: view.frame.width/3, y: ypos, width: view.frame.width/3, height: 40))
            let gradeLabel = UILabel(frame: CGRect(x: (view.frame.width/3) * 2 - 10, y: ypos, width: view.frame.width/3, height: 40))

            let font = UIFont(name: "Avenir Next Demi Bold", size: 20)
            
            scoreLabel.text = "\(score)/\(value)"
            scoreLabel.textColor = .white
            scoreLabel.font = font
            scoreLabel.textAlignment = .left

            pointsLabel.text = "\(newRecieved)/\(total)"
            pointsLabel.textColor = .white
            pointsLabel.font = font
            pointsLabel.textAlignment = .center

            gradeLabel.text = "\(String(format: "%.2f", newGrade))%"
            gradeLabel.textColor = .white
            gradeLabel.font = font
            gradeLabel.textAlignment = .right
            
            scrollView.addSubview(scoreLabel)
            scrollView.addSubview(pointsLabel)
            scrollView.addSubview(gradeLabel)
            labelList.append(scoreLabel)
            labelList.append(pointsLabel)
            labelList.append(gradeLabel)

            ypos -= 50
        }
    }
    
    func clearLabels() {
        for label in labelList {
            label.removeFromSuperview()
        }
    }
    
    func addAssingmentLabels() {
        let xpos: CGFloat = 10
        var ypos: CGFloat = 80
        for assignment in assignments {
            let label = UILabel(frame: CGRect(x: xpos, y: ypos, width: self.view.frame.width-20, height: 60))
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 10
            label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 2
            label.textColor = .white
            
            let received = Double(assignment.score.split(separator: "/")[0]) ?? 0
            let total = Double(assignment.score.split(separator: "/")[1]) ?? 0
            let grade: Double = round(received / total * 10000) / 100
            label.text = "•  \(assignment.name) (\(assignment.score)" + (!grade.isInfinite ? " | \(grade)%)" : ")")
            
            scrollView.addSubview(label)
            ypos += 65
        }
        scrollView.contentSize = CGSize(width: view.frame.size.width, height: ypos + 80)
    }
}

extension AssignmentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSortedList[section].assignments.count
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableSortedList.count
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableSortedList[section].date == "-1/-1/-1" {
            let action = UIAction(title: "Assignment Calculator") { _ in
                guard let assignmentAddVC = self.storyboard?.instantiateViewController(withIdentifier: "AssignmentAdd") as? AssignmentAdd else {return}
                self.navigationController?.pushViewController(assignmentAddVC, animated: true)
            }
            let button = UIButton(frame: CGRect(x: 10, y: 0, width: view.frame.width-20, height: 50), primaryAction: action)
            button.layer.cornerRadius = 5
            button.backgroundColor = .black
            button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
            button.titleLabel?.text = "Assignment Calculator"
            button.setTitleColor(Util.getThemeColor(), for: .normal)
            return button
        } else {
            let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-10, height: 85))
            lbl.textColor = .white
            lbl.font = UIFont.systemFont(ofSize: 35, weight: .heavy)
            lbl.text = " \(tableSortedList[section].date)"
            return lbl
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 50}
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .darkGray
        let cell = assignmentTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCellView
        let assignment = tableSortedList[indexPath.section].assignments[indexPath.row]
        
        let received = Double(assignment.score.split(separator: "/")[0]) ?? 0
        let total = Double(assignment.score.split(separator: "/")[1]) ?? 0
        let grade: Double = round(received / total * 10000) / 100
        
        var flagString = ""
        var colors: [UIColor] = []
        for flag in assignment.flags {
        
            colors.append(Util.setFlagColor(flag: String(flag)))
            flagString += "• "
        }
        let myMutableString = NSMutableAttributedString(string: flagString, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 40, weight: .heavy)])
        for (i, color) in colors.enumerated() {
            myMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location:i*2,length:1))
        }

        cell.assignmentLabel.text = "\(assignment.name) (\(assignment.score)" + (!grade.isInfinite ? " | \(grade)%)" : ")")
        cell.flagLabel.attributedText = myMutableString
        cell.selectionStyle = .none
        return cell
    }
}

class AssignmentFormat {
    var date = ""
    var assignments = List<Assignments>()
         
    init(date: String, assignments: List<Assignments>) {
        self.date = date
        self.assignments = assignments
    }
}

class CustomTableCellView: UITableViewCell {
    @IBOutlet weak var assignmentLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
}

