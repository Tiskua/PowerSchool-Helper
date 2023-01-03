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
    @IBOutlet weak var aboutViewContainer: UIView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Verdana Bold", size: 12) ?? UIFont.systemFont(ofSize: 12)]
        segmentedControl.setTitleTextAttributes(titleTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(titleTextAttributes, for: .selected)
    }
    
    @IBAction func saveSettingsAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    
    @IBAction func didChangeSegment(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            aboutViewContainer.isHidden = true
            themeViewContainer.isHidden = true
            generalViewContainer.isHidden = false
        }
        else if sender.selectedSegmentIndex == 1 {
            aboutViewContainer.isHidden = true
            generalViewContainer.isHidden = true
            themeViewContainer.isHidden = false

        }
        else if sender.selectedSegmentIndex == 2 {
            generalViewContainer.isHidden = true
            themeViewContainer.isHidden = true
            aboutViewContainer.isHidden = false
        }
    }
}


class GeneralViewContainer: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var powerschoolURL: UITextField!
    @IBOutlet weak var hideClassesSwitch: UISwitch!
    @IBOutlet weak var autoLoginSwitch: UISwitch!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        powerschoolURL.delegate = self

        if UserDefaults.standard.value(forKey: "pslink") != nil {powerschoolURL.text = UserDefaults.standard.string(forKey: "pslink")}
        
        if let hideUG = UserDefaults.standard.value(forKey: "hide-ug-class") as? Bool {hideClassesSwitch.isOn = hideUG}
        if let autoLogin = UserDefaults.standard.value(forKey: "auto-login") as? Bool {autoLoginSwitch.isOn = autoLogin}

    }
    @IBAction func editedURL(_ sender: Any) {
        if powerschoolURL.text!.replacingOccurrences(of: " ", with: "") == "" {return}
        if UserDefaults.standard.string(forKey: "pslink") != powerschoolURL.text! {
            UserDefaults.standard.set(powerschoolURL.text!, forKey: "pslink")
            guard let url = URL(string: UserDefaults.standard.string(forKey: "pslink")!) else {return}
            WebpageManager.shared.webView.load(URLRequest(url: url))
            WebpageManager.shared.setPageLoadingStatus(status: .inital)
            
        }
    }
    @IBAction func toggleShowUngradedClasses(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "hide-ug-class")
    }
    
    @IBAction func toggleAutoLogin(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "auto-login")

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
    
    var bgImageSave = UIImage()
    var changedWallpaper = false

    override func viewDidLoad() {
        super.viewDidLoad()
        colorIndicator.backgroundColor = Util.getThemeColor()

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openColorPicker(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        gestureRecognizer.numberOfTouchesRequired = 1
        colorIndicator.addGestureRecognizer(gestureRecognizer)
        colorIndicator.isUserInteractionEnabled = true
        
        Util.loadImage(imageView: imageIndicator)
        
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
        Util.clearBackgroundImage(imageView: inst.viewController.backgroundImage)
        UserDefaults.standard.removeObject(forKey: "bg-image")
        imageIndicator.image = nil
    }
    
    @IBAction func changeMainWallpaper(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        Util.setThemeColor(color: color)
        colorIndicator.backgroundColor = color
        inst.viewController.changeThemeColor()
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        inst.viewController.setBackgroundImage(image: image)
                        inst1.infoViewController.backgroundImage.image = image
                        Util.saveImage(image: image)
                        self.imageIndicator.image = image
                    }
                }
            })
        }
    }
}

class AboutViewContainer: UIViewController {
    
}

