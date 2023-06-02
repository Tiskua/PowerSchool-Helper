//
//  SettingsViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/18/22.
//

import UIKit
import PhotosUI


class GeneralViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var powerschoolURL: UITextField!
    @IBOutlet weak var hideClassesSwitch: UISwitch!
    @IBOutlet weak var nateSwitch: UISwitch!
    @IBOutlet weak var developerSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        powerschoolURL.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        if let psLink = UserDefaults.standard.string(forKey: "pslink") { powerschoolURL.text = psLink }

        powerschoolURL.attributedPlaceholder = NSAttributedString(
            string: "PowerSchool URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        hideClassesSwitch.isOn = UserDefaults.standard.bool(forKey: "hide-ug-class")
        nateSwitch.isOn = UserDefaults.standard.bool(forKey: "nate-mode")
        developerSwitch.isOn = UserDefaults.standard.bool(forKey: "developer-mode")
    }

    @IBAction func changedURL(_ sender: Any) {
        if powerschoolURL.text!.replacingOccurrences(of: " ", with: "") == "" {return}
        if UserDefaults.standard.string(forKey: "pslink") != powerschoolURL.text! {
            UserDefaults.standard.set(powerschoolURL.text!, forKey: "pslink")
        }
    }

    @IBAction func toggleShowUngradedClasses(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "hide-ug-class")
    }
    @IBAction func toggleDeveloperMode(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "developer-mode")

    }
    @IBAction func toggleNateMode(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "nate-mode")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var changePictureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var profileImage = UIImage(named: "DefaultProfilePicture")
        if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
        profilePictureImageView.image = profileImage
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width/2
    }
    
    @IBAction func didTapChangeProfilePicture(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        pickerViewController.isEditing = true
       
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    DispatchQueue.main.async { self.present(pickerViewController, animated: true, completion: nil) }
                }
            })
        } else if PHPhotoLibrary.authorizationStatus() == .denied {
            let alert = UIAlertController(title: "Access Photos", message: "Allow acess to photos to change the wallpaper. Change in settings.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.present(pickerViewController, animated: true, completion: nil)

        }
    }
}

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        Util.saveImage(image: image, key: "profile-pic")
                        
                        self.profilePictureImageView.image = image
                    }
                }
            })
        }
    }
}

class WallpaperViewController: UIViewController, PHPickerViewControllerDelegate  {
    @IBOutlet weak var imageIndicator: UIImageView!
    @IBOutlet weak var bgOverlayOpacitySlider: UISlider!
    @IBOutlet weak var bgOverlayOpacityIndicator: UILabel!
    @IBOutlet weak var bgOverlayOnImageIndicator: UIView!
    
    override func viewDidLoad() {
        if let bgImage = Util.getImage(key: "bg-image") {
            imageIndicator.image = bgImage
        }
        if let backgroundOverlayOpacity = UserDefaults.standard.value(forKey: "background-overlay-opacity") as? Float {
            bgOverlayOpacitySlider.value = backgroundOverlayOpacity
        }
        bgOverlayOpacityIndicator.text = "\(Int(bgOverlayOpacitySlider.value * 100))%"
        bgOverlayOnImageIndicator.alpha = CGFloat(bgOverlayOpacitySlider.value)
    }
    
    @IBAction func setBGOverlayOpacity(_ sender: UISlider) {
        guard let classListVC = Storyboards.shared.classListViewController() else { return }
        UserDefaults.standard.set(sender.value, forKey: "background-overlay-opacity")
        classListVC.backgroundOverlay.backgroundColor = .black.withAlphaComponent(CGFloat(sender.value))
        bgOverlayOpacityIndicator.text = "\(Int(sender.value * 100))%"
        bgOverlayOnImageIndicator.alpha = CGFloat(bgOverlayOpacitySlider.value)
    }
    
    @IBAction func changeMainWallpaper(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        pickerViewController.isEditing = true
       
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    DispatchQueue.main.async { self.present(pickerViewController, animated: true, completion: nil) }
                }
            })
        } else if PHPhotoLibrary.authorizationStatus() == .denied {
            let alert = UIAlertController(title: "Access Photos", message: "Allow acess to photos to change the wallpaper. Change in settings.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.present(pickerViewController, animated: true, completion: nil)
        }
    
    }
    
    @IBAction func resetBGImage(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "bg-image")
        UserDefaults.standard.removeObject(forKey: "background-overlay-opacity")
        imageIndicator.image = nil
    }
    
  
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        Util.saveImage(image: image, key: "bg-image")
                        self.imageIndicator.image = image
                    }
                }
            })
        }
    }
}


