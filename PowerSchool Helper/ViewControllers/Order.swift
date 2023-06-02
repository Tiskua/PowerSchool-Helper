//
//  Order.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/7/23.
//

import UIKit

class OrderViewController: UIViewController {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var sortButton: UIBarButtonItem!

    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    var classList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedClassList = UserDefaults.standard.array(forKey: "class-order") as? [String] {
            classList = savedClassList}
        
        addDefaultClasses()
        
        table.layer.cornerRadius = 10
        table.dataSource = self
        table.delegate = self
        sortButton.tintColor = Util.getThemeColor()
        resetButton.tintColor = Util.getThemeColor()
    }
    
    func addDefaultClasses() {
        for c in ClassInfoManager.shared.getClassesData(username: AccountManager.global.username) {
            if !classList.contains(c.class_name) { classList.append(c.class_name) }
        }
    }

    @IBAction func didTapSort() {
        table.isEditing = !table.isEditing
        sortButton.title = table.isEditing ? "Done" : "Sort"
        if !table.isEditing {
            UserDefaults.standard.set(classList, forKey: "class-order")
            self.dismiss(animated: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "order.changed"), object: nil)
        }
    }
    
    @IBAction func didTapReset(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "class-order")
        classList = []
        addDefaultClasses()
        self.dismiss(animated: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "order.changed"), object: nil)
    }
}

extension OrderViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textColor = .white
        cell.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.text = classList[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        classList.swapAt(sourceIndexPath.row, destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
