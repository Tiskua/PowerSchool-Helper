//
//  InfoViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/6/22.
//

import UIKit
import WebKit
import SwiftSoup
import GoogleMobileAds
import PhotosUI

class ClassListViewController: UIViewController, UIScrollViewDelegate {
    
    var selectedClassName = ""
    var selectedhref = ""
    var loggedOut = false

            
    let backgroundImage: UIImageView = {
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.contentMode = .scaleAspectFill
        return backgroundImage
    }()
    
    private let banner: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-2145540291403574/8069022745"
//        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.load(GADRequest())
        return banner
    }()
    
    private let banner2: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-2145540291403574/4810125939"
//        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.load(GADRequest())
        return banner
    }()
    
    let backgroundOverlay: UIView = {
        let imageOverlay = UIView(frame: UIScreen.main.bounds)
        return imageOverlay
    }()
    
    var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear

        return scrollView
    }()
    
    var quarterButton = UIButton()
   
    
    var showSideMenu = false
    
    let black = UIView()    
    let gradientLayer = CAGradientLayer()

    var classList: [[String : String]] = []
    var classViewsList: [ClassView] = []
    var watchClassList: [[String : String]] = []
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    
    var barProfileImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        WebpageManager.shared.webView.navigationDelegate = self

        WebpageManager.shared.webView.frame = view.bounds
        AccountManager.global.password = KeychainManager().getPassword()
        
        if UserDefaults.standard.integer(forKey: "quarter") == 0 { UserDefaults.standard.set(1, forKey: "quarter") }
        AccountManager.global.selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        
        WebpageManager.shared.loadURL() { valid in
            if valid { WebpageManager.shared.setPageLoadingStatus(status: .initial) }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateQuarter(_:)), name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems(_:)), name: Notification.Name(rawValue: "saved.settings"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(classOrderChanged(_:)), name: Notification.Name(rawValue: "order.changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetworkConnection(_:)), name: Notification.Name(rawValue: "network.changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)

        
        
        banner.rootViewController = self
        banner2.rootViewController = self
        scrollView.addSubview(banner)
        scrollView.addSubview(banner2)
        
        let refreshController: UIRefreshControl = UIRefreshControl()
        refreshController.addTarget(self, action:#selector(refreshAction), for: .valueChanged)
        refreshController.tintColor = .lightGray
        scrollView.refreshControl = refreshController
        
        addQuarterBar()
        Util.showLoading(view: self.view)
        
        toggleTabItems(enabled: false)
    
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.frame = view.bounds
        updateProfileImage()
        
        WebpageManager.shared.isValidURL() { valid in
            if !valid || UserDefaults.standard.value(forKey: "sign-in-type") == nil {
                self.showLoginScreen()
            }
            if valid {
                NotificationManager.shared.registerForPushNotifications()
            }
        }
        
    }
    
    func showLoginScreen() {
        DispatchQueue.main.async {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            loginVC.loadViewIfNeeded()
            self.navigationController?.pushViewController(loginVC, animated: true)
        }
    }
    
    func addQuarterBar() {
        let action = UIAction(title: "") { _ in
            guard let quarterSelectVC = Storyboards.shared.termSelectionViewController() else { return }
            if let sheet = quarterSelectVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersGrabberVisible = true
            }
            self.present(quarterSelectVC, animated: true)
        }
        
        let bar = UIView(frame: CGRect(x: 30, y: 25, width: view.frame.width-60, height: 3))
        bar.backgroundColor = .darkGray
        bar.layer.cornerRadius = 3
        quarterButton = UIButton(frame:  CGRect(x: view.frame.width/2-50, y: 5, width: 100, height: 40), primaryAction: action)
        quarterButton.setTitle(Util.formatQuarterLabel(), for: .normal)

        quarterButton.setTitleColor(.white, for: .normal)
        quarterButton.setTitleColor(.darkGray, for: .highlighted)
        quarterButton.titleLabel?.font = UIFont(name: "Avenir Next Bold", size: 30)
        quarterButton.titleLabel?.textAlignment = .center
        quarterButton.backgroundColor = .black
        quarterButton.layer.cornerRadius = 10
        quarterButton.layer.borderColor = UIColor.darkGray.cgColor
        quarterButton.layer.borderWidth = 3
        
        scrollView.addSubview(bar)
        scrollView.addSubview(quarterButton)
    }
    
    @objc func updateQuarter(_ notification: Notification) {
        Util.showLoading(view: self.view)
        quarterButton.setTitle(Util.formatQuarterLabel(), for: .normal)
        if NetworkMonitor.shared.isConnected {
            WebpageManager.shared.loadURL() { _ in }
            return
        }
        setClassLabels() { _ in}
    }
    
    @objc func checkFromBackground() {
        Util.showLoading(view: self.view)
        WebpageManager.shared.checkForSignOutBox { found in
            if !found {
                Util.hideLoading(view: self.view)
                return
            } else {
                WebpageManager.shared.setPageLoadingStatus(status: .initial)
                WebpageManager.shared.loadURL() { _ in }
                WebpageManager.shared.loadURL() { _ in }
            }
        }
    }
     
    
    func changeThemeColor() {
        for c in classViewsList {
            c.backgroundColor = Util.getThemeColor()
        }
    }
    
    @objc func updateNetworkConnection(_ notification: Notification) {
        if !NetworkMonitor.shared.isConnected {
            if let _ = view.viewWithTag(1000) { return }
            let yPos = view.frame.height-(navigationController?.navigationBar.frame.height ?? 0)-10
            let noNetworkLabel = UILabel(frame:CGRect(x: 0, y: yPos, width: view.frame.width, height: 30))
            noNetworkLabel.font = UIFont(name: "Avenir Next Bold", size: 18)
            noNetworkLabel.layer.cornerRadius = 10
            noNetworkLabel.backgroundColor = .red.withAlphaComponent(0.8)
            noNetworkLabel.textAlignment = .center
            noNetworkLabel.textColor = .white
            noNetworkLabel.tag = 1000
            noNetworkLabel.text = "No Internet Connection"
            view.addSubview(noNetworkLabel)
        } else {
            if let label = view.viewWithTag(1000) { label.removeFromSuperview() }
        }
    }
    
   
    
    func setBackgroundWallpaper() {
        if let bgImage = Util.getImage(key: "bg-image") {
            backgroundImage.image = bgImage
            self.setBackgroundOverlay()
        } else {
            self.backgroundImage.image = nil
        }
        if UserDefaults.standard.bool(forKey: "nate-mode") { backgroundImage.image = UIImage(named: "Nate") }

    }
    
    
    @objc func classOrderChanged(_ notification: Notification) {
        WebpageManager.shared.setPageLoadingStatus(status: .refreshing)
        WebpageManager.shared.loadURL(completion: { _ in})
    }
    
    @objc func refreshAction() {
        Util.showLoading(view: self.view, text: "Gathering Class Data...")
        AccountManager.global.updatedClasses = []
        if !WebpageManager.shared.isLoopingClasses {
            WebpageManager.shared.isLoopingClasses = true
            DispatchQueue.main.async {
                WebpageManager.shared.loopThroughClassData(index: 0, completion: {
                    WebpageManager.shared.setPageLoadingStatus(status: .login)
                    WebpageManager.shared.loadURL(completion: { _ in })
                    Util.hideLoading(view: self.view)
                    
                })
            }
        }
       
       DispatchQueue.main.async {
          self.scrollView.refreshControl?.endRefreshing()
       }
    }
    

    func setBackgroundOverlay() {
        if let opacity = UserDefaults.standard.value(forKey: "background-overlay-opacity") as? Float { backgroundOverlay.backgroundColor = .black.withAlphaComponent(CGFloat(opacity))
        } else { backgroundOverlay.backgroundColor = .black.withAlphaComponent(0) }
    }
    
    @objc func refreshItems(_ notification: Notification) {
        WebpageManager.shared.loadURL { valid in
            if !valid { return }
            DispatchQueue.main.async {
                self.setBackgroundWallpaper()
                self.backgroundOverlay.layer.opacity = UserDefaults.standard.float(forKey: "background-overlay-opacity")
                var profileImage = UIImage(named: "DefaultProfilePicture")
                if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
                self.barProfileImageView.image = profileImage
                self.setBackgroundOverlay()
                self.setClassLabels() { _ in }
            }
        }
    }
    
    

    func updateProfileImage() {
        var profileImage = UIImage(named: "DefaultProfilePicture")
        if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
        barProfileImageView.image = profileImage
    }


    @objc func clearClassViews() {
        for list in self.classViewsList {
            list.removeFromSuperview()
        }
        while let view = self.scrollView.viewWithTag(100) { view.removeFromSuperview() }
        self.classViewsList = []
        self.classList = []
        
    }

    
    @objc func openClassMenu(recognizer: ClassGestures) {
        WebpageManager.shared.isLoopingClasses = false

        for cl in classList {
            if cl["className"] != recognizer.className { continue }
            
            let href: String = cl["href"] ?? ""
            if href.trimmingCharacters(in: .whitespacesAndNewlines) == "" { continue }
            
            Util.showLoading(view: self.view)
            self.selectedClassName = cl["className"] ?? ""
            self.selectedhref = cl["href"] ?? ""
            
            if !NetworkMonitor.shared.isConnected {
                self.selectClass()
                return
            }
            WebpageManager.shared.openClass(href: href, completion: { _ in
                WebpageManager.shared.checkForAssignments() { success in
                    if success {
                        self.selectClass()
                        return
                    }
                }
            })
        }
    }
    
    func selectClass() {
        AccountManager.global.selectedClass = selectedClassName
        AccountManager.global.selectedhref = selectedhref
        AccountManager.global.classType = ClassType(username: AccountManager.global.username,
                                                    className: selectedClassName,
                                                    quarter: AccountManager.global.selectedQuarter,
                                                    href: selectedhref)
      
        guard let tabBar = Storyboards.shared.classInfoTabbarController() else {return}
        tabBar.modalPresentationStyle = .formSheet
        self.navigationController?.present(tabBar, animated: true)
        Util.hideLoading(view: self.view)
    }
    
    func getClassName(text: String) -> String {
        let textArray = text.components(separatedBy: "Email")
        let className = textArray[0].trimmingCharacters(in: .whitespacesAndNewlines)
        return className
    }
    
    func getClassDataFromDatabase() {
        let classData = DatabaseManager.shared.getClassesData(username: AccountManager.global.username)
        for c in classData {
            if c.quarter != AccountManager.global.selectedQuarter { continue }
            classList.append([
                "className" : c.className,
                "weightedGrade" : String(c.weighted_grade),
                "unweightedGrade" : String(c.grade),
                "href" : c.href
            ])
        }
    }
    
    func retrieveData(completion: @escaping (Bool) -> (Void))  {
        if (NetworkMonitor.shared.isConnected) {
            getClassDataFromWebsite() { gotData, _ in
                if self.classList.isEmpty { self.noClassData() }
                completion(true)
            }
        } else {
            getClassDataFromDatabase()
            if self.classList.isEmpty { self.noClassData() }
            completion(true)
        }
    }

    

    func setClassLabels(completion: @escaping (Bool) -> Void) {
        clearClassViews()
        retrieveData() { _ in
            var ypos = 50
            let xpos = 10
            
            self.banner.backgroundColor = UIColor.black
            self.banner.frame = CGRect(x: 0, y: ypos, width: Int(self.view.frame.width), height: 50).integral
            self.banner.isHidden = false
            
            ypos += 70
            
            for cl in self.classList {
                self.addLabels(data: cl, position: CGPoint(x: xpos, y: ypos), backgroundColor: Util.getThemeColor().cgColor)
                ypos += 220
            }
            self.banner2.backgroundColor = .black
            self.banner2.frame = CGRect(x: 0, y: ypos, width: Int(self.view.frame.width), height: 50).integral
            self.banner2.isHidden = false
            
            Util.hideLoading(view: self.view)
            self.fixSrollHeight(ypos: ypos)
            self.toggleTabItems(enabled: true)
            
            completion(true)
        }
        
    }
    
    func orderClassLabels() {
        var reorderClassesList: [[String : String]] = []
        var orderedClasses:[String] = []
        if let savedClassList = UserDefaults.standard.array(forKey: "class-order") as? [String] {
            orderedClasses = savedClassList
            for orderedClass in orderedClasses {
                for recentclass in classList {
                    if orderedClass == recentclass["className"] {
                        reorderClassesList.append(recentclass)
                    }
                }
            }
            classList = reorderClassesList
        }
    }
    
    func toggleTabItems(enabled: Bool) {
        let tabBarControllerItems = self.tabBarController?.tabBar.items
        if let tabArray = tabBarControllerItems {
            for i in 1...3 {
                tabArray[i].isEnabled = enabled
            }
            tabArray[2].isEnabled = false
        }
    }
    
    
    
    private func getClassDataFromWebsite(completion: @escaping (Bool, [[String : String]]) -> (Void)) {
        WebpageManager.shared.checkForClasses() { didFind in
            if !didFind { completion(false, []) }
            
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
                guard let html = result as? String, error == nil else {
                    completion(false, [])
                    return
                }
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let trs: Elements = try doc.select("tr")
                    let length = trs.size()-10
                    if length <= 0 {
                        completion(false, [])
                        return
                    }
                    for i in 0...length {
                        let tds: Elements = try trs[2+i].select("td")
                        if tds.count < 12 { continue }
                        
                        let text:String = try tds[11].text()
                        let classname = getClassName(text: text)
                        
                        let quarterIndex = 11+AccountManager.global.selectedQuarter
                        if tds[quarterIndex].hasClass("notInSession") { continue }
                        
                        guard let link = try tds[quarterIndex].select("a").first() else { continue }
                        let href:String = try link.attr("href")
                        
                        let gradeval = try tds[quarterIndex].text()
                        let numWeightedGradeVal = Int(gradeval.split(separator: " ")[0]) ?? -1
                        let numGradeVal = Int(gradeval.split(separator: " ")[1]) ?? -1
                    
                        if numGradeVal == -1 {
                            if UserDefaults.standard.bool(forKey: "hide-ug-class") { continue }
                        }
                        
                        let classType = ClassType(username: AccountManager.global.username, className: classname, quarter: AccountManager.global.selectedQuarter, href: href)
                        DatabaseManager.shared.addClass(username: AccountManager.global.username, classType: classType)
                        DatabaseManager.shared.setClassData(classType: classType, type: .href, value: href)
                        DatabaseManager.shared.setClassData(classType: classType, type: .weightedGrade, value: numWeightedGradeVal)
                        DatabaseManager.shared.setClassData(classType: classType, type: .grade, value: numGradeVal)
                        if DatabaseManager.shared.getClassData(classType: classType, type: .placement) as? String == "" {
                            DatabaseManager.shared.setClassData(classType: classType, type: .placement, value: getClassPlacement(name: classname.lowercased()))
                        }
                        classList.append([
                            "className" : classname,
                            "weightedGrade" : String(numWeightedGradeVal),
                            "unweightedGrade" : String(numGradeVal),
                            "href" : href,
                        ])
                    }
                    if classList.isEmpty {
                        completion(false, [])
                        return
                    } else {
                        if DatabaseManager.shared.containsOldClasses(currentClasses: classList) {
                            DatabaseManager.shared.deleteClasses()
                            completion(false, [])
                            retrieveData(completion: { _ in })
                            return
                        }
                        completion(true, classList)
                    }
                    
                   
                } catch {
                    completion(false, []) 
                }
            }
        }
    }
    
    func getClassPlacement(name: String) -> String {
        if name.contains("advance") || name.contains("honor") || name.contains("adv"){
            return "Honors/Advanced"
        } else if name.contains("ap ") {
            return "AP/IB"
        } else {
            return "Regular"
        }
    }
        
    
    func addLabels(data: [String : String], href: String = "", position: CGPoint, backgroundColor: CGColor) {
        let className = data["className"] ?? "UNKOWN"
        let grade:Int = Int(data["weightedGrade"] ?? "UNKNOWN") ?? 0
        let secondgrade:Int = Int(data["unweightedGrade"] ?? "UNKNOWN") ?? 0
        
        let button_width: CGFloat = view.frame.width - position.x*2
        let button_height: CGFloat = 200
        
        let stringTapped = ClassGestures.init(target: self, action: #selector(openClassMenu(recognizer:)))
        stringTapped.className = className
        
        let classView = ClassView(frame: CGRect(x: position.x, y: position.y, width: button_width, height: button_height))
        classView.layer.opacity = 0

        classView.namelabel.text = String(className.trimmingCharacters(in: .whitespaces))
        classView.addGestureRecognizer(stringTapped)

        classView.backgroundColor = UIColor(cgColor: backgroundColor).withAlphaComponent(0.3)
        classView.layer.cornerRadius = 20
        classView.clipsToBounds = true
        classView.layer.masksToBounds = true
                
        classView.layer.borderColor = backgroundColor.copy(alpha: 0.5)
        classView.layer.borderWidth = 4

        classView.gradeLabel.text = grade > -1 ? "\(grade)%" : "__"
        classView.secondGradeLabel.text = secondgrade > -1 ? "\(secondgrade)%" : "__"

        
        scrollView.addSubview(classView)
        classViewsList.append(classView)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
            classView.layer.opacity = 1
         })
    }
    
    func noClassData() {
        let label = UILabel(frame: CGRect(x: 20, y: (view.frame.height/2)-100, width: view.frame.width-40, height: 100))
        label.text = "There appears to be no Class Information for this term"
        label.numberOfLines = 0
        label.textColor = .red
        label.font = UIFont(name: "Avenir Next Bold", size: 25)
        label.textAlignment = .center
        label.tag = 100
        banner.isHidden = true
        banner2.isHidden = true
        scrollView.addSubview(label)
    }
    
    func fixSrollHeight(ypos: Int) {
        let bottomOffset: CGFloat = 75
        if CGFloat(ypos) + bottomOffset > view.frame.height {scrollView.contentSize.height = CGFloat(ypos) + bottomOffset}
        else {scrollView.contentSize.height = view.frame.height+20}
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "saved.settings"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "order.changed"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "network.changed"), object: nil)
    }
}

class ClassGestures: UITapGestureRecognizer {
    var className = ""
}
