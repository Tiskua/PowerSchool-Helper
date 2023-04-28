//
//  RotatingCircleIndicator.swift
//  
//
//  Created by Branson Campbell on 12/10/22.
//

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
        self.backgroundColor = .clear
        self.layer.borderWidth = 5
        self.layer.borderColor = Util.getThemeColor().cgColor
    }
    
    func animate() {
        UIView.animate(withDuration: 1.2, delay: 0, options: .curveEaseInOut, animations:  {
            self.frame = CGRect(x: self.frame.midX-25, y: self.frame.midY-25, width: 50, height: 50)
            self.layer.cornerRadius = self.frame.width/2
            self.transform = CGAffineTransform(rotationAngle: .pi)

        }) { (completed) in
            UIView.animate(withDuration: 1.2, delay: 0, options: .curveEaseInOut, animations: {
                self.layer.cornerRadius = 0
                self.frame = CGRect(x: self.frame.midX-50, y: self.frame.midY-50, width: 100, height: 100)
                self.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/4))

            }) { (completed) in
                UIView.animate(withDuration: 1.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.transform = CGAffineTransform(rotationAngle: 0)
                }) { (completed) in
                    self.animate()
                }
            }
        }
    }
}
