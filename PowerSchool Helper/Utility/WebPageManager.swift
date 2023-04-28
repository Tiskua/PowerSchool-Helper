//
//  WebPageManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/22/22.
//

import Foundation
import UIKit
import WebKit
import SwiftSoup

class WebpageManager {
    static let shared = WebpageManager()
    
    var isLoopingClasses = false
    var wasLoopingClasses = false
    
    let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: CGRect(x: 0, y: 100, width: 400, height: 900), configuration: configuration)
        webView.isHidden = true
        return webView
    }()
    
    
    private var pageLoadingStatus: PageLoadingStatus = .unknown
    
    enum PageLoadingStatus {
        case inital
        case login
        case classList
        case classInfo
        case signOut
        case unknown
    }
    
    public func setPageLoadingStatus(status: PageLoadingStatus) {
        pageLoadingStatus = status
    }
    public func getPageLoadingStatus() -> PageLoadingStatus {
        return pageLoadingStatus
    }
    
    public func checkLogin(completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript("document.body.innerHTML") { result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let errorMessage: Elements = try doc.select(".feedback-alert")
                if(try errorMessage.text() == "") { completion(true) }
                else { completion(false) }
            } catch {
                print(error.localizedDescription)
                completion(false) 
            }
        }
    }
    
    public func login(username: String, password: String) {
        WebpageManager.shared.setPageLoadingStatus(status: .login)

        webView.evaluateJavaScript("document.getElementById('fieldAccount').value='\(username)'")
        webView.evaluateJavaScript("document.getElementById('fieldPassword').value='\(password)'")
        webView.evaluateJavaScript("document.getElementById('btn-enter-sign-in').click()")
    }
    
    func loadURL(completion: @escaping (Bool) -> Void) {
        isValidURL() {  valid in
            if valid {
                var link = UserDefaults.standard.string(forKey: "pslink") ?? ""
                if !link.contains("https://") { link = "https://" + link }
                guard let url = URL(string: link) else {return}
                DispatchQueue.main.async { self.webView.load(URLRequest(url: url)) }
                completion(true)
            } else { completion(false) }
        }
        completion(false)
    }

    func isValidURL(completion: @escaping (Bool) -> Void) {
        var link = UserDefaults.standard.string(forKey: "pslink") ?? ""
        if link.lowercased().contains("powerschool") == false {
            completion(false)
            return
        }
        
        if !link.contains("https://") { link = "https://" + link }
        guard let url = URL(string: link) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpresponse = response as? HTTPURLResponse {completion(httpresponse.statusCode == 200)}
            else if let _ = error {completion(false)}
        }
        task.resume()
    }
    func loopThroughClasses(index: Int) {
        if self.isLoopingClasses == false {return}
        if index+1 > ClassInfoManager.shared.getClassesData(username: AccountManager.global.username).count {
            wasLoopingClasses = false
            return
        }
        let cl = ClassInfoManager.shared.getClassesData(username: AccountManager.global.username)[index]
        if cl.quarter != AccountManager.global.selectedQuarter {
            loopThroughClasses(index: index+1)
            return
        }
        wasLoopingClasses = true

        AccountManager.global.classIndexToUpdate = index
        self.openClass(href:cl.href)
        checkForAssignments() { success in
            if success {
                self.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                    guard let html = result as? String, error == nil else {return}
                    do {
                        let doc = try SwiftSoup.parseBodyFragment(html)
                        let classType = ClassType(username: AccountManager.global.username, className: cl.class_name, quarter: AccountManager.global.selectedQuarter, href: cl.href)
                        let classData = ClassData(isUpdated: false, classType: classType, doc: doc)
                        let studentClassData = StudentClassData()
                        studentClassData.teacher = classData.getTeacher()
                        
                        let grades = classData.getGrade()
                        studentClassData.grade = grades[0]
                        studentClassData.weighted_grade = grades[1]
                        studentClassData.letterGrade = classData.getGradeLetter()
                        
                        let points = classData.getPoints()
                        studentClassData.received =  points[0]
                        studentClassData.total =  points[1]
                        studentClassData.detailedGrade = classData.getDetailedGrade(recieved: points[0], total: points[1])[0]
                        let pointsNeed = classData.getPointsNeeded()
                        studentClassData.needPointsPercent = Float(pointsNeed[0]) ?? -1
                        studentClassData.needPointsLetter = Float(pointsNeed[1]) ?? -1
                        
                        studentClassData.assignments =  classData.getAssignments()

                        AccountManager.global.updatedClassInfoList.append(studentClassData)
                        AccountManager.global.updatedClasses.append("\(cl.class_name)_\(cl.quarter)")
                        self.loopThroughClasses(index: index + 1)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("FAILURE")
            }
        }
    }
    
    func openClass(href:String) {
        webView.evaluateJavaScript("window.location.href='\(href)'")
    }
    
    public func checkForAssignments(completion: @escaping (Bool) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                guard let html = result as? String, error == nil else {return}
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let xte: Elements = try doc.select(".xteContentWrapper")
                    if xte.size() == 0 { return }
                    let tbody: Elements = try xte[0].select(".ng-scope")
                    if tbody.count >= 3 {
                        self.setPageLoadingStatus(status: .classInfo)
                        completion(true)
                        timer.invalidate()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    public func checkForClasses(completion: @escaping (Bool) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                guard let html = result as? String, error == nil else {return}
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let trs: Elements = try doc.select("tr")
                    let length = trs.size() - 10
                    if length > 0 {
                        completion(true)
                        timer.invalidate()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    public func checkIfLoggedOut(completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript("document.body.innerHTML") { result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let signedOutBox = try doc.select(".signedout.visible")
                if signedOutBox.count > 0 {
                    self.loadURL(completion: ) { _ in}
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print(error.localizedDescription)
                completion(true)
            }
        }
    }
}
