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
//        banner.load(GADRequest())
        return banner
    }()
    
    private let banner2: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-2145540291403574/4810125939"
//        banner.load(GADRequest())
        return banner
    }()
    
    let backgroundOverlay: UIView = {
        let imageOverlay = UIView(frame: UIScreen.main.bounds)
        return imageOverlay
    }()
    
    var scrollView: UIScrollView!
    
    var showSideMenu = false
    
    let black = UIView()
    var sidebarView = SidebarView()
    
    let gradientLayer = CAGradientLayer()
    let gradeLabel = UILabel()

    var classList: [[String : String]] = []
    var classViewsList: [ClassView] = []
    var watchClassList: [[String : String]] = []

    var selectedLayout: layoutOptions.RawValue = layoutOptions.doubleColumn.rawValue
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    enum layoutOptions: String {
        case doubleColumn
        case singleColumn
    }
    
    var barProfileImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        WebpageManager.shared.webView.navigationDelegate = self
        WebpageManager.shared.webView.frame = self.view.frame
        view.addSubview(WebpageManager.shared.webView)
        
        AccountManager.global.username = UserDefaults.standard.string(forKey: "login-username") ?? "UK"
        AccountManager.global.password = KeychainManager().getPassword(username: AccountManager.global.username)
        
        sidebarView = SidebarView(frame: CGRect(x: -220, y: 0, width: 200, height: Int(view.frame.height)))
        
        if let layout = UserDefaults.standard.value(forKey: "selectedLayout") as? layoutOptions.RawValue {
            selectedLayout = layout
        }
        
        if UserDefaults.standard.integer(forKey: "quarter") == 0 { UserDefaults.standard.set(1, forKey: "quarter") }
        AccountManager.global.selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        sidebarView.GPALabel.textColor = Util.getThemeColor()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false

        view.insertSubview(backgroundImage, at: 0)
        
        if NetworkMonitor.shared.isConnected {
            WebpageManager.shared.loadURL() {_ in
                WebpageManager.shared.setPageLoadingStatus(status: .inital)
            }
        }
        
        addTopBar()
        addSideMenu()
        updateProfileImage()
        setBackgroundWallpaper()
        scrollView.backgroundColor = .clear
        if UserDefaults.standard.value(forKey: "light-text") == nil {
            UserDefaults.standard.set(true, forKey: "light-text")
        }
        
        view.insertSubview(backgroundOverlay, at: 1)
        sidebarView.quarterLabel.text = Util.formatQuarterLabel()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateQuarter(_:)), name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems(_:)), name: Notification.Name(rawValue: "saved.settings"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(classOrderChanged(_:)), name: Notification.Name(rawValue: "order.changed"), object: nil)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRightGesture(gesture:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
        
            
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressRecognizer.minimumPressDuration = 3
        view.addGestureRecognizer(longPressRecognizer)
        
        
        view.addSubview(sidebarView)
        banner.rootViewController = self
        banner2.rootViewController = self
        scrollView.addSubview(banner)
        scrollView.addSubview(banner2)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.string(forKey: "pslink") == "" || KeychainManager().getPassword(username: UserDefaults.standard.string(forKey: "login-username") ?? "UK") == "" {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            loginVC.loadViewIfNeeded()
            self.navigationController?.pushViewController(loginVC, animated: true)
            return
        }
        updateNetworkConnection()
        WebpageManager.shared.checkIfLoggedOut() { isLoggedOut in
            if isLoggedOut {
                Util.showLoading(view: self.view)
            }
        }
    }

    func updateNetworkConnection() {
        if !NetworkMonitor.shared.isConnected {
            if let _ = view.viewWithTag(1000) { return }
            let noNetworkLabel = UILabel(frame:CGRect(x: 0, y: view.frame.height-55, width: view.frame.width, height: 40))
            noNetworkLabel.backgroundColor = .red.withAlphaComponent(0.7)
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
            self.setGradientBackground()
        }
        if UserDefaults.standard.bool(forKey: "nate-mode") { backgroundImage.image = UIImage(named: "Nate") }

    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if !UserDefaults.standard.bool(forKey: "developer-mode") { return }
        if (sender.state == UIPanGestureRecognizer.State.began) {
            if classViewsList.isEmpty {
                setClassLabels(completion: { _ in})
                banner.isHidden = false
                banner2.isHidden = false
            } else {
                clearInfo()
                banner.isHidden = true
                banner2.isHidden = true
            }
        }
    }
    
    @objc func classOrderChanged(_ notification: Notification) {
        WebpageManager.shared.setPageLoadingStatus(status: .refreshing)
        WebpageManager.shared.loadURL(completion: { _ in})
    }
    
    @objc func handleRefreshControl() {
        updateNetworkConnection()
        AccountManager.global.updatedClasses = []
        var temp = false
        WebpageManager.shared.loadURL() { _ in
            if temp { return}
            DispatchQueue.main.async {
                temp = true
                self.setClassLabels() { _ in
                    if !WebpageManager.shared.isLoopingClasses {
                        WebpageManager.shared.isLoopingClasses = true
                        WebpageManager.shared.loopThroughClasses(index: 0)
                    }
                }
            }
        }
       
       DispatchQueue.main.async {
          self.scrollView.refreshControl?.endRefreshing()
       }
    }
    
    @objc func swipeRightGesture(gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right { toggleSideMenu() }
    }
    
    
    func setBackgroundOverlay() {
        if let opacity = UserDefaults.standard.value(forKey: "background-overlay-opacity") as? Float { backgroundOverlay.backgroundColor = .black.withAlphaComponent(CGFloat(opacity))
        } else { backgroundOverlay.backgroundColor = .black.withAlphaComponent(0) }
    }
    
    @objc func refreshItems(_ notification: Notification) {
        while let viewWithTag = self.view.viewWithTag(1) {viewWithTag.removeFromSuperview()}
        while let viewWithTag2 = self.view.viewWithTag(1) {viewWithTag2.removeFromSuperview()}
        gradientLayer.removeFromSuperlayer()
        setBackgroundWallpaper()
        gradeLabel.textColor = Util.getThemeColor()
        sidebarView.layoutSegmentPicker.selectedSegmentTintColor = Util.getThemeColor()
        sidebarView.GPALabel.textColor = Util.getThemeColor()
        backgroundOverlay.layer.opacity = UserDefaults.standard.float(forKey: "background-overlay-opacity")
        setClassLabels() { _ in}
        var profileImage = UIImage(named: "DefaultProfilePicture")
        if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
        sidebarView.profileImageView.image = profileImage
        barProfileImageView.image = profileImage
        WebpageManager.shared.webView.isHidden = !UserDefaults.standard.bool(forKey: "developer-mode")
        setBackgroundOverlay()
    }
    
    func setGradientBackground() {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        Util.getThemeColor().getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let colorTop =  UIColor(red: 22/255, green: 22/255, blue: 24/255, alpha: 1).cgColor
        let colorBottom = UIColor(red: red/6, green: green/6, blue: blue/6, alpha: alpha).cgColor
    
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
    
    @objc func updateQuarter(_ notification: Notification) {
        self.sidebarView.quarterLabel.text = Util.formatQuarterLabel()
        Util.showLoading(view: self.view)
        WebpageManager.shared.loadURL() { _ in }
    }
    
    
    
    
    func updateProfileImage() {
        var profileImage = UIImage(named: "DefaultProfilePicture")
        if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
        barProfileImageView.image = profileImage
        sidebarView.profileImageView.image = profileImage
    }
    
    func addTopBar() {
        let topBar = UIView(frame: CGRect(x: 0, y: 10, width: view.frame.width, height: 60))
        topBar.backgroundColor = .black.withAlphaComponent(0.3)
        topBar.layer.shadowColor = UIColor.black.cgColor
        topBar.layer.shadowOpacity = 0.3
        topBar.layer.shadowOffset = CGSize(width: 0, height: 6)
        topBar.layer.shadowRadius = 5
        scrollView.addSubview(topBar)
        
        gradeLabel.frame = CGRect(x: 10, y: 15, width: view.frame.width, height: 50)
        gradeLabel.text = "Grades"
        gradeLabel.font = UIFont(name: "Avenir Next Bold", size: 33)
        gradeLabel.textColor = Util.getThemeColor()
        scrollView.addSubview(gradeLabel)
        barProfileImageView = UIImageView(frame: CGRect(x: view.frame.size.width-60, y: 15, width: 50, height: 50))
        barProfileImageView.isUserInteractionEnabled = true
        barProfileImageView.layer.masksToBounds = true
        barProfileImageView.layer.cornerRadius = barProfileImageView.frame.width/2
        barProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSideMenu)))
        scrollView.addSubview(barProfileImageView)
        Util.showLoading(view: self.view)

    }
    
    func addSideMenu() {
        black.frame = view.bounds
        black.backgroundColor = .black.withAlphaComponent(0.7)
        black.isHidden = true
        black.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSideMenu)))
        view.addSubview(scrollView)
        view.addSubview(black)
        
        let refreshController: UIRefreshControl = UIRefreshControl()
        refreshController.addTarget(self, action:#selector(handleRefreshControl), for: .valueChanged)
        refreshController.tintColor = .lightGray
        scrollView.refreshControl = refreshController
        
    }
    
    @objc func toggleSideMenu() {
        if showSideMenu {
            UIView.animate(withDuration: 0.32, animations: {
                self.black.isHidden = true
                self.sidebarView.frame = CGRect(x: -220, y: 0, width: 200, height: self.view.frame.height);
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.black.isHidden = false
                self.sidebarView.frame = CGRect(x: 0, y: 0, width: 200, height: self.view.frame.height);
                self.view.layoutIfNeeded()
            })
        }
        showSideMenu = !showSideMenu

    }
   

    @objc func clearInfo() {
        DispatchQueue.main.async {
            for list in self.classViewsList {
                list.removeFromSuperview()
            }
            while let view = self.scrollView.viewWithTag(100) { view.removeFromSuperview() }
            self.classViewsList = []
            self.classList = []
            self.watchClassList = []
        }
    }

    
    @objc func clickedClassButton(recognizer: MyTapGesture) {
        if showSideMenu  {return}
        if !NetworkMonitor.shared.isConnected {
            updateNetworkConnection()
            return
        }
        WebpageManager.shared.checkIfLoggedOut() { isLoggedOut in
            if isLoggedOut {
                WebpageManager.shared.setPageLoadingStatus(status: .inital)
                WebpageManager.shared.loadURL() { _ in}
                return
            }
            for cl in ClassInfoManager.shared.getClassesData(username: AccountManager.global.username) {
                if cl.class_name == recognizer.className && cl.quarter == AccountManager.global.selectedQuarter {
                    WebpageManager.shared.isLoopingClasses = false
                    let href: String = cl.href
                    Util.showLoading(view: self.view)
                    self.selectedClassName = cl.class_name
                    self.selectedhref = cl.href
                    if AccountManager.global.updatedClasses.contains("\(cl.class_name)_\(AccountManager.global.selectedQuarter)") {
                        self.selectClass()
                        return
                    }
                    WebpageManager.shared.openClass(href: href)
                    WebpageManager.shared.checkForAssignments() { success in
                        if success { self.selectClass() }
                    }
                    break
                }
            }
        }
    }
    
    func selectClass() {
        AccountManager.global.selectedClass = selectedClassName
        AccountManager.global.selectedhref = selectedhref
        AccountManager.global.classType = ClassType(username: AccountManager.global.username,
                                                    className: selectedClassName,
                                                    quarter: AccountManager.global.selectedQuarter,
                                                    href: selectedhref)
      
        guard let tabBar = Storyboards.shared.tabBarController() else {return}
        present(tabBar, animated: true)
        Util.hideLoading(view: self.view)
    }
    
    func getClassName(text: String) -> String {
        let textArray = text.components(separatedBy: "Email")
        let className = textArray[0].trimmingCharacters(in: .whitespacesAndNewlines)
        return className
    }

    func setClassLabels(completion: @escaping (Bool) -> Void) {
        if AccountManager.global.password == "" { return }
        clearInfo()
        getClassesData() { gotData, _ in
            if gotData == false || self.classList.isEmpty {
                self.noClassData()
                Util.hideLoading(view: self.view)
                completion(false)
                return
            }
            self.orderClassLabels()
            var ypos = 95
            var xpos = self.selectedLayout == layoutOptions.doubleColumn.rawValue ? 5 : 15
        
            var adPos = Int.random(in : 0...self.classList.count-1)
            let previousAdPos = adPos
            
            for a in 1...2 {
                self.classList.insert([
                    "className" : "BANNER_CLASS_\(a)",
                    "weightedGrade" : "-1"
                ], at: adPos)
                adPos = Int.random(in : 0...self.classList.count)
                if adPos == previousAdPos { adPos = Int.random(in : 0...self.classList.count-1)}
            }
            for (index,cl) in self.classList.enumerated() {
                self.addLabels(data: cl, position: CGPoint(x: xpos, y: ypos))
                let newValues = self.positionLabels(xpos: xpos, ypos: ypos, index: index-1)
                xpos = newValues[0]
                ypos = newValues[1]
            }
            
            self.banner.isHidden = false
            self.banner2.isHidden = false
            self.fixSrollHeight(ypos: ypos)
            self.setGPA()
            Util.hideLoading(view: self.view)
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
    
    func noClassData() {
        let label = UILabel(frame: CGRect(x: 20, y: 150, width: Int(view.frame.width)-40, height: 100))
        label.text = "No Class Data for this Term. Try changing the term in the side menu."
        label.numberOfLines = 0
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 25, weight: .heavy)
        label.textAlignment = .center
        label.tag = 100
        banner.isHidden = true
        banner2.isHidden = true
        scrollView.addSubview(label)
    }
    
    public func getClassesData(completion: @escaping (Bool, [[String : String]]) -> (Void)) {
        WebpageManager.shared.checkForClasses() { didFind in
            if didFind {
                WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
                    guard let html = result as? String, error == nil else {return}
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
                            if tds.count < 12 {
                                continue
                            }
                            let text:String = try tds[11].text()
                            let classname = getClassName(text: text)
                            
                            let quarterIndex = 11+AccountManager.global.selectedQuarter
                            if tds[quarterIndex].hasClass("notInSession") {
                                continue}
                            let link = try tds[quarterIndex].select("a").first()!
                            let href:String = try link.attr("href")
                            var numGradeVal:Int = -1
                            var numWeightedGradeVal:Int = -1
                            
                            let gradeval = try tds[quarterIndex].text()
                            if gradeval == "[ i ]" {
                                if UserDefaults.standard.bool(forKey: "hide-ug-class") {continue}
                            } else {
                                numWeightedGradeVal = Int(gradeval.split(separator: " ")[0]) ?? -1
                                numGradeVal = Int(gradeval.split(separator: " ")[1]) ?? -1
                            }
                            
                            let classType = ClassType(username: AccountManager.global.username, className: classname, quarter: AccountManager.global.selectedQuarter, href: href)
                            ClassInfoManager.shared.addClass(username: AccountManager.global.username, classType: classType)
                            ClassInfoManager.shared.setClassData(classType: classType, type: .href, value: href)
                            ClassInfoManager.shared.setClassData(classType: classType, type: .weightedGrade, value: numWeightedGradeVal)
                            ClassInfoManager.shared.setClassData(classType: classType, type: .grade, value: numGradeVal)
            
                            let needPointsPercent: Float = ClassInfoManager.shared.getClassData(classType: classType, type: .needPointsPercent) as! Float
                            let revieved: Float = ClassInfoManager.shared.getClassData(classType: classType, type: .received) as! Float
                            let total: Float = ClassInfoManager.shared.getClassData(classType: classType, type: .total) as! Float
                            
                            classList.append([
                                "className" : classname,
                                "weightedGrade" : String(numWeightedGradeVal)
                            ])
                            watchClassList.append([
                                "className" : classname,
                                "grade" : String(numGradeVal),
                                "weightedGrade" : String(numWeightedGradeVal),
                                "points" : "\(revieved)/\(total)",
                                "needPointPercent" : String(needPointsPercent)
                            ])
                        }
                        if classList.isEmpty {
                            completion(false, [])
                            return
                        }

                        WatchManager.shared.sendMessageToWatch(id: "themeColor", data: Util.getThemeColor().colorToString())
                        WatchManager.shared.sendMessageToWatch(id: "term", data: Util.formatQuarterLabel())
                        WatchManager.shared.sendMessageToWatch(id: "classinfo", data: watchClassList)
                        
                        completion(true, watchClassList)
                    } catch {
                        print("COULD NOT GET DATA:" + error.localizedDescription)
                        completion(false, [])
                    }
                }
                
            } else {
                completion(false, [])
            }
        }
    }
           
    

    func fixSrollHeight(ypos: Int) {
        let bottomOffset: CGFloat = selectedLayout == layoutOptions.doubleColumn.rawValue ? 200 : 130
        if CGFloat(ypos) + bottomOffset > view.frame.height {scrollView.contentSize.height = CGFloat(ypos) + bottomOffset}
        else {scrollView.contentSize.height = view.frame.height+20}
    }
    
    func positionLabels(xpos:Int, ypos:Int, index: Int) -> [Int] {
        var ypos2 = ypos
        var xpos2 = xpos
        if selectedLayout == layoutOptions.doubleColumn.rawValue {
            if index % 2 == 0 {
                xpos2 = 5
                ypos2 += 220}
            else if index % 2 != 0 {xpos2 = Int(view.frame.width - (view.frame.width/2.1) - 5)}
            
        } else if selectedLayout == layoutOptions.singleColumn.rawValue {
            xpos2 = 15
            ypos2 += 160}
        return [xpos2, ypos2]
        
    }
    
    func setGPA() {
        var grades: [Int] = []
        for c in ClassInfoManager.shared.getClassesData(username: AccountManager.global.username) {
            if c.grade == -1 || c.weighted_grade == -1 {continue}
            if c.quarter != AccountManager.global.selectedQuarter {continue}
            grades.append(Int(c.grade))
        }
        let oGPA: String = Util.findOverallGPA(gradeList: grades).isNaN ? "Unknown" : String(Util.findOverallGPA(gradeList: grades))
        sidebarView.GPALabel.text = "\(oGPA)"
    }
    
    
    func addLabels(data: [String : String], href: String = "", position: CGPoint) {
        let className = data["className"] ?? "UNKNOWN"
        let grade:Int = Int(data["weightedGrade"] ?? "UNKNOWN") ?? 0
        
        let button_width: CGFloat = selectedLayout == layoutOptions.doubleColumn.rawValue ? CGFloat(view.frame.width/2.1) : view.frame.width - position.x*2
        let button_height: CGFloat = selectedLayout == layoutOptions.doubleColumn.rawValue ? 200 : 130
        
        if className.contains("BANNER_CLASS") && grade == -1{
            let b: GADBannerView = className == "BANNER_CLASS_1" ? banner : banner2
            b.backgroundColor = .black.withAlphaComponent(0.9)
            b.layer.cornerRadius = 10
            b.layer.borderWidth = 2
            b.layer.borderColor = Util.getThemeColor().cgColor
            b.frame = CGRect(x: position.x, y: CGFloat(position.y), width: button_width, height: button_height).integral
            b.dropShadow()
            return
        }
        
        let stringTapped = MyTapGesture.init(target: self, action: #selector(clickedClassButton(recognizer:)))
        stringTapped.className = className
        
        
        let classView = ClassView(frame: CGRect(x: position.x, y: position.y, width: button_width, height: button_height))
        classView.layer.opacity = 0
        let nameLabel: UILabel = selectedLayout == layoutOptions.doubleColumn.rawValue ? classView.nameLabelDouble : classView.nameLabel
        let gradeLabel: UILabel = selectedLayout == layoutOptions.doubleColumn.rawValue ? classView.gradeLabelDouble : classView.gradeLabel
        
        classView.backgroundColor = Util.getThemeColor()
        if UserDefaults.standard.bool(forKey: "nate-mode") { classView.imageView.image = UIImage(named: "Nate") }

        nameLabel.text = String(className.trimmingCharacters(in: .whitespaces))
        classView.addGestureRecognizer(stringTapped)
        classView.dropShadow()
        
        classView.layer.cornerRadius = 10
        classView.clipsToBounds = true
        classView.layer.masksToBounds = true
        
        nameLabel.textColor = UserDefaults.standard.bool(forKey: "light-text") ? UIColor.white : UIColor.black
        nameLabel.dropShadow(opacity: 0.4, offset: CGSize(width: 1, height: 1))

        gradeLabel.textColor = Util.colorGrade(grade: grade)
        
        if UserDefaults.standard.bool(forKey: "color-grades") == false { gradeLabel.textColor = UserDefaults.standard.bool(forKey: "light-text") ? UIColor.white : UIColor.black }
        
        gradeLabel.text = grade > -1 ? "\(grade)%" : "__"
        gradeLabel.dropShadow(opacity: 0.4, offset: CGSize(width: 1, height: 1))
        
        scrollView.addSubview(classView)
        classViewsList.append(classView)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
            classView.layer.opacity = 1
         })

    }
}
extension ClassListViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!) {
        let pageManager = WebpageManager.shared
        if pageManager.getPageLoadingStatus() == .inital {
            if UserDefaults.standard.string(forKey: "pslink") != nil && UserDefaults.standard.string(forKey: "login-username") != nil{
                WebpageManager.shared.login(username: AccountManager.global.username, password: AccountManager.global.password)
                pageManager.setPageLoadingStatus(status: .login)
            }
        } else if pageManager.getPageLoadingStatus() == .login {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            loginVC.loadViewIfNeeded()
            if loggedOut {
                loggedOut = false
                WebpageManager.shared.setPageLoadingStatus(status: .login)
                return
            }
            pageManager.checkLogin() { success in
                if success {
                    let login_username = AccountManager.global.username
                    let login_password = AccountManager.global.password
                    let realmFileName = "\(login_username)_\(login_password.prefix(2))"
                    
                    ClassInfoManager.shared.initizialeSchema(username: realmFileName)
                    ClassInfoManager.shared.addStudentToDatabase(username: login_username)
                    UserDefaults.standard.set(login_username, forKey: "login-username")
                    if KeychainManager().getPassword(username: login_username) != login_password {
                        do {
                            try KeychainManager().saveLogin(service: "powerschool-helper.com", account: login_username, password: Data(login_password.utf8))
                        } catch {
                            KeychainManager().updatePassword(username: login_username, newPassword: login_password)
                        }
                    }
                    if UserDefaults.standard.array(forKey: "order-quarter-list") as? [String] == nil {
                        Util.getTermOptions() { _ in
                            self.sidebarView.quarterLabel.text = Util.formatQuarterLabel()
                        }
                    }
                    
                    self.navigationController?.popViewController(animated: true)
                    WebpageManager.shared.checkRestore() { _ in
                        self.setClassLabels() { _ in}
                        Util.hideLoading(view: loginVC.view)
                        WebpageManager.shared.setPageLoadingStatus(status: .classList)
                    }
                } else {
                    WebpageManager.shared.setPageLoadingStatus(status: .login)
                    if let presentVC = self.navigationController?.topViewController as? LoginViewController  {
                        presentVC.invalidLogin.isHidden = false
                        Util.hideLoading(view: presentVC.view)
                    } else {self.navigationController?.pushViewController(loginVC, animated: true) }
                }
            }
        } else if pageManager.getPageLoadingStatus() == .classInfo { pageManager.setPageLoadingStatus(status: .classList)
        } else if pageManager.getPageLoadingStatus() == .signOut {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            self.navigationController?.pushViewController(loginVC, animated: true)
            loggedOut = true
            pageManager.setPageLoadingStatus(status: .login)
            UserDefaults.standard.removeObject(forKey: "class-order")
            self.toggleSideMenu()
        } else if pageManager.getPageLoadingStatus() == .refreshing {
            if UserDefaults.standard.array(forKey: "order-quarter-list") == nil {
                Util.getTermOptions(completion: { _ in
                    self.sidebarView.quarterLabel.text = Util.formatQuarterLabel()
                })
            }

            self.setClassLabels(completion: { _ in
                WebpageManager.shared.setPageLoadingStatus(status: .classList)
            })
            
        }
    }
}

extension UIView {
    func addOverlay(color: UIColor) {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.colors = [
            Util.getThemeColor().withAlphaComponent(0.7).cgColor,
            Util.getThemeColor().cgColor,
        ]
        gradient.locations = [ 0.0, 1.0]
        gradient.frame = self.bounds
        gradient.cornerRadius = 10
        self.layer.addSublayer(gradient)
    }
    
    func dropShadow(opacity: Float = 0.6, offset: CGSize = CGSize(width: 5, height: 5)) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
    }
}
class MyTapGesture: UITapGestureRecognizer {
    var className = ""
}
