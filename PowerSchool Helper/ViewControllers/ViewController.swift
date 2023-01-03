//
//  ViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/2/22.
//

import UIKit
import WebKit
import GoogleMobileAds
import SwiftSoup

struct inst {
    static var viewController: ViewController = ViewController()
}

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, GADBannerViewDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var invalidLogin: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var pwHelperLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var invalidURL: UILabel!
    
    var firstLogin = true
    
    private let banner: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-3940256099942544/6300978111"
        banner.load(GADRequest())
        return banner
    }()
    
    let backgroundImage: UIImageView = {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.contentMode = .scaleAspectFill
        return backgroundImage
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        WebpageManager.shared.webView.navigationDelegate = self
        view.addSubview(WebpageManager.shared.webView)
        loadURL()
        
        loginButton.layer.cornerRadius = 10
        settingsButton.layer.cornerRadius = 10
            
        changeThemeColor()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        banner.rootViewController = self
        view.addSubview(banner)
        
        Util.loadImage(imageView: backgroundImage) 
        view.insertSubview(backgroundImage, at: 0)
        checkInternetConnection()
        inst.viewController = self
        if let classesData = UserDefaults.standard.value(forKey: "class_data_list") as? [[String : Any]] {
            ClassDataManager.shared.classes_info = classesData
        }
    }
    
    
    private func checkInternetConnection() {
        if NetworkMonitor.shared.isConnected == false{
            let alert = UIAlertController(title: "Internet Connection Failed", message: "You are currently not connected to an internet connection. Do you want to continue? The info will not be up to date or accurate.", preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "Try again", style: UIAlertAction.Style.default, handler: { _ in
                UserDefaults.standard.set(self.usernameTextField.text!, forKey: "username")
                UserDefaults.standard.set(self.passwordTextField.text!, forKey: "password")
                self.dismiss(animated: true)
                self.checkInternetConnection()
            }))
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                self.dismiss(animated: true)
                guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ClassListViewController") as? ClassListViewController else {return}
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        banner.frame = CGRect(x: 0, y: 60, width: view.frame.size.width, height: 50).integral
        banner.layer.cornerRadius = 5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func loadURL() {
        if UserDefaults.standard.string(forKey: "pslink") != nil {
            guard let url = URL(string: UserDefaults.standard.string(forKey: "pslink")!) else {return}
            WebpageManager.shared.webView.load(URLRequest(url: url))
            WebpageManager.shared.setPageLoadingStatus(status: .inital)
        }
    }
    
    func setBackgroundImage(image: UIImage) {
        backgroundImage.image = image
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
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else {return}
        self.present(vc, animated: true, completion:nil)
    }
    
    
    private func askToRemember() {
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ClassInfoController") as? ClassInfoController else {return}
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        let alert = UIAlertController(title: "Save Login Information", message: "Do you want to remember your username and password?", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in
            UserDefaults.standard.set(self.usernameTextField.text!, forKey: "username")
            UserDefaults.standard.set(self.passwordTextField.text!, forKey: "password")
            self.dismiss(animated: true)
            self.present(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
            self.dismiss(animated: true)
            self.present(vc, animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func fillInInfo() {
        if let _ = UserDefaults.standard.value(forKey: "username") as? String {
            usernameTextField.text = UserDefaults.standard.value(forKey: "username") as? String
            passwordTextField.text = UserDefaults.standard.value(forKey: "password") as? String
        }
        if UserDefaults.standard.bool(forKey: "auto-login") && firstLogin {
            login()
            firstLogin = false
        }
    }
    
    private func checkForAssignments() {
        var found = false
        DispatchQueue.global(qos: .background).async {
            while found == false {
                DispatchQueue.main.async {
                    WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                        guard let html = result as? String, error == nil else {return}
                        do {
                            let doc: Document = try SwiftSoup.parseBodyFragment(html)
                            let xte: Elements = try doc.select(".xteContentWrapper")
                            if xte.size() == 0 {
                                self.dismiss(animated: true)
                                WebpageManager.shared.setPageLoadingStatus(status: .inital)
                                self.loadURL()
                                found = true
                                return
                            }
                            let tbody: Elements = try xte[0].select(".ng-scope")
                            if tbody.count >= 3 {
                                found = true
                                WebpageManager.shared.setPageLoadingStatus(status: .classMenu)
                                inst1.infoViewController.selectClass()
                            }
                        } catch {print("ERROR WITH SWIFTSOUP")}
                    }
                }
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }
        
        
    private func checkLogin() {
        WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self] result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let error: Elements = try doc.select(".feedback-alert")
                if(try error.text() == "") {
                    guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ClassListViewController") as? ClassListViewController else {return}
                    vc.modalPresentationStyle = .fullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    WebpageManager.shared.setPageLoadingStatus(status: .main)

                    if self.usernameTextField.text != UserDefaults.standard.value(forKey: "username") as? String || self.passwordTextField.text != UserDefaults.standard.value(forKey: "password") as? String{
                        self.askToRemember()
                    } else {self.present(vc, animated: true, completion:nil)}

                } else {
                    self.invalidLogin.layer.isHidden = false
                    self.passwordTextField.text = ""
                }
                hideLoading()
                self.loginButton.isEnabled = true
                
            } catch {
                print("ERROR WITH SWIFTSOUP")
            }
        }
    }
    
    
    @IBAction func loginAction(_ sender: UIButton) {
        login()
    }
    
    private func login() {
        if UserDefaults.standard.value(forKey: "pslink") == nil {
            invalidURL.isHidden = false
            return
        }
        
        var username: String = ""
        var password: String = ""
        if let usernameText = usernameTextField.text {username = usernameText}
        if let passwordText = passwordTextField.text {password = passwordText}
        
        invalidLogin.isHidden = true
        
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('fieldAccount').value='\(username)'")
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('fieldPassword').value='\(password)'")
        
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('btn-enter-sign-in').click()")
        showLoading()
        loginButton.isEnabled = false
    }
    
    
    func showLoading() {
        let loadingBG = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        loadingBG.backgroundColor = .black
        loadingBG.layer.opacity = 0.8
        loadingBG.tag = 200
        view.addSubview(loadingBG)
        
        let spinningCircleView = RotatingCirclesView()
        spinningCircleView.frame = CGRect(x: view.center.x-50, y: view.center.y-50, width: 100, height: 100)
        view.addSubview(spinningCircleView)
        spinningCircleView.tag = 201
        spinningCircleView.animate()
    }
    
    func hideLoading() {
        if let viewWithTag = self.view.viewWithTag(200) {viewWithTag.removeFromSuperview()}
        if let viewWithTag = self.view.viewWithTag(201) {viewWithTag.removeFromSuperview()}
    }
    
    
    func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!) {
        let pageManager = WebpageManager.shared
        if pageManager.getPageLoadingStatus() == .inital {
            fillInInfo()
            pageManager.setPageLoadingStatus(status: .login)
        } else if pageManager.getPageLoadingStatus() == .login {checkLogin()
        } else if pageManager.getPageLoadingStatus() == .main {checkForAssignments()
        } else if pageManager.getPageLoadingStatus() == .classMenu {pageManager.setPageLoadingStatus(status: .main)
        } else if pageManager.getPageLoadingStatus() == .signOut {pageManager.setPageLoadingStatus(status: .inital)
        } else {pageManager.setPageLoadingStatus(status: .unknown)}
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
