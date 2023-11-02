//
//  ReportClassView.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 9/19/23.
//

import UIKit

final class ReportClassView: UIView {
    

    
    @IBOutlet weak var classNameLabel: UILabel!
    @IBOutlet weak var gradeChangeLabel: UILabel!
    @IBOutlet weak var earnedPointsLabel: UILabel!
    @IBOutlet weak var totalPointsLabel: UILabel!
    @IBOutlet weak var assignmentChangeLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        guard let view = self.loadViewFromNib(nibName: "ReportClassView", index: 0) else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    
        addSubview(view)
        
    }
}
