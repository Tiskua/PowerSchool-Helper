//
//  ClassInfoBarVC.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 3/23/23.
//

import UIKit
import SwiftUI
import RealmSwift

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        self.sheetPresentationController?.prefersGrabberVisible = true
    }
}

extension TabBarController: UITabBarControllerDelegate  {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tabViewControllers = tabBarController.viewControllers!
        guard let toIndex = tabViewControllers.firstIndex(of: viewController) else {return false }
        animateToTab(toIndex: toIndex)
        
        return true
    }
    
    func animateToTab(toIndex: Int) {
        let tabViewControllers = viewControllers!
        let fromView = selectedViewController!.view
        let toView = tabViewControllers[toIndex].view!
        let fromIndex = tabViewControllers.firstIndex(of: selectedViewController!)
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
                self.selectedIndex = toIndex
                self.view.isUserInteractionEnabled = true
            })
    }
    
}

class GradeHistoryVC: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let nameScreenData = NameScreenData()
        var gradePointData: [[[String : String]]] = []

        let assignments = ClassInfoManager.shared.getClassData(classType: AccountManager.global.classType, type: .assignments) as! RealmSwift.List<Assignments>
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 7, assignments: assignments))
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 14, assignments: assignments))
        gradePointData.append(GradeChartManager().getGradePointDataList(timeBack: 30, assignments: assignments))
        nameScreenData.assignments = gradePointData
        let gradeHistoryVC = UIHostingController(rootView: GradeChartView().environmentObject(nameScreenData))

        addChild(gradeHistoryVC)
        view.addSubview(gradeHistoryVC.view)
        gradeHistoryVC.didMove(toParent: self)
        gradeHistoryVC.view.frame = self.view.frame
        gradeHistoryVC.view.frame.size.height -= (self.navigationController?.navigationBar.frame.height ?? 0)
    }
}
