//
//  AssignmentViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 10/22/22.
//

import UIKit
import RealmSwift

class AssignmentViewController: UIViewController {
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
        
        if UserDefaults.standard.bool(forKey: "nate-mode") {
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: "Nate")
            assignmentTable.backgroundView = imageView
        }
    }
    
    func addTableHeader() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        let action = UIAction(title: "Assignment Calculator") { _ in
            guard let assignmentAddVC = Storyboards.shared.assignmentCalculatorViewController() else {return}
            self.navigationController?.pushViewController(assignmentAddVC, animated: true)
        }
        let button = UIButton(frame: CGRect(x: 00, y: 15, width: view.frame.width, height: 50), primaryAction: action)
        button.layer.cornerRadius = 5
        button.backgroundColor = .black
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        button.titleLabel?.text = "Assignment Calculator"
        button.setTitleColor(Util.getThemeColor(), for: .normal)
        containerView.addSubview(button)
        assignmentTable.tableHeaderView = containerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        addTableHeader()
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
            if !dates.contains(assignment.date) { dates.append(assignment.date) }
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
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width-10, height: 85))
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 35, weight: .heavy)
        lbl.text = " \(tableSortedList[section].date)"
        return lbl
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 50}
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .darkGray
        let cell = assignmentTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableCellView
        let assignment = tableSortedList[indexPath.section].assignments[indexPath.row]
        
        cell.nameLabel.text = "\(assignment.name)"
        cell.scoreLabel.text = "\(assignment.score)"
        cell.percentLabel.text = "\(Int(Util.convertScoreToGrade(score: assignment.score)))%"
        cell.flagLabel.attributedText = getFlagColors(assignment: assignment)
        cell.selectionStyle = .none
        return cell
    }
    
    func getFlagColors(assignment: Assignments) -> NSMutableAttributedString {
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
        return myMutableString
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let assignment = tableSortedList[indexPath.section].assignments[indexPath.row]

        guard let assignmentDetailVC = Storyboards.shared.assignmentDetailViewController() else { return }
        
        if let sheet = assignmentDetailVC.sheetPresentationController {sheet.detents = [.medium(), .large()]}
        present(assignmentDetailVC, animated: true, completion: nil)
        
        assignmentDetailVC.dateLabel.text = tableSortedList[indexPath.section].date
        assignmentDetailVC.nameLabel.text = assignment.name
        assignmentDetailVC.scoreLabel.text = assignment.score
        assignmentDetailVC.percentLabel.text = "\(Util.convertScoreToGrade(score: assignment.score))%"
        assignmentDetailVC.categoryLabel.text = assignment.category
        assignmentDetailVC.flagLabel.attributedText = convertFlagToNameAndColor(flags: assignment.flags)
    }
    
    func convertFlagToNameAndColor(flags: String) -> NSMutableAttributedString {
        let finalString: NSMutableAttributedString = NSMutableAttributedString(string: " ", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir Next Bold", size: 16)!])
        var flagsList: [NSMutableAttributedString] = []
        for flag in flags {
            let test = "\(Util.getFlagName(flag: String(flag)))"
            let myMutableString = NSMutableAttributedString(string: test)
            myMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: Util.setFlagColor(flag: String(flag)), range: NSRange(location:0,length:test.count))
            flagsList.append(myMutableString)
        }
        let seperator = NSMutableAttributedString(string: " , ", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir Next Bold", size: 16)!])
        seperator.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: NSRange(location:0,length:3))
        for (i,list) in flagsList.enumerated() {
            finalString.append(list)
            if i < flagsList.count - 1 { finalString.append(seperator) }
        }
        return finalString
    }
  
}

class AssignmentDetailViewController:UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
}

class Section {
    let title: String
    let options: [String]
    var isOpened: Bool = false
    
    init(title: String, options: [String], isOpened: Bool) {
        self.title = title
        self.options = options
        self.isOpened = isOpened
    }
}


class AssignmentCalculatorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var assignments = RealmSwift.List<Assignments>()
    var labelList: [UILabel] = []
    @IBOutlet weak var table: UITableView!
    
    private var sections = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        table.dataSource = self
        table.delegate = self
        
        if UserDefaults.standard.bool(forKey: "nate-mode") {
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: "Nate")
            table.backgroundView = imageView
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        assignments = AccountManager.global.assignments
        addPointCalculator()
    }
    func addPointCalculator() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 80))
        let pointTextField = UITextField(frame: CGRect(x: 10, y: 0, width: view.frame.width-200, height: 30))
        pointTextField.backgroundColor = .white
        pointTextField.textColor = .black
        pointTextField.attributedPlaceholder = NSAttributedString(
            string: "Points of Assignment",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        pointTextField.borderStyle = UITextField.BorderStyle.roundedRect
        pointTextField.font = UIFont(name: "Avenir Next Bold", size: 16)
        
        let action = UIAction(title: "title") { _ in
            let points = Int(pointTextField.text ?? "") ?? 0
            if points == 0 { return}
            self.calculate(value: points)
            
            pointTextField.text = ""
        }
    
        let addButton = UIButton(frame: CGRect(x: view.frame.width-170-10, y: 0, width: 170, height: 30), primaryAction: action)
        addButton.setTitle("Calculate", for: .normal)
        addButton.backgroundColor = .black
        addButton.titleLabel?.textColor = .white
        addButton.titleLabel?.font = UIFont(name: "Avenir Next Bold", size: 18)
        addButton.layer.cornerRadius = 10
        containerView.addSubview(addButton)
        containerView.addSubview(pointTextField)
        table.tableHeaderView = containerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        
        if section.isOpened { return section.options.count + 1 }
        else { return 1 }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 { return 70 }
        else { return 50}
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sectionCell", for: indexPath) as! SectionTableViewCell
            cell.title.text = sections[indexPath.section].title
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath)
            cell.textLabel?.text = sections[indexPath.section].options[indexPath.row - 1]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            sections[indexPath.section].isOpened = !sections[indexPath.section].isOpened
            tableView.reloadSections([indexPath.section], with: .none)
        }
    }
    
    func calculate(value: Int) {
        sections = []
        let total = ClassInfoManager.shared.getClassData(classType: AccountManager.global.classType, type: .total) as! Float + Float(value)
        let recieved = ClassInfoManager.shared.getClassData(classType: AccountManager.global.classType, type: .received) as! Float
        
        for score in 0...value {
            let newRecieved = recieved + Float(score)
            let newGrade = (newRecieved/total) * 100
            
            sections.append(
                Section(title: "\(score)/\(value)",
                        options: ["New Points: \(newRecieved)/\(total)",
                                  "New Grade: \(String(format: "%.2f", newGrade))%"],
                        isOpened: false))
        }
        sections = sections.reversed()
        table.reloadData()

    }
}

class SectionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var flagLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
}

