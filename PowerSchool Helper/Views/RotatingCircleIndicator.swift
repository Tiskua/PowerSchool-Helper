//
//  RotatingCircleIndicator.swift
//  
//
//  Created by Branson Campbell on 12/10/22.
//

import Foundation
import UIKit

class RotatingCirclesView: UIView {
    
    let spinningCircle = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
     }
    
    private func configure() {
        frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect = self.bounds
        let circularPath = UIBezierPath(ovalIn: rect)
        
        spinningCircle.path = circularPath.cgPath
        spinningCircle.fillColor = UIColor.clear.cgColor
        spinningCircle.strokeColor = Util.getThemeColor().cgColor
        spinningCircle.lineWidth = 10
        spinningCircle.strokeEnd = 0.25
        spinningCircle.lineCap = .round
        
        self.layer.addSublayer(spinningCircle)
    }
    
    func animate() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations:  {
            self.transform = CGAffineTransform(rotationAngle: .pi)
        }) { (completed) in
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
                self.transform = CGAffineTransform(rotationAngle: 0)
            }) { (completed) in
                self.animate()
            }
        }
                        
    }
}
