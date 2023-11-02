//
//  ClassInfoBarVC.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 3/23/23.
//

import UIKit
import SwiftUI
import RealmSwift

class ClassInfoTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

extension ClassInfoTabBarController: UITabBarControllerDelegate  {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tabViewControllers = tabBarController.viewControllers!
        guard let toIndex = tabViewControllers.firstIndex(of: viewController) else {return false }
        animateToTab(tab: tabBarController, toIndex: toIndex)
        return true
    }

    func animateToTab(tab: UITabBarController, toIndex: Int) {
        let tabViewControllers = tab.viewControllers!
        let fromView = tab.selectedViewController!.view
        let toView = tabViewControllers[toIndex].view!
        let fromIndex = tabViewControllers.firstIndex(of: tab.selectedViewController!)
        guard fromIndex != toIndex else {return}
        
        fromView?.superview!.addSubview(toView)
        
        let screenWidth = UIScreen.main.bounds.size.width;
        let scrollRight = toIndex > fromIndex!;
        let offset = (scrollRight ? screenWidth : -screenWidth)
        toView.center = CGPoint(x: fromView!.center.x + offset, y: toView.center.y)

        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                fromView!.center = CGPoint(x: fromView!.center.x - offset, y: fromView!.center.y);
                toView.center   = CGPoint(x: toView.center.x - offset, y: toView.center.y);
            }, completion: { finished in
                fromView!.removeFromSuperview()
                tab.selectedIndex = toIndex
                tab.view.isUserInteractionEnabled = true
            })
    }

}


class MainTabBar: UITabBarController {
    let spacing: CGFloat = 12
    var barProfileImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        var profileImage = UIImage(named: "DefaultProfilePicture")
        if let savedprofileImage = Util.getImage(key: "profile-pic") {profileImage = savedprofileImage}
        barProfileImageView.image = profileImage
        barProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openStudentInfoVC)))
        barProfileImageView.layer.masksToBounds = true
        barProfileImageView.isUserInteractionEnabled = true
        barProfileImageView.clipsToBounds = true
        barProfileImageView.layer.borderColor = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1).cgColor
        barProfileImageView.layer.borderWidth = 5
        barProfileImageView.contentMode = .scaleAspectFill
        view.insertSubview(barProfileImageView, aboveSubview: self.tabBar)
        moveTabBarItems()
        
        if #available(iOS 16, *) {
            if let item = self.tabBar.items?[1] {
                item.image = UIImage(systemName: "clipboard")
            }
        }
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        barProfileImageView.frame = CGRect(x: tabBar.center.x-25, y: tabBar.frame.origin.y, width: 50, height: 50)
        barProfileImageView.layer.cornerRadius = barProfileImageView.frame.width/2
    }
    
    @objc func openStudentInfoVC() {
        guard let vc = Storyboards.shared.studentInfoVC() else { return }
        
        if let tabItem = tabBar.items?[1], !tabItem.isEnabled {
            return
        }
        if let sheet = vc.sheetPresentationController {sheet.detents = [.medium(), .large()]}
        vc.sheetPresentationController?.prefersGrabberVisible = true
        self.present(vc, animated: true)
    }
    
}

extension MainTabBar: UITabBarControllerDelegate  {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tabViewControllers = tabBarController.viewControllers!
        guard let toIndex = tabViewControllers.firstIndex(of: viewController) else {return false }
        animateToTab(tab: tabBarController, toIndex: toIndex)

        return true
    }
    
    func moveTabBarItems() {
        for tab in tabBar.items! {
            tab.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        }
    }

    func animateToTab(tab: UITabBarController, toIndex: Int) {
        let tabViewControllers = tab.viewControllers!
        let fromView = tab.selectedViewController!.view
        let toView = tabViewControllers[toIndex].view!
        let fromIndex = tabViewControllers.firstIndex(of: tab.selectedViewController!)
        guard fromIndex != toIndex else {return}
        
        fromView?.superview!.addSubview(toView)
        
        let screenWidth = UIScreen.main.bounds.size.width;
        let scrollRight = toIndex > fromIndex!;
        let offset = (scrollRight ? screenWidth : -screenWidth)
        toView.center = CGPoint(x: fromView!.center.x + offset, y: toView.center.y)

        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                fromView!.center = CGPoint(x: fromView!.center.x - offset, y: fromView!.center.y);
                toView.center   = CGPoint(x: toView.center.x - offset, y: toView.center.y);
            }, completion: { finished in
                fromView!.removeFromSuperview()
                tab.selectedIndex = toIndex
                tab.view.isUserInteractionEnabled = true
            })
    }
    
    

}

class TabBarWithCorners: UITabBar {
    @IBInspectable var color: UIColor?
    @IBInspectable var radii: CGFloat = 18
    
    private var shapeLayer: CALayer?
    
    override func draw(_ rect: CGRect) {
        addShape()
        self.tintColor = Util.getThemeColor()
        self.unselectedItemTintColor = .gray
    }
    

    private func addShape() {
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = createPath()
        let darkness: CGFloat = 20/255
        shapeLayer.fillColor = UIColor(red: darkness, green: darkness, blue: darkness, alpha: 1).cgColor
        shapeLayer.lineWidth = 1

        
        if let oldShapeLayer = self.shapeLayer {
            layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
        } else {
            layer.insertSublayer(shapeLayer, at: 0)
        }
        
        self.shapeLayer = shapeLayer
    }
    
    private func createPath() -> CGPath {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radii, height: 0.0))
        
        return path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 18
    
    }
}
