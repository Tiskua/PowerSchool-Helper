//
//  QuarterSelectionController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 2/26/23.
//

import UIKit

class QuarterSelectionController: UIViewController {
    
    
    @IBOutlet var myTable: UITableView!
    
    let quarterList = ["Quarter 1", "Quarter 2", "Semester 1", "Quarter 3", "Final 1", "Quarter 4", "Semester2", "Year 1"]
    var selectedRow = UserDefaults.standard.integer(forKey: "quarter")-1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTable.delegate = self
        myTable.dataSource = self
        myTable.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebpageManager.shared.isLoopingClasses = false
        WebpageManager.shared.loadURL() { _ in } 

    }
        
}

extension QuarterSelectionController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quarterList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .darkGray
        let cell = myTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.text = quarterList[indexPath.row]
        cell.selectionStyle = .none
        
        if selectedRow == indexPath.row {
            cell.accessoryType = .checkmark
            cell.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
        }
        else {cell.accessoryType = .none}
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if selectedRow != indexPath.row {
            cell?.accessoryType = .checkmark
            cell?.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/55, alpha: 1)
            selectedRow = indexPath.row
            UserDefaults.standard.set(indexPath.row+1, forKey: "quarter")
            AccountManager.global.selectedQuarter = indexPath.row + 1
            WebpageManager.shared.loadURL() { _ in
                WebpageManager.shared.setPageLoadingStatus(status: .classList)
            }
            tableView.reloadData()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "quarter.selected"), object: nil)
            self.dismiss(animated: true)
        }
    }
    
}