class ColorViewController: UIViewController, UIColorPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var colorIndicator: UIView!
    @IBOutlet weak var gradeColorTable: UITableView!
    @IBOutlet weak var colorGradesSwitch: UISwitch!
    @IBOutlet weak var lightTextSwitch: UISwitch!
    
    var colorEditType = "theme"
    var selectedView = UIView()
    var selectedIndex = 0
    
    var gradeColorsNames: [[String : String]] = [["grade" : "A", "color" : UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1).colorToString()],
                                                 ["grade" : "B", "color" : UIColor(red: 100/255, green: 240/255, blue: 33/255, alpha: 1).colorToString()],
                                                 ["grade" : "C", "color" : UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1).colorToString()],
                                                 ["grade" : "D", "color" : UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1).colorToString()],
                                                 ["grade" : "F", "color" : UIColor(red: 182/255, green: 5/255, blue: 5/255, alpha: 1).colorToString()]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorIndicator.backgroundColor = Util.getThemeColor()
        
        if let savedGradeColors = UserDefaults.standard.array(forKey: "grade-colors") as? [[String : String]] {
            gradeColorsNames = savedGradeColors
        } 
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openColorPicker))

        colorIndicator.addGestureRecognizer(gestureRecognizer)
        colorIndicator.isUserInteractionEnabled = true
        
        gradeColorTable.delegate = self
        gradeColorTable.dataSource = self
        
        gradeColorTable.layer.cornerRadius = 10
        colorGradesSwitch.isOn = UserDefaults.standard.bool(forKey: "color-grades")
        if UserDefaults.standard.value(forKey: "light-text") == nil {
            UserDefaults.standard.set(true, forKey: "light-text")
        }
        lightTextSwitch.isOn = UserDefaults.standard.bool(forKey: "light-text")
    }
    
    @IBAction func toggleColorGrades(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "color-grades")
    }
    
    @IBAction func toggleLightText(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "light-text")

    }
    
    @IBAction func changeThemeColor(_ sender: Any) {
        colorEditType = "theme"
        openColorPicker(initialColor: Util.getThemeColor())
    }
    
    @objc func openColorPicker(initialColor: UIColor) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        colorPickerVC.selectedColor = initialColor
        
        present(colorPickerVC, animated: true)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color: UIColor = viewController.selectedColor
        if colorEditType == "theme" {
            Util.setThemeColor(color: color)
            colorIndicator.backgroundColor = color
        } else if colorEditType == "grade-color" {
            selectedView.backgroundColor = color
            gradeColorsNames[selectedIndex]["color"] = color.colorToString()
            UserDefaults.standard.set(gradeColorsNames, forKey: "grade-colors")
            gradeColorTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gradeColorsNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = gradeColorTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ColorGradeTableCell
        cell.name.text = "Change \(gradeColorsNames[indexPath.row]["grade"] ?? "_") Color"
        cell.colorView.backgroundColor = gradeColorsNames[indexPath.row]["color"]?.stringToColor()
        cell.colorView.layer.cornerRadius = 3
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = gradeColorTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ColorGradeTableCell
        colorEditType = "grade-color"
        selectedView = cell.colorView
        selectedIndex = indexPath.row
        openColorPicker(initialColor: cell.colorView.backgroundColor ?? .white)
    }
}

class ColorGradeTableCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var colorView: UIView!
}


class NotificationViewController: UIViewController {
    @IBOutlet weak var reportEnabledSwitch: UISwitch!
    @IBOutlet weak var reportDaysLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!

