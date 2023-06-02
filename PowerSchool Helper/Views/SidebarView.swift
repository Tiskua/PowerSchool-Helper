//
//  SidebarView.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/9/23.
//

import UIKit

class SidebarView: UIView {

    @IBOutlet weak var quarterButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var quarterLabel: UILabel!
    @IBOutlet weak var GPALabel: UILabel!
    @IBOutlet weak var layoutSegmentPicker: UISegmentedControl!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var signoutButton: UIButton!
    
    var selectedLayout: layoutOptions.RawValue = layoutOptions.doubleColumn.rawValue
    enum layoutOptions: String {
        case doubleColumn
        case singleColumn
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
       
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        guard let view = self.loadViewFromNib(nibName: "SidebarView", index: 0) else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)
        
        if let layout = UserDefaults.standard.value(forKey: "selectedLayout") as? layoutOptions.RawValue {
            selectedLayout = layout
            layoutSegmentPicker.selectedSegmentIndex = selectedLayout == layoutOptions.doubleColumn.rawValue ? 0 : 1
        }
        GPALabel.textColor = Util.getThemeColor()
        quarterLabel.text = Util.formatQuarterLabel()
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.isUserInteractionEnabled = true
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20)
        let largeImage = UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: largeConfig)

        signoutButton.setImage(largeImage, for: .normal)
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.7
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 10

    }
    
    @IBAction func quarterSelectViewButton(_ sender: Any) {
        guard let quarterSelectVC = Storyboards.shared.quarterSelectViewController() else { return }
        if let sheet = quarterSelectVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
        }
        self.parentViewController!.present(quarterSelectVC, animated: true)
    }
    
    @IBAction func layoutControlClick(_ sender: Any) {
        switch layoutSegmentPicker.selectedSegmentIndex {
            case 0: selectedLayout = layoutOptions.doubleColumn.rawValue
            case 1: selectedLayout = layoutOptions.singleColumn.rawValue
            default: selectedLayout = layoutOptions.singleColumn.rawValue
        }
        UserDefaults.standard.setValue(selectedLayout, forKey: "selectedLayout")
        
        guard let classListVC = self.parentViewController as? ClassListViewController else {return}
        classListVC.selectedLayout = selectedLayout
        Util.showLoading(view: self.parentViewController!.view)

        classListVC.setClassLabels() { _ in }
    }
    
    @IBAction func logOut(_ sender: Any) {
        WebpageManager.shared.setPageLoadingStatus(status: .signOut)
        WebpageManager.shared.webView.evaluateJavaScript("document.getElementById('btnLogout').click()")
    }
    
    @IBAction func showOrderTable(_ sender: Any) {
        guard let orderVC = Storyboards.shared.orderViewController() else { return }
        self.parentViewController!.present(orderVC, animated: true)
    }
    @IBAction func settingsButtonAction(_ sender: Any) {
        guard let settingsVC = Storyboards.shared.settingsViewController() else { return }
        settingsVC.modalPresentationStyle = .fullScreen
        WebpageManager.shared.loadURL(completion: { _ in})
        self.parentViewController!.navigationController?.pushViewController(settingsVC, animated: true)
    }
    @IBAction func helpButtonAction(_ sender: Any) {
        guard let helpVC = Storyboards.shared.helpViewController() else { return }
        self.parentViewController!.present(helpVC, animated: true)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}
