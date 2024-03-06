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
    
    var loggedOut = false
    let pageManager = WebpageManager.shared
    
    private let banner: GADBannerView = {
        let banner = GADBannerView()
        //        banner.adUnitID = "ca-app-pub-2145540291403574/8069022745"
        //        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.load(GADRequest())
        return banner
    }()
    
    private let banner2: GADBannerView = {
        let banner = GADBannerView()
        //        banner.adUnitID = "ca-app-pub-2145540291403574/4810125939"
        //        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        banner.load(GADRequest())
        return banner
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
    
    var classViewsList: [ClassView] = []
    
    private var classesModels = [StudentClassData]()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    var barProfileImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        WebpageManager.shared.webView.navigationDelegate = self
        
        schema()
        if UserDefaults.standard.integer(forKey: "quarter") == 0 {
            UserDefaults.standard.set(1, forKey: "quarter")
        }
        
        AccountManager.global.selectedQuarter = UserDefaults.standard.integer(forKey: "quarter")
        
        WebpageManager.shared.loadBaseUrl()
        WebpageManager.shared.setPageLoadingStatus(status: .initial)
        
        
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
        refreshController.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        refreshController.tintColor = Util.getThemeColor()
        scrollView.refreshControl = refreshController
        
        addQuarterBar()
        toggleTabItems(enabled: false)
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateProfileImage()
                
        guard let baseURL = UserDefaults.standard.value(forKey: "powerschool-url") as? String,
              let _ = UserDefaults.standard.value(forKey: "sign-in-type") as? String else {
            print("Failed to find url or sign-in-type")
            openLoginViewController()
            return
        }
        
        WebpageManager.shared.isValidURL(with: baseURL.safeURL(), completion: { [weak self] isValid in
            guard isValid else {
                self?.openLoginViewController()
                print("Failed to automatically login. Presenting login view controller")
                return
            }
            
            NotificationManager.shared.registerForPushNotifications()
            DispatchQueue.main.async {
                self?.setClassLabels(getNewData: false)
            }
        })
    }
    
    func openLoginViewController() {
        DispatchQueue.main.async {
            guard let loginVC = Storyboards.shared.loginViewController() else {return}
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        WebpageManager.shared.webView.frame = view.bounds
        
    }
    
    func schema() {
        guard let fileNmae = UserDefaults.standard.value(forKey: "realm-file-name") as? String else {
            return
        }
        DatabaseManager.shared.initizialeSchema(username: fileNmae)
        DatabaseManager.shared.getFileLocation()
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
        
        let bar = UIView(frame: CGRect(x: 30, y: 25, width: view.width-60, height: 3))
        bar.backgroundColor = .darkGray
        bar.layer.cornerRadius = 3
        quarterButton = UIButton(frame:  CGRect(x: view.width/2-50, y: 5, width: 100, height: 40), primaryAction: action)
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
            WebpageManager.shared.loadBaseUrl()
            return
        }
        setClassLabels(getNewData: true)
    }
    
    @objc func checkFromBackground() {
        Util.showLoading(view: self.view)
        WebpageManager.shared.checkForSignOutBox { found in
            if !found {
                Util.hideLoading(view: self.view)
                return
            } else {
                WebpageManager.shared.setPageLoadingStatus(status: .initial)
                WebpageManager.shared.loadBaseUrl()
                WebpageManager.shared.loadBaseUrl()
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
            let yPos = view.height-(navigationController?.navigationBar.height ?? 0)-10
            let noNetworkLabel = UILabel(frame:CGRect(x: 0, y: yPos, width: view.width, height: 30))
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
    
    
    
    @objc func classOrderChanged(_ notification: Notification) {
        WebpageManager.shared.setPageLoadingStatus(status: .refreshing)
        WebpageManager.shared.loadBaseUrl()
    }
    
    @objc func refreshAction() {
        Util.showLoading(view: self.view, text: "Gathering Class Data...")
        AccountManager.global.updatedClasses = []
        if !WebpageManager.shared.isLoopingClasses {
            WebpageManager.shared.isLoopingClasses = true
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.async {
                WebpageManager.shared.loopThroughClassData(index: 0, completion: { [weak self] in
                    WebpageManager.shared.setPageLoadingStatus(status: .login)
                    WebpageManager.shared.loadBaseUrl()
                    Util.hideLoading(view: self?.view ?? UIView())
                    
                })
            }
        }
        
        DispatchQueue.main.async {
            self.scrollView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func refreshItems(_ notification: Notification) {
        WebpageManager.shared.loadBaseUrl()
        DispatchQueue.main.async {
            
            var profileImage = UIImage(named: "DefaultProfilePicture")
            if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
            self.barProfileImageView.image = profileImage
            self.setClassLabels(getNewData: false)
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
        self.classesModels = []
    }
    
    
    @objc func openClassMenu(recognizer: ClassGestures) {
        print(recognizer.state)
        WebpageManager.shared.isLoopingClasses = false
       
        for cl in classesModels {
            if cl.className != recognizer.className { continue }
            if cl.href == "" { continue }

            Util.showLoading(view: self.view)
            
            guard NetworkMonitor.shared.isConnected && WebpageManager.shared.webpageLoadedSuccessfully else {
                self.selectClass(data: cl)
                return
            }
            
            WebpageManager.shared.openClass(href: cl.href, completion: { [weak self] _ in
                WebpageManager.shared.containsAssignments { success in
                    if success {
                        self?.selectClass(data: cl)
                        return
                    }
                }
            })
        }
    }
    
    func selectClass(data: StudentClassData) {
        AccountManager.global.classType = ClassType(username: AccountManager.global.username,
                                                    className: data.className,
                                                    quarter: AccountManager.global.selectedQuarter,
                                                    href: data.href)
        
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
    
    
    func retrieveData(getNewData: Bool, completion: @escaping (Result<[StudentClassData], Error>) -> (Void))  {
        if getNewData {
            guard NetworkMonitor.shared.isConnected else {
                print("No internet connection")
                return
            }
            
            getClassDataFromWebsite() { [weak self] result in
                switch result {
                case .success(let data):
                    self?.classesModels = data
                    print("Got New Class Information!")
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                    print("Failed to get Data from Website: \(error)")
                }
            }
        } else {
            guard let username = UserDefaults.standard.value(forKey: "login-username") as? String else {
                print("FAILED TO GET LOGIN USERNAME")
                return
            }
            let result = DatabaseManager.shared.getTermClasses(username: username, term: AccountManager.global.selectedQuarter)
            
            switch result {
            case .success(let classes):
                self.classesModels = classes
                completion(.success(classes))
            case .failure(let error):
                print("failed to get all classes: \(error)")
                completion(.failure(error))
                return
            }
        }
    }

    

    func setClassLabels(getNewData: Bool) {
        clearClassViews()
        retrieveData(getNewData: getNewData, completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let data):
                guard data.count > 0 else {
                    strongSelf.noClassData()
                    Util.hideLoading(view: strongSelf.view)
                    return
                }
                
                var ypos = 50
                let xpos = 10
                
                strongSelf.banner.backgroundColor = UIColor.black
                strongSelf.banner.frame = CGRect(x: 0, y: ypos, width: Int((strongSelf.view.width)), height: 50).integral
                strongSelf.banner.isHidden = false
                
                ypos += 70
                
                
                for cl in data {
                    strongSelf.addLabels(data: cl, position: CGPoint(x: xpos, y: ypos), backgroundColor: Util.getThemeColor().cgColor)
                    ypos += 220
                }
                strongSelf.banner2.backgroundColor = .black
                strongSelf.banner2.frame = CGRect(x: 0, y: ypos, width: Int((self?.view.width)!), height: 50).integral
                strongSelf.banner2.isHidden = false
                
                Util.hideLoading(view: self?.view ?? UIView())
                strongSelf.fixSrollHeight(ypos: ypos)
                strongSelf.toggleTabItems(enabled: true)
            case .failure(let error):
                print("Failed to set class labels: \(error)")
            }
        })
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
    
    enum DatabaseErrors: Error {
        case FailedToLocateClasses
        case NoClassesFound
    }
    
    private func getClassDataFromWebsite(completion: @escaping (Result<[StudentClassData], Error>) -> (Void)) {
        WebpageManager.shared.checkForClasses() { didFind in
            if !didFind { 
                print("Could not find classes in website")
                completion(.failure(DatabaseErrors.FailedToLocateClasses))
            }
            
            WebpageManager.shared.webView.evaluateJavaScript("document.body.innerHTML") { [weak self] result, error in
                guard let strongSelf = self else { return }
                guard let html = result as? String, error == nil else {
                    completion(.failure(DatabaseErrors.FailedToLocateClasses))
                    return
                }
                do {
                    let doc: Document = try SwiftSoup.parseBodyFragment(html)
                    let trs: Elements = try doc.select("tr")
                    let length = trs.size()-10
                    if length <= 0 {
                        print("Length is 0!")
                        completion(.failure(DatabaseErrors.NoClassesFound))
                        return
                    }
                    
                    var classList = [StudentClassData]()
                    
                    for i in 0...length {
                        let tds: Elements = try trs[2+i].select("td")
                        if tds.count < 12 { continue }
                        
                        let text:String = try tds[11].text()
                        
                         let classname = strongSelf.getClassName(text: text)
           
                        
                        let quarterIndex = 11+AccountManager.global.selectedQuarter
                        if tds[quarterIndex].hasClass("notInSession") { continue }
                        
                        guard let link = try tds[quarterIndex].select("a").first() else { continue }
                        let href:String = try link.attr("href")
                        
                        let gradeval = try tds[quarterIndex].text()
                        let numWeightedGradeVal: Int = Int(gradeval.split(separator: " ")[0]) ?? -1
                        let numGradeVal: Int = Int(gradeval.split(separator: " ")[1]) ?? -1
                        let weight:Int = numWeightedGradeVal-100
                        if numGradeVal == -1 {
                            if UserDefaults.standard.bool(forKey: "hide-ug-class") { continue }
                        }
                        
                        let classType = ClassType(username: AccountManager.global.username, className: classname, quarter: AccountManager.global.selectedQuarter, href: href)
                        DatabaseManager.shared.addClass(username: AccountManager.global.username, classType: classType)
                        DatabaseManager.shared.setClassData(classType: classType, type: .href, value: href)
                        DatabaseManager.shared.setClassData(classType: classType, type: .weightedGrade, value: numWeightedGradeVal)
                        DatabaseManager.shared.setClassData(classType: classType, type: .grade, value: numGradeVal)
                        
                        if DatabaseManager.shared.getClassData(classType: classType, type: .placement) as? String == "" {
                            DatabaseManager.shared.setClassData(classType: classType, type: .placement, value: strongSelf.getClassPlacement(name: classname.lowercased()))
                        }
                        
                        if DatabaseManager.shared.getClassData(classType: classType, type: .weight) as? Int == -1 {
                            DatabaseManager.shared.setClassData(classType: classType, type: .weight, value: weight)
                        }
                        
                        let classData = StudentClassData()
                        classData.className = classname
                        classData.weighted_grade = numWeightedGradeVal
                        classData.grade = numGradeVal
                        classData.href = href
                        
                        classList.append(classData)
                       
                    }
                    guard classList.count > 0 else {
                        completion(.failure(DatabaseErrors.NoClassesFound))
                        return
                    }
//                    if DatabaseManager.shared.containsOldClasses(currentClasses: strongSelf.classesModels) {
//                        DatabaseManager.shared.deleteClasses()
//                        completion(.failure(DatabaseErrors.FailedToGetClasses))
//                        self.retrieveData(getNewData: true, completion: {_ in })
//                        return
//                    }
                    completion(.success(classList))
                    
                } catch {
                    completion(.failure(DatabaseErrors.FailedToLocateClasses))
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
    
    func addLabels(data: StudentClassData, href: String = "", position: CGPoint, backgroundColor: CGColor) {
        
        let button_width: CGFloat = view.width - position.x*2
        let button_height: CGFloat = 200
        
        let stringTapped = ClassGestures.init(target: self, action: #selector(openClassMenu(recognizer:)))
        stringTapped.className = data.className
        
        let test = UIGestureRecognizer(target: self, action: #selector(didtap(_:)))
        
        let classView = ClassView(frame: CGRect(x: position.x, y: position.y, width: button_width, height: button_height))
        classView.layer.opacity = 0

        classView.namelabel.text = String(data.className.trimmingCharacters(in: .whitespaces))
        classView.addGestureRecognizer(stringTapped)
        classView.addGestureRecognizer(test)

        classView.backgroundColor = UIColor(cgColor: backgroundColor).withAlphaComponent(0.3)
        classView.layer.cornerRadius = 20
        classView.clipsToBounds = true
        classView.layer.masksToBounds = true
                
        classView.layer.borderColor = backgroundColor.copy(alpha: 0.5)
        classView.layer.borderWidth = 4

        classView.gradeLabel.text = data.weighted_grade > -1 ? "\(data.weighted_grade)%" : "__"
        classView.secondGradeLabel.text = data.grade > -1 ? "\(data.grade)%" : "__"
        
        scrollView.addSubview(classView)
        classViewsList.append(classView)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
            classView.layer.opacity = 1
         })
    }
    
    func noClassData() {
        let label = UILabel(frame: CGRect(x: 20, y: (view.height/2)-100, width: view.width-40, height: 100))
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
        if CGFloat(ypos) + bottomOffset > view.height {scrollView.contentSize.height = CGFloat(ypos) + bottomOffset}
        else {scrollView.contentSize.height = view.height+20}
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "quarter.selected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "saved.settings"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "order.changed"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "network.changed"), object: nil)
    }
    
    @objc private func didtap(_ sender: UITapGestureRecognizer) {
        print(sender.state)
    }
}



class ClassGestures: UITapGestureRecognizer {
    var className = ""
}


