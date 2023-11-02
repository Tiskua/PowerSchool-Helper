//
//  QuarterSelectionController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 2/26/23.
//

import UIKit
import SwiftSoup


class QuarterSelectionController: UIViewController {
    @IBOutlet var myTable: UITableView!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    var quarterList: [String] = []
    var selectedRow = UserDefaults.standard.integer(forKey: "quarter")-1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let storedQuarterList = UserDefaults.standard.array(forKey: "order-quarter-list") as? [String] {
            quarterList = storedQuarterList
        }
        myTable.delegate = self
        myTable.dataSource = self
        myTable.backgroundColor = .black
        sortButton.tintColor = Util.getThemeColor()
        resetButton.tintColor = Util.getThemeColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebpageManager.shared.isLoopingClasses = false
        
    }
    @IBAction func resetAction(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "order-quarter-list")
        WebpageManager.shared.setPageLoadingStatus(status: .refreshing)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        self.dismiss(animated: true)

    }
    
    @IBAction func didTapSort(_ sender: Any) {
        myTable.isEditing = !myTable.isEditing

        sortButton.title = myTable.isEditing ? "Done" : "Sort"
        if !myTable.isEditing {
            UserDefaults.standard.set(quarterList, forKey: "order-quarter-list")
        }
    }
}
    
extension QuarterSelectionController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quarterList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .darkGray
        let cell = myTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.text = quarterList[indexPath.row]
        cell.selectionStyle = .none
        
        if selectedRow == indexPath.row {
            cell.accessoryType = .checkmark
            cell.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if selectedRow != indexPath.row {
            cell?.accessoryType = .checkmark
            cell?.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 20/55, alpha: 1)
            selectedRow = indexPath.row
            AccountManager.global.selectedQuarter = indexPath.row + 1
            UserDefaults.standard.set(indexPath.row+1, forKey: "quarter")
            WebpageManager.shared.setPageLoadingStatus(status: .refreshing)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "quarter.selected"), object: nil)
            self.dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        quarterList.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        selectedRow = destinationIndexPath.row
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

}
