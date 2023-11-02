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
    @IBOutlet weak var invalidURL: UILabel!
    @IBOutlet weak var googleLoginBtnImg: UIImageView!
    var firstLogin = true
    
    let KeyChainManager = KeychainManager()
        
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButton.layer.cornerRadius = 10
        googleLoginBtnImg.layer.cornerRadius = 10
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        NotificationCenter.default.addObserver(self, selector: #selector(settingsUpdated(_:)), name: Notification.Name(rawValue: "saved.settings"), object: nil)
        
        usernameTextField.layer.borderColor = UIColor.darkGray.cgColor
        usernameTextField.layer.cornerRadius = 10
        usernameTextField.layer.borderWidth = 1
        
        passwordTextField.layer.borderColor = UIColor.darkGray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.layer.borderWidth = 1
        
        let googleLoginGesture = UITapGestureRecognizer(target: self, action: #selector(googleLoginAction))
        googleLoginBtnImg.addGestureRecognizer(googleLoginGesture)
        googleLoginBtnImg.isUserInteractionEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebpageManager.shared.isValidURL() { valid in
            DispatchQueue.main.async {
                self.loginButton.isEnabled = valid
                if valid == false {
                    self.invalidURL.isHidden = false
                    self.goToURLSetting()
                }
            }
        }
    }
    
    func goToURLSetting() {
        self.tabBarController?.selectedIndex = 4
    }
    
    @objc func settingsUpdated(_ notification: Notification) {
        invalidURL.isHidden = true
        invalidLogin.isHidden = true
        WebpageManager.shared.setPageLoadingStatus(status: .firstLogin)
        WebpageManager.shared.loadURL() { success in
            if success {
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
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
    
    @IBAction func loginAction(_ sender: UIButton) {
        invalidLogin.isHidden = true
        if let username = usernameTextField.text, let password = passwordTextField.text {
            AccountManager.global.username = username
            AccountManager.global.password = password
            UserDefaults.standard.set(username, forKey: "login-username")
            UserDefaults.standard.set("regular", forKey: "sign-in-type")

            KeychainManager().updatePassword(username: AccountManager.global.username, password: AccountManager.global.password)
            WebpageManager.shared.login(username: username, password: password)
            Util.showLoading(view: self.view)
        } else {
            invalidLogin.isHidden = false
        }
    }
    
    @objc func googleLoginAction() {
        invalidLogin.isHidden = true
        WebpageManager.shared.googleLogin()
        Util.showLoading(view: self.view)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "saved.settings"), object: nil)
    }
}

class GoogleSignInViewController: UIViewController {
    @IBOutlet weak var closeViewButton: UIButton!
    
    override func viewDidLoad() {
        self.title = "Sign In"
        view.insertSubview(WebpageManager.shared.webView, at: 0)
        closeViewButton.layer.cornerRadius = 10
        closeViewButton.layer.borderColor = UIColor.red.cgColor
        closeViewButton.layer.borderWidth = 2
    }
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
