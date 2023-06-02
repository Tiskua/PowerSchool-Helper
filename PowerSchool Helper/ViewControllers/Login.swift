//
//  ViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/2/22.
//

import UIKit
import WebKit
import SwiftSoup
import AuthenticationServices


class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var invalidLogin: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var pwHelperLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var invalidURL: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    
    var firstLogin = true
    
    let KeyChainManager = KeychainManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButton.layer.cornerRadius = 10
        settingsButton.layer.cornerRadius = 10
        changeThemeColor()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(self, selector: #selector(settingsUpdated(_:)), name: Notification.Name(rawValue: "saved.settings"), object: nil)
        
        usernameTextField.layer.borderColor = UIColor.darkGray.cgColor
        usernameTextField.layer.cornerRadius = 10
        usernameTextField.layer.borderWidth = 1
        
        passwordTextField.layer.borderColor = UIColor.darkGray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.layer.borderWidth = 1
        loginButton.setTitleColor(Util.getThemeColor().isLight() ?? true ? UIColor.black : UIColor.white, for: .normal)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebpageManager.shared.isValidURL() { valid in
            if valid == false {
                DispatchQueue.main.async {
                    self.invalidURL.isHidden = false
                    self.loginButton.isEnabled = false
                }
            } else {
                self.loginButton.isEnabled = true

            }
        }
    }
    
    @objc func settingsUpdated(_ notification: Notification) {
        invalidURL.isHidden = true
        invalidLogin.isHidden = true
        WebpageManager.shared.loadURL() { success in
            WebpageManager.shared.setPageLoadingStatus(status: .inital)
            DispatchQueue.main.async {
                if !success {
                    self.invalidURL.isHidden = false
                    self.loginButton.isEnabled = false
                } else {
                    self.invalidURL.isHidden = true
                    self.loginButton.isEnabled = true
                }
            }
        }
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        usernameTextField.attributedPlaceholder = NSAttributedString(
            string: "Username",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    public func changeThemeColor() {
        loginButton.backgroundColor = Util.getThemeColor()
        pwHelperLabel.textColor = Util.getThemeColor()
        let config = UIImage.SymbolConfiguration(pointSize: 25)
        let image: UIImage = (UIImage(systemName: "gearshape", withConfiguration: config))!
        settingsButton.configuration?.baseForegroundColor = Util.getThemeColor()
        settingsButton.setImage(image, for: .normal)
        settingsButton.tintColor = Util.getThemeColor()
    }
    
    @IBAction func openSettings(_ sender: Any) {
        guard let settingsVC = Storyboards.shared.settingsViewController() else {return}
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    

    @IBAction func loginAction(_ sender: UIButton) {
        invalidLogin.isHidden = true
        let username = usernameTextField.text ?? "UNKOWN"
        let password = passwordTextField.text ?? "UNKOWN"
        AccountManager.global.username = username
        AccountManager.global.password = password
        WebpageManager.shared.login(username: username, password: password)
        Util.showLoading(view: self.view)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

