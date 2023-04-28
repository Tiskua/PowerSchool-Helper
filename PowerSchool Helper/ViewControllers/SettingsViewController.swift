//
//  SettingsViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/18/22.
//

import UIKit
import PhotosUI


class SettingsViewController: UIViewController  {
    
        
    @IBOutlet weak var themeViewContainer: UIView!
    @IBOutlet weak var generalViewContainer: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Verdana Bold", size: 12) ?? UIFont.systemFont(ofSize: 12)]
        segmentedControl.setTitleTextAttributes(titleTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
        self.sheetPresentationController?.prefersGrabberVisible = true
    }
    
    @IBAction func saveSettingsAction(_ sender: Any) {
        self.dismiss(animated: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "saved.settings"), object: nil)

    }
    
    
    @IBAction func didChangeSegment(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            themeViewContainer.isHidden = true
            generalViewContainer.isHidden = false
        }
        else if sender.selectedSegmentIndex == 1 {
            generalViewContainer.isHidden = true
            themeViewContainer.isHidden = false

        }
        else if sender.selectedSegmentIndex == 2 {
            generalViewContainer.isHidden = true
            themeViewContainer.isHidden = true
        }
    }
}


class GeneralViewContainer: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var powerschoolURL: UITextField!
    @IBOutlet weak var hideClassesSwitch: UISwitch!
    @IBOutlet weak var colorGradesSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        powerschoolURL.delegate = self

        if UserDefaults.standard.value(forKey: "pslink") != nil {powerschoolURL.text = UserDefaults.standard.string(forKey: "pslink")}

        powerschoolURL.attributedPlaceholder = NSAttributedString(
            string: "PowerSchool URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        hideClassesSwitch.isOn = UserDefaults.standard.bool(forKey: "hide-ug-class")
        colorGradesSwitch.isOn = UserDefaults.standard.bool(forKey: "color-grades")
    }
    
    @IBAction func editedURL(_ sender: Any) {
        if powerschoolURL.text!.replacingOccurrences(of: " ", with: "") == "" {return}
        if UserDefaults.standard.string(forKey: "pslink") != powerschoolURL.text! {
            UserDefaults.standard.set(powerschoolURL.text!, forKey: "pslink")
        }
    }
    @IBAction func toggleShowUngradedClasses(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "hide-ug-class")
    }
    @IBAction func toggleColorGrades(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "color-grades")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

class ThemeViewContainer: UIViewController, UIColorPickerViewControllerDelegate, PHPickerViewControllerDelegate {

    @IBOutlet weak var colorIndicator: UIView!
    @IBOutlet weak var imageIndicator: UIImageView!
    @IBOutlet weak var bgOverlayOpacitySlider: UISlider!
    @IBOutlet weak var bgOverlayOpacityIndicator: UILabel!
    
    @IBOutlet weak var bgOverlayOnImageIndicator: UIView!
    var bgImageSave = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        colorIndicator.backgroundColor = Util.getThemeColor()

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openColorPicker(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        colorIndicator.addGestureRecognizer(gestureRecognizer)
        colorIndicator.isUserInteractionEnabled = true
        
        Util.loadImage(imageView: imageIndicator) {_ in}
        
        if let backgroundOverlayOpacity = UserDefaults.standard.value(forKey: "background-overlay-opacity") as? Float {
            bgOverlayOpacitySlider.value = backgroundOverlayOpacity
        }
        bgOverlayOpacityIndicator.text = "\(Int(bgOverlayOpacitySlider.value * 100))%"
        bgOverlayOnImageIndicator.alpha = CGFloat(bgOverlayOpacitySlider.value)
        
    }
    
    @IBAction func changeThemeColor(_ sender: Any) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        colorPickerVC.selectedColor = Util.getThemeColor()
        present(colorPickerVC, animated: true)
    }
    
    @objc func openColorPicker(_ gesture: UITapGestureRecognizer) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.supportsAlpha = false
        colorPickerVC.selectedColor = Util.getThemeColor()
        
        present(colorPickerVC, animated: true)
    }
    
    @IBAction func resetBGImage(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "bg-image")
        UserDefaults.standard.removeObject(forKey: "background-overlay-opacity")

        imageIndicator.image = nil
    }
    
    @IBAction func changeMainWallpaper(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
       
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    DispatchQueue.main.async {
                        self.present(pickerViewController, animated: true, completion: nil)
                    }
                }
            })
        } else if PHPhotoLibrary.authorizationStatus() == .denied {
            let alert = UIAlertController(title: "Access Photos", message: "Allow acess to photos to change the wallpaper. Change in settings.", preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
            
            }))
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.present(pickerViewController, animated: true, completion: nil)

        }
    
    }
    
    
    @IBAction func setBGOverlayOpacity(_ sender: UISlider) {
        guard let classListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ClassListViewController") as? ClassListViewController else { return }
        UserDefaults.standard.set(sender.value, forKey: "background-overlay-opacity")
        classListVC.backgroundOverlay.backgroundColor = .black.withAlphaComponent(CGFloat(sender.value))
        bgOverlayOpacityIndicator.text = "\(Int(sender.value * 100))%"
        bgOverlayOnImageIndicator.alpha = CGFloat(bgOverlayOpacitySlider.value)
    }
    
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        Util.setThemeColor(color: color)
        colorIndicator.backgroundColor = color
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        Util.saveImage(image: image)
                        self.imageIndicator.image = image
                    }
                }
            })
        }
    }
}

class HelpViewController: UIViewController {
    @IBOutlet weak var loginImage: UIImageView!
    
    override func viewDidLoad() {
        self.sheetPresentationController?.prefersGrabberVisible = true
        super.viewDidLoad()
    }
}

