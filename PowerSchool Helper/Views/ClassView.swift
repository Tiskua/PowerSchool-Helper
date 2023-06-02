//
//  TestView.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/7/23.
//

import UIKit

final class ClassView: UIView {
    var selectedLayout: layoutOptions.RawValue = layoutOptions.doubleColumn.rawValue

    enum layoutOptions: String {
        case doubleColumn
        case singleColumn
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    
    @IBOutlet weak var gradeLabelDouble: UILabel!
    @IBOutlet weak var nameLabelDouble: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    
    func commonInit() {
        if UserDefaults.standard.value(forKey: "selectedLayout") != nil {
            selectedLayout = UserDefaults.standard.value(forKey: "selectedLayout") as! layoutOptions.RawValue
        }
        let index: Int = selectedLayout == layoutOptions.singleColumn.rawValue ? 0 : 1
        guard let view = self.loadViewFromNib(nibName: "ClassView", index: index) else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.contentMode = .scaleAspectFill
        addSubview(view)
    }
}

extension UIView {
    func loadViewFromNib(nibName: String, index: Int) -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil)[index] as? UIView
    }
}
