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
    
    let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: CGRect(x: 0, y: 100, width: 400, height: 900), configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36";
        webView.isHidden = true
                
        return webView
    }()
    
    
    private var pageLoadingStatus: PageLoadingStatus = .unknown
    public var previousePageLoadingStatus: PageLoadingStatus = .unknown
    
    enum PageLoadingStatus {
        case initial
        case classList
        case classInfo
        case signOut
        case refreshing
        case googleLogin
        case signInToGoogle
        case firstLogin
        case login
        case unknown
        case checkStatus
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
        setPageLoadingStatus(status: .login)
       
        self.webView.evaluateJavaScript("document.getElementById('fieldAccount').value='\(username)'")
        self.webView.evaluateJavaScript("document.getElementById('fieldPassword').value='\(password)'")
        self.webView.evaluateJavaScript("document.getElementById('btn-enter-sign-in').click()")
    
    }
    
    public func googleLogin() {
        
        setPageLoadingStatus(status: .googleLogin)
        self.webView.evaluateJavaScript("document.getElementById('studentSignIn').click()")
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
    func loopThroughClassData(index: Int, completion: @escaping () -> Void) {
        if self.isLoopingClasses == false {return}
        
        let classes = DatabaseManager.shared.getClassesData(username: AccountManager.global.username)
        if index+1 > classes.count {
            isLoopingClasses = false
            completion()
            return
        }
        let cl = classes[index]
        if cl.quarter != AccountManager.global.selectedQuarter {
            loopThroughClassData(index: index+1, completion: { completion() })
            return
        }
        AccountManager.global.classIndexToUpdate = index
        self.openClass(href:cl.href, completion: { _ in })
        checkForAssignments() { success in
            if success {
                self.webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                    guard let html = result as? String, error == nil else {return}
                    do {
                        let doc = try SwiftSoup.parseBodyFragment(html)
                        let classType = ClassType(username: AccountManager.global.username, className: cl.className, quarter: AccountManager.global.selectedQuarter, href: cl.href)
                        let classData = ClassInfoSetData(isUpdated: false, classType: classType, doc: doc)
                        let studentClassData = StudentClassData()
                        studentClassData.teacher = classData.getTeacher()
                        
                        let grades = classData.getGrade()
                        studentClassData.grade = grades[0]
                        studentClassData.weighted_grade = grades[1]
                        studentClassData.letterGrade = classData.getGradeLetter()
                        
                        let points = classData.getPoints()
                        studentClassData.received = points[0]
                        studentClassData.total = points[1]
                        studentClassData.detailedGrade = classData.getDetailedGrade(recieved: points[0], total: points[1])[0]
                        let pointsNeed = classData.getPointsNeeded(total: points[1],
                                                                   received: points[0])
                        
                        studentClassData.needPointsPercent = Float(pointsNeed[0]) ?? -1
                        studentClassData.needPointsLetter = Float(pointsNeed[1]) ?? -1
                        
                        studentClassData.assignments =  classData.getAssignments()

                        AccountManager.global.updatedClasses.append("\(cl.className)_\(cl.quarter)")
                        self.loopThroughClassData(index: index + 1, completion: {completion()})
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("FAILURE")
            }
        }
    }
    
    func openClass(href:String, completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript("window.location.href='\(href)'") { result, error in
            completion(true)
        }
    }
    
    func checkForGoogleLogin(completion: @escaping (Bool) -> (Void))  {
        webView.evaluateJavaScript("document.getElementById('studentSignIn') !== null") { (result, error) in
            if let exists = result as? Bool {
                completion(exists)
            } else {
                completion(false)
            }
        }
    }
    
    public func checkForAssignments(completion: @escaping (Bool) -> Void) {
        var times = 0
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
                    
                    if times > 10 {
                        timer.invalidate()
                        completion(false)
                    }
                    
                    times += 1
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    public func checkForClasses(completion: @escaping (Bool) -> Void) {
        var times = 0
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
                    
                    if times > 10 {
                        timer.invalidate()
                        completion(false)
                    }
                    times += 1
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    public func checkForLoginPage(completion: @escaping (Bool) -> Void) {
        let script = "document.getElementById('btn-enter-sign-in') !== null"
        self.webView.evaluateJavaScript(script) { (result, error) in
            if let hasElement = result as? Bool, hasElement {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public func checkForSignOutBox(completion: @escaping (Bool) -> Void) {
        let script = "document.getElementById('sessiontimeoutwarning').style.display != 'none'"
        self.webView.evaluateJavaScript(script) { (result, error) in
            if let hasElement = result as? Bool, hasElement {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func addClickListener() {
        let script = """
        var elements = document.querySelectorAll("*");
        elements.forEach(function(element) {
            element.addEventListener("click", function(event) {
                var eventData = {
                    id: event.target.id
                }
                window.webkit.messageHandlers.elementClicked.postMessage(eventData);
            });
        });
        """
        webView.evaluateJavaScript(script, completionHandler: { (result, error) in
            if let error = error {
                print("Error executing JavaScript: \(error)")
            } else {
                print("JavaScript executed successfully")
            }
        })
    }
    
    func getStudentName(completion: @escaping ([String]) -> Void) {
        webView.evaluateJavaScript("document.body.innerHTML") { result, error in
            guard let html = result as? String, error == nil else {return}
            do {
                let doc: Document = try SwiftSoup.parseBodyFragment(html)
                let h1: String = try doc.select("h1").text()
                let name = h1.components(separatedBy: ": ")[1].components(separatedBy: ", ")
                let last: String = name[1]
                let first: String = name[0].replacingOccurrences(of: ",", with: "")
                completion([first, last])
                
            } catch {
                print(error.localizedDescription)
                completion(["error", "name"])
            }
        }
    }
    
    func clearBrowserData() {
        if let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies]) as? Set<String> {
            let dateFrom = Date(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
                self.loadURL(completion: { _ in})
            }
        }
    }
}
