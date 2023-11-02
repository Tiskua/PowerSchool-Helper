//
//  TestView.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/7/23.
//

import UIKit

final class ClassView: UIView {
    @IBOutlet weak var namelabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    @IBOutlet weak var secondGradeLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    
    func commonInit() {
        guard let view = self.loadViewFromNib(nibName: "ClassView", index: 0) else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        namelabel.adjustsFontSizeToFitWidth = true
        namelabel.minimumScaleFactor = 0.2
        namelabel.numberOfLines = 0
        addSubview(view)
    }
    
    @IBAction func clickedSettingsButton(_ sender: Any) {
        for cl in DatabaseManager.shared.getClassesData(username: AccountManager.global.username) {
            if cl.className != namelabel.text || cl.quarter != AccountManager.global.selectedQuarter { continue }
            let href: String = cl.href
            if href.trimmingCharacters(in: .whitespacesAndNewlines) == "" { continue }
            AccountManager.global.classType = ClassType(username: AccountManager.global.username,
                                                        className: namelabel.text ?? "",
                                                        quarter: AccountManager.global.selectedQuarter,
                                                        href: href)
            break
        }
        
        guard let vc = Storyboards.shared.classSettingsViewController() else { return }
        vc.loadViewIfNeeded()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        self.findViewController()?.present(vc, animated: true)
        
        vc.classNameLabel.text = namelabel.text
    }
}

extension UIView {
    func loadViewFromNib(nibName: String, index: Int) -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil)[index] as? UIView
    }
    
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