    override func viewDidLoad() {
        reportEnabledSwitch.isOn = UserDefaults.standard.bool(forKey: "reports-enabled")
        updateReportDays()
        
        let reportGesutre = UITapGestureRecognizer(target: self, action: #selector(showRepeatViewController))
        reportDaysLabel.addGestureRecognizer(reportGesutre)
        reportDaysLabel.isUserInteractionEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateReportDays), name: Notification.Name(rawValue: "report.days.changed"), object: nil)

        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        if let time = UserDefaults.standard.string(forKey: "reportTime") {
            let dateTime = formatter.date(from: time)!
            timePicker.date = dateTime
        } else {
            let dateTime = formatter.date(from: "3:00 pm")!
            timePicker.date = dateTime
        }
        timePicker.tintColor = .white
        timePicker.overrideUserInterfaceStyle = .dark
    
    }
    
    @IBAction func toggleReportsEnabled(_ sender: UISwitch) {
        if sender.isOn {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                if settings.authorizationStatus == .notDetermined {
                    NotificationManager.shared.registerForPushNotifications()
                } else if settings.authorizationStatus == .denied {
                    let alert = UIAlertController(title: "Allow Notifications", message: "Allow acess to Notifications to enable Reports. Change in settings.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                   }))
                } else if settings.authorizationStatus == .authorized {
                    UserDefaults.standard.set(sender.isOn, forKey: "reports-enabled")
                }
            })
        }
                                                                          
    }
    @IBAction func reportRepeatButtonAction(_ sender: Any) {
        showRepeatViewController()
    }
    
    @objc func updateReportDays() {
        reportDaysLabel.text = convertReportDaysToString()
        NotificationManager.shared.removePendingNotifications()
        NotificationManager.shared.scheduleNotification()

    }
    
    @objc func showRepeatViewController() {
        guard let repeatViewController = Storyboards.shared.repeatViewController() else { return }
        self.navigationController?.pushViewController(repeatViewController, animated: true)
    }
    
    func convertReportDaysToString() -> String {
        if let reportDays = UserDefaults.standard.array(forKey: "reportDays") as? [Int] {
            if reportDays.count == 0 { return "None"}
            var days = ""
            for day in reportDays.sorted() {
                var dayOfWeek = ""
                switch day {
                    case 0: dayOfWeek = "Sun"
                    case 1: dayOfWeek = "Mon"
                    case 2: dayOfWeek = "Tue"
                    case 3: dayOfWeek = "Wed"
                    case 4: dayOfWeek = "Thur"
                    case 5: dayOfWeek = "Fri"
                    case 6: dayOfWeek = "Sat"
                    default: dayOfWeek = "UK"
                }
                days += "\(dayOfWeek) "
            }
            return "\(days)".trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "None"
        }
    }
    
    @IBAction func didChangeTime(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        UserDefaults.standard.set(formatter.string(from: sender.date), forKey: "reportTime")
        timePicker.date = sender.date
        NotificationManager.shared.removePendingNotifications()
        NotificationManager.shared.scheduleNotification()
    }
}


class RepeatViewController: UIViewController {
    @IBOutlet weak var repeatTableView: UITableView!
    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var selectedRows: [Int] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        repeatTableView.layer.cornerRadius = 10
        
        if let reportDays = UserDefaults.standard.array(forKey: "reportDays") as? [Int] {
            selectedRows = reportDays
        }
        
        repeatTableView.dataSource = self
        repeatTableView.delegate = self
    }
}

extension RepeatViewController: UITableViewDelegate, UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        days.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = days[indexPath.item]
        content.textProperties.color = .white
        content.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        cell.accessoryType = selectedRows.contains(indexPath.row) ? .checkmark : .none
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if selectedRows.contains(indexPath.row) {
            let index = self.selectedRows.firstIndex(of: indexPath.row)
            self.selectedRows.remove(at: index!)
        } else {
            selectedRows.append(indexPath.row)
        }
        UserDefaults.standard.set(selectedRows, forKey: "reportDays")
        tableView.reloadData()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "report.days.changed"), object: nil)

    }
}

class SettingsCategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self

    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "saved.settings"), object: nil)
        }

    }
    var settingsCategories: [String] = ["General" , "Profile", "Wallpaper", "Color", "Notifications"]

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsCategories.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .darkGray
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.text = settingsCategories[indexPath.row]
        cell.selectionStyle = .none
        cell.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segue: String
        switch indexPath.row {
            case 0:
                segue = "generalSegue"
            case 1:
                segue = "profileSegue"
            case 2:
                segue = "wallpaperSegue"
            case 3:
                segue = "colorSegue"
            case 4:
                segue = "notificationSegue"
            default:
                segue = ""
                return
        }
        self.performSegue(withIdentifier: segue, sender: self)
    }
}

class HelpViewController: UIViewController {
    override func viewDidLoad() {
        self.sheetPresentationController?.prefersGrabberVisible = true
        super.viewDidLoad()
    }
}
