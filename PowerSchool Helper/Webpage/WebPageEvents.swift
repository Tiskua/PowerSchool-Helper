//
//  WebPageEvents.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/12/23.
//

import UIKit
import WebKit

extension ClassListViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!) {
        let pageManager = WebpageManager.shared
        if pageManager.getPageLoadingStatus() == .firstLogin {
            pageManager.checkForGoogleLogin(completion: { found in
                if let presentVC = self.navigationController?.topViewController as? LoginViewController  {
                    presentVC.googleLoginBtnImg.isUserInteractionEnabled = found
                }
            })
        }
        else if pageManager.getPageLoadingStatus() == .initial {
            if UserDefaults.standard.string(forKey: "sign-in-type") == "google" {
                pageManager.webView.evaluateJavaScript("document.getElementById('studentSignIn').click()")
                pageManager.setPageLoadingStatus(status: .googleLogin)
            } else if UserDefaults.standard.string(forKey: "sign-in-type") == "regular" {
                pageManager.webView.evaluateJavaScript("document.getElementById('btn-enter-sign-in').click()")
                pageManager.setPageLoadingStatus(status: .login)
            }
            
        } else if pageManager.getPageLoadingStatus() == .login {
            pageManager.checkLogin() { success in
                if success {
                    if let _ = self.navigationController?.topViewController as? LoginViewController  {
                        self.navigationController?.popViewController(animated: true)
                    }
                    self.view.addSubview(self.scrollView)
                    pageManager.getStudentName() { name in
                        if UserDefaults.standard.string(forKey: "sign-in-type") == "google" {
                            AccountManager.global.username = name[0]
                            AccountManager.global.password = name[1]
                        }
                        let realmFileName = "\(AccountManager.global.username)_\(AccountManager.global.password.prefix(2))"
                        DatabaseManager.shared.initizialeSchema(username: realmFileName)
                        DatabaseManager.shared.addStudentToDatabase(username: AccountManager.global.username)
                        
                        Util.getTermOptions(completion: { _ in
                            self.quarterButton.setTitle(Util.formatQuarterLabel(), for: .normal)
                            self.setClassLabels() { _ in }
                        })
                        pageManager.setPageLoadingStatus(status: .classList)
                        Util.hideLoading(view: self.view)
                    }
                } else {
                    WebpageManager.shared.setPageLoadingStatus(status: .login)
                    self.openLoginView()
                }
            }
        } else if pageManager.getPageLoadingStatus() == .classInfo { pageManager.setPageLoadingStatus(status: .classList)
        } else if pageManager.getPageLoadingStatus() == .signOut {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            self.navigationController?.pushViewController(loginVC, animated: true)
            loggedOut = true
            pageManager.setPageLoadingStatus(status: .login)
            UserDefaults.standard.removeObject(forKey: "class-order")
        } else if pageManager.getPageLoadingStatus() == .refreshing {
            if UserDefaults.standard.array(forKey: "order-quarter-list") == nil {
                Util.getTermOptions(completion: { _ in
                    self.quarterButton.setTitle(Util.formatQuarterLabel(), for: .normal)
                })
            }
            self.setClassLabels(completion: { _ in
                WebpageManager.shared.setPageLoadingStatus(status: .classList)
            })
        
        } else if pageManager.getPageLoadingStatus() == .googleLogin {
            if let url = webView.url, url.absoluteString.starts(with: "https://accounts.google.com") == false, url.absoluteString.starts(with: "https://accounts.youtube.com") == false  {
                self.navigationController?.dismiss(animated: true)
                self.navigationController?.popViewController(animated: true)
                UserDefaults.standard.set("google", forKey: "sign-in-type")
                pageManager.setPageLoadingStatus(status: .login)
                pageManager.webView.reload()
                pageManager.webView.isHidden = true
            } else {
                Util.hideLoading(view: self.view)
                if self.navigationController?.presentationController is GoogleSignInViewController  { return }
                guard let googleLoginVC = Storyboards.shared.googleSigninViewController() else {return}
                googleLoginVC.modalPresentationStyle = .formSheet
                googleLoginVC.isModalInPresentation = true
                self.navigationController?.present(googleLoginVC, animated: true)
                    pageManager.webView.isHidden = false
            }
        }
    }
    
    func openLoginView() {
        if let presentVC = self.navigationController?.topViewController as? LoginViewController  {
            presentVC.invalidLogin.isHidden = false
            Util.hideLoading(view: presentVC.view)
        } else {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            loginVC.loadViewIfNeeded()
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
    }
}
