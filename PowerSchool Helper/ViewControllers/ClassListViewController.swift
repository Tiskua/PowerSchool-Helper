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


class ClassListViewController: UIViewController, UIScrollViewDelegate {
    
    var selectedQuarter = 1
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
        banner.load(GADRequest())
        return banner
    }()
    
    private let banner2: GADBannerView = {
        let banner = GADBannerView()
        banner.adUnitID = "ca-app-pub-2145540291403574/4810125939"
        banner.load(GADRequest())
        return banner
    }()
    
    let backgroundOverlay: UIView = {
        let imageOverlay = UIView(frame: UIScreen.main.bounds)
        return imageOverlay
    }()
    
    var scrollView: UIScrollView!
    
    var showSideMenu = false
    
    let black = UIView()
    let sideMenuButton = UIButton()
    let gradientLayer = CAGradientLayer()
    let gradeLabel = UILabel()


    var selectedLayout: layoutOptions.RawValue = layoutOptions.doubleColumn.rawValue
    
    enum layoutOptions: String {
        case doubleColumn
        case singleColumn
    }

    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideMenu: UIView!
    @IBOutlet weak var quarterButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var quarterLabel: UILabel!
    @IBOutlet weak var GPALabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var layoutSegmentPicker: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AccountManager.global.username = UserDefaults.standard.string(forKey: "login-username") ?? "UK"
        AccountManager.global.password = KeychainManager().getPassword(username: AccountManager.global.username)
        
        if UserDefaults.standard.integer(forKey: "quarter") == 0 { UserDefaults.standard.set(1, forKey: "quarter") }
        selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        AccountManager.global.selectedQuarter = selectedQuarter
        if UserDefaults.standard.value(forKey: "selectedLayout") != nil {
            selectedLayout = UserDefaults.standard.value(forKey: "selectedLayout") as! layoutOptions.RawValue
            layoutSegmentPicker.selectedSegmentIndex = selectedLayout == layoutOptions.doubleColumn.rawValue ? 0 : 1
        }
        layoutSegmentPicker.selectedSegmentTintColor = Util.getThemeColor()
        GPALabel.textColor = Util.getThemeColor()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        view.insertSubview(backgroundImage, at: 0)
        
        if NetworkMonitor.shared.isConnected {
            WebpageManager.shared.loadURL() {_ in
                WebpageManager.shared.setPageLoadingStatus(status: .inital)
            }
            view.addSubview(WebpageManager.shared.webView)
            banner.rootViewController = self
            banner2.rootViewController = self
            scrollView.addSubview(banner)
            scrollView.addSubview(banner2)
        }
        
        addSideMenu()
        setBackgroundWallpaper()
        scrollView.backgroundColor = .clear
        
        view.insertSubview(backgroundOverlay, at: 1)
        quarterLabel.text = formatQuarterLabel()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateQuarter(_:)), name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshItems(_:)), name: Notification.Name(rawValue: "saved.settings"), object: nil)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRightGesture(gesture:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
        WebpageManager.shared.webView.navigationDelegate = self
        WebpageManager.shared.webView.frame = self.view.frame
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserDefaults.standard.string(forKey: "pslink") == "" || KeychainManager().getPassword(username: UserDefaults.standard.string(forKey: "login-username") ?? "UK") == "" {
            guard let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {return}
            loginVC.loadViewIfNeeded()
            loginVC.isModalInPresentation = true
            present(loginVC, animated: true)
        } else{
            Util.showLoading(view: self.view)
        }
    }
    
    func setBackgroundWallpaper() {
        Util.loadImage(imageView: backgroundImage) { success in
            if !success {
                self.backgroundImage.image = nil
                self.setGradientBackground()
            } else { self.setBackgroundOverlay() }
        }
    }
    
    func configureScrollView() {
        let refreshController: UIRefreshControl = UIRefreshControl()
        refreshController.addTarget(self, action:#selector(handleRefreshControl), for: .valueChanged)
        refreshController.tintColor = .lightGray
        scrollView.refreshControl = refreshController
    }
    
    @objc func handleRefreshControl() {
        setClassLabels() { _ in
            if !WebpageManager.shared.isLoopingClasses {
                WebpageManager.shared.isLoopingClasses = true
                WebpageManager.shared.loopThroughClasses(index: 0)
            }
        }

       DispatchQueue.main.async {
          self.scrollView.refreshControl?.endRefreshing()
       }
    }
    
    @objc func swipeRightGesture(gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            toggleSideMenu()
        }
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
        sideMenuButton.tintColor = Util.getThemeColor()
        layoutSegmentPicker.selectedSegmentTintColor = Util.getThemeColor()
        GPALabel.textColor = Util.getThemeColor()
        backgroundOverlay.layer.opacity = UserDefaults.standard.float(forKey: "background-overlay-opacity")
        setClassLabels() { _ in}
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
        if selectedQuarter != UserDefaults.standard.integer(forKey: "quarter") {
            selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
            quarterLabel.text = formatQuarterLabel()
            showLoading(c_view: self.view)
            setClassLabels() { _ in}
        }
    }
    
    
    @IBAction func quarterSelectViewButton(_ sender: Any) {
        let quarterSelectionVC = self.storyboard?.instantiateViewController(withIdentifier: "QuarterSelectionController") as! QuarterSelectionController
        
        if let sheet = quarterSelectionVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
        }
        self.present(quarterSelectionVC, animated: true)
    }
    
    func addSideMenu() {
        let topBar = UIView(frame: CGRect(x: 0, y: 10, width: view.frame.width, height: 50))
        topBar.backgroundColor = .black.withAlphaComponent(0.3)
        topBar.layer.shadowColor = UIColor.black.cgColor
        topBar.layer.shadowOpacity = 0.3
        topBar.layer.shadowOffset = CGSize(width: 0, height: 6)
        topBar.layer.shadowRadius = 5
        
        gradeLabel.frame = CGRect(x: 10, y: 10, width: view.frame.width, height: 50)
        gradeLabel.text = "Grades"
        gradeLabel.font = UIFont(name: "Avenir Next Bold", size: 33)
        gradeLabel.textColor = Util.getThemeColor()
        
        
        sideMenuButton.frame = CGRect(x: view.frame.size.width-50, y: 20, width: 30, height: 30)
        let config = UIImage.SymbolConfiguration(pointSize: 80)
        sideMenuButton.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: config), for: .normal)
        sideMenuButton.tintColor = Util.getThemeColor()
        sideMenuButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSideMenu)))
        
        black.frame = view.bounds
        black.backgroundColor = .black.withAlphaComponent(0.5)
        black.isHidden = true
        black.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSideMenu)))
        
        sideMenu.frame.size.height = view.frame.height
        sideMenu.layer.shadowColor = UIColor.black.cgColor
        sideMenu.layer.shadowOpacity = 0.7
        sideMenu.layer.shadowOffset = .zero
        sideMenu.layer.shadowRadius = 10
        
        let image: UIImage = (UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration:
                                        UIImage.SymbolConfiguration(pointSize: 20)))!
        logoutButton.setImage(image, for: .normal)
        
        view.addSubview(scrollView)
        view.addSubview(black)
        scrollView.addSubview(topBar)
        configureScrollView()
        scrollView.addSubview(gradeLabel)
        scrollView.addSubview(sideMenuButton)
        view.addSubview(sideMenu)
    }
    
    @objc func toggleSideMenu() {
        let config = UIImage.SymbolConfiguration(pointSize: 80)
        if showSideMenu {
            UIView.animate(withDuration: 0.32, animations: {
                self.black.isHidden = true
                self.leadingConstraint.constant = -220
                self.view.layoutIfNeeded()
                self.sideMenuButton.setImage(UIImage(systemName: "line.3.horizontal", withConfiguration: config), for: .normal)
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.black.isHidden = false
                self.leadingConstraint.constant = 0;
                self.view.layoutIfNeeded()
                self.sideMenuButton.setImage(UIImage(systemName: "x.circle", withConfiguration: config), for: .normal)
            })
        }
        showSideMenu = !showSideMenu

    }
    
    @IBAction func layoutControlClick(_ sender: Any) {
        switch layoutSegmentPicker.selectedSegmentIndex {
            case 0: selectedLayout = layoutOptions.doubleColumn.rawValue
            case 1: selectedLayout = layoutOptions.singleColumn.rawValue
            default: selectedLayout = layoutOptions.singleColumn.rawValue
        }
        UserDefaults.standard.setValue(selectedLayout, forKey: "selectedLayout")
        setClassLabels() { _ in }
    }
    
    func formatQuarterLabel() -> String {
        switch self.selectedQuarter {
            case 1: return "Q1"
            case 2: return "Q2"
            case 3: return "S1"
            case 4: return "Q3"
            case 5: return "F1"
            case 6: return "Q4"
            case 7: return "S2"
            case 8: return "Y1"
            default: return "UK"
        }
    }

    @objc func clearInfo() {
        while let viewWithTag = self.view.viewWithTag(100) {viewWithTag.removeFromSuperview()}
        while let viewWithTag = self.view.viewWithTag(102) {viewWithTag.removeFromSuperview()}
        while let viewWithTag = self.view.viewWithTag(103) {viewWithTag.removeFromSuperview()}
        while let viewWithTag = self.view.viewWithTag(104) {viewWithTag.removeFromSuperview()}
        while let viewWithTag = self.view.viewWithTag(105) {viewWithTag.removeFromSuperview()}
    }

    func showLoading(c_view: UIView) {
        let loadingBG = UIView(frame: CGRect(x: 0, y: 0, width: c_view.frame.width, height: c_view.frame.height))
        loadingBG.backgroundColor = .black
        loadingBG.layer.opacity = 0.8
        loadingBG.tag = 200
        c_view.addSubview(loadingBG)
        
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
    
    @objc func clickedClassButton(recognizer: MyTapGesture) {
        if showSideMenu {return}
        WebpageManager.shared.checkIfLoggedOut() { isLoggedOut in
            if isLoggedOut { return }
            for cl in ClassInfoManager.shared.getClassesData(username: AccountManager.global.username) {
                if cl.class_name == recognizer.className && cl.quarter == AccountManager.global.selectedQuarter {
                    let href: String = cl.href
                    self.showLoading(c_view: self.view)
                    self.selectedClassName = cl.class_name
                    self.selectedhref = cl.href
                    WebpageManager.shared.isLoopingClasses = false
                    if AccountManager.global.updatedClasses.contains(cl.class_name) {
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
        AccountManager.global.classType = ClassType(username: AccountManager.global.username, className: selectedClassName, quarter: selectedQuarter, href: selectedhref)
        let classInfoStoryboard = UIStoryboard(name: "ClassInfo", bundle: nil)
        guard let tabBar = classInfoStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? TabBarController else {return}
        present(tabBar, animated: true)
        hideLoading()
    }
    
    func getClassName(text: String) -> String {
        let textArray = text.components(separatedBy: "Email")
        let className = textArray[0].trimmingCharacters(in: .whitespacesAndNewlines)
        return className
    }
    func getTeacher(text: String) -> String {
        let textArray = text.components(separatedBy: "Email")
        let teacherAndRoom = textArray[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let teacher = teacherAndRoom.components(separatedBy: "Rm")[0].replacingOccurrences(of: "-", with: "")
        return teacher.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setClassLabels(completion: @escaping (Bool) -> Void) {
        if AccountManager.global.password == "" { return }
        clearInfo()
        var ypos = 95
        var xpos = selectedLayout == layoutOptions.doubleColumn.rawValue ? 5 : 15
        WebpageManager.shared.checkForClasses() { didFind in
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [self]result, error in
                guard let html = result as? String, error == nil else {return}
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let trs: Elements = try doc.select("tr")
                    let length = trs.size()-10
                    var classList: [[String : String]] = []
                    if length < 0 { return }
                    for i in 0...length {
                        let tds: Elements = try trs[2+i].select("td")
                        let text:String = try tds[11].text()
                        let classname = getClassName(text: text)
                        
                        let quarterIndex = 11+selectedQuarter
                        if tds[quarterIndex].hasClass("notInSession") {continue}
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
                        let classType = ClassType(username: AccountManager.global.username, className: classname, quarter: selectedQuarter, href: href)
                        ClassInfoManager.shared.addClass(username: AccountManager.global.username, classType: classType)
                        ClassInfoManager.shared.setClassData(classType: classType, type: .href, value: href)
                        ClassInfoManager.shared.setClassData(classType: classType, type: .weightedGrade, value: numWeightedGradeVal)
                        ClassInfoManager.shared.setClassData(classType: classType, type: .grade, value: numGradeVal)
                        classList.append([
                            "className" : classname,
                            "weightedGrade" : String(numWeightedGradeVal)
                        ])
                    }
                    
                  
                    var adPos = Int.random(in : 0...classList.count-1)
                    let previousAdPos = adPos
                    
                    for a in 1...2 {
                        classList.insert([
                            "className" : "BANNER_CLASS_\(a)",
                            "weightedGrade" : "-1"
                        ], at: adPos)
                        adPos = Int.random(in : 0...classList.count)
                        if adPos == previousAdPos { adPos = Int.random(in : 0...classList.count-1)}
                    }
                    for (index,cl) in classList.enumerated() {
                        addLabels(data: cl, position: CGPoint(x: xpos, y: ypos))
                        let newValues = positionLabels(xpos: xpos, ypos: ypos, index: index-1)
                        xpos = newValues[0]
                        ypos = newValues[1]
                    }
                    fixSrollHeight(ypos: ypos)
                    setGPA()
                    Util.hideLoading(view: self.view)
                    completion(true)
                } catch {
                    print("COULD NOT GET DATA:" + error.localizedDescription)
                    completion(false)
                }
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
            if c.quarter != selectedQuarter {continue}
            grades.append(Int(c.grade))
        }
        let oGPA: String = Util.findOverallGPA(gradeList: grades).isNaN ? "Unknown" : String(Util.findOverallGPA(gradeList: grades))
        GPALabel.text = "\(oGPA)"
        hideLoading()
    }
    
    
    func addLabels(data: [String : String], href: String = "", position: CGPoint) {
        let className = data["className"] ?? "UNKNOWN"
        let grade:Int = Int(data["weightedGrade"] ?? "UNKNOWN") ?? 0
        
        let button_width: CGFloat = selectedLayout == layoutOptions.doubleColumn.rawValue ? CGFloat(view.frame.width/2.1) : view.frame.width - position.x*2
        let button_height: CGFloat = selectedLayout == layoutOptions.doubleColumn.rawValue ? 200 : 130
        
        let b: GADBannerView = className == "BANNER_CLASS_1" ? banner : banner2
        if className.contains("BANNER_CLASS") && grade == -1{
            b.backgroundColor = .black.withAlphaComponent(0.9)
            b.layer.cornerRadius = 10
            b.layer.borderWidth = 2
            b.layer.borderColor = Util.getThemeColor().cgColor
            b.frame = CGRect(x: position.x, y: CGFloat(position.y), width: button_width, height: button_height).integral
            return
        }
        
        let stringTapped = MyTapGesture.init(target: self, action: #selector(clickedClassButton(recognizer:)))
        stringTapped.className = className
        
        let classView = UIView(frame: CGRect(x: position.x, y: position.y, width: (button_width), height: button_height))
        classView.addOverlay(color: Util.getThemeColor().withAlphaComponent(0.85))
        classView.dropShadow()
        classView.layer.cornerRadius = 10
        classView.tag = 100
        classView.addGestureRecognizer(stringTapped)
        classView.layer.borderWidth = 3
        classView.layer.borderColor = Util.getThemeColor().cgColor
        
        
        let classNameLabel = UILabel(frame: CGRect(x: position.x, y: position.y, width: classView.frame.width, height: classView.frame.height/2))
        classNameLabel.font = UIFont(name: "Avenir Next Bold", size: 25)
        classNameLabel.lineBreakMode = .byWordWrapping
        classNameLabel.numberOfLines = 3
        classNameLabel.textAlignment = .center
        classNameLabel.text = String(className.trimmingCharacters(in: .whitespaces))
        classNameLabel.tag = 102
        classNameLabel.textColor = Util.getThemeColor().isLight() ?? true ? UIColor.black : UIColor.white
        
        if Util.getThemeColor().compareColor(withColor: classNameLabel.textColor, withTolerance: 0.15) { classNameLabel.textColor = .white }
        
        let classGradeLabel = UILabel(frame: CGRect(x: position.x, y: position.y + classView.frame.height/2, width: classView.frame.width, height: classView.frame.height/2))
        classGradeLabel.textAlignment = .center
        classGradeLabel.font = UIFont(name: "Avenir Next Heavy", size: 23)
        classGradeLabel.tag = 103
        
        
        if grade >= 93 {classGradeLabel.textColor = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1)}
        else if grade >= 85 {classGradeLabel.textColor = UIColor(red: 100/255, green: 240/255, blue: 33/255, alpha: 1)}
        else if grade >= 75 {classGradeLabel.textColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)}
        else if grade >= 65 {classGradeLabel.textColor = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)}
        else if grade <= 64 && grade > -1 {classGradeLabel.textColor = UIColor(red: 182/255, green: 5/255, blue: 5/255, alpha: 1)}

        if UserDefaults.standard.bool(forKey: "color-grades") == false { classGradeLabel.textColor = Util.getThemeColor().isLight() ?? true ? UIColor.black : UIColor.white }

        classGradeLabel.text = grade > -1 ? "\(grade)%" : "__%"
        
        if Util.getThemeColor().compareColor(withColor: classGradeLabel.textColor, withTolerance: 0.15) {
            classGradeLabel.layer.shadowColor = UIColor.black.cgColor
            classGradeLabel.layer.shadowOpacity = 0.9
            classGradeLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        }

        scrollView.addSubview(classView)
        scrollView.addSubview(classNameLabel)
        scrollView.addSubview(classGradeLabel)
    }
    
    @IBAction func logOut(_ sender: Any) {
        WebpageManager.shared.setPageLoadingStatus(status: .signOut)
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('btnLogout').click()")
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
            guard let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {return}
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
                    self.dismiss(animated: true)
                    self.setClassLabels() { _ in}
                    Util.hideLoading(view: loginVC.view)
                    WebpageManager.shared.setPageLoadingStatus(status: .classList)
                } else {
                    WebpageManager.shared.setPageLoadingStatus(status: .login)
                    if self.presentedViewController != nil {
                        let presentVC = self.presentedViewController as! LoginViewController
                        presentVC.invalidLogin.isHidden = false
                        Util.hideLoading(view: presentVC.view)
                    } else {
                        self.present(loginVC, animated: true) }
                }
            }
        } else if pageManager.getPageLoadingStatus() == .classInfo { pageManager.setPageLoadingStatus(status: .classList)
        } else if pageManager.getPageLoadingStatus() == .signOut {
            guard let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {return}
            self.present(loginVC, animated: true)
            loggedOut = true
            pageManager.setPageLoadingStatus(status: .login)
            self.toggleSideMenu()
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
    
    func dropShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowOffset = CGSize(width: 5, height: 5)
    }
}


class MyTapGesture: UITapGestureRecognizer {
    var className = ""
}
