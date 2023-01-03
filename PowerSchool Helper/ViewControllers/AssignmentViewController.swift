//
//  AssignmentViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 10/22/22.
//

import Foundation
import UIKit

class AssignmentViewController: UIViewController, UIScrollViewDelegate {
    var pubScrollView: UIScrollView = UIScrollView()
    var assignments: [[String : String]] = []

    override func viewDidLoad() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.indicatorStyle = .white
        view.addSubview(scrollView)
        pubScrollView = scrollView
        addLabels(view: scrollView)
        let barFrame = CGRect(x: scrollView.frame.width/2-15, y: 10, width: 30, height: 5)
        let barView = UIView(frame: barFrame)
        barView.layer.cornerRadius = 3
        barView.backgroundColor = .gray
        scrollView.addSubview(barView)
    }
    
    func addLabels(view: UIScrollView) {
        let xpos: CGFloat = 10
        var ypos: CGFloat = 30
        
        
        var lastDate = ""
        for assignment in assignments {
            if assignment["date"]! != lastDate {
                let label = UILabel(frame: CGRect(x: xpos, y: ypos, width: view.frame.width-10, height: 50))
                label.backgroundColor = .black
                label.layer.masksToBounds = true
                label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
                label.textColor = Util.setFlagColor(flag: assignment["flags"]!)
                label.text = assignment["date"]!
                view.addSubview(label)
                let line = UIView(frame: CGRect(x: xpos, y: ypos+50, width: view.frame.width-10, height: 5))
                line.layer.cornerRadius = 3
                line.backgroundColor = .darkGray
                view.addSubview(line)
                ypos += 60
            }
            
            let label = UILabel(frame: CGRect(x: xpos, y: ypos, width: view.frame.size.width-20, height: 60))
            label.backgroundColor = .black
            label.layer.masksToBounds = true
            label.layer.cornerRadius = 10
            label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 2
            label.textColor = Util.setFlagColor(flag: assignment["flags"]!)
            let received = Double(assignment["score"]!.split(separator: "/")[0]) ?? 0
            let total = Double(assignment["score"]!.split(separator: "/")[1]) ?? 0
            let grade: Double = round(received / total * 10000) / 100
            label.text = "•  \(assignment["assignment"]!) (\(assignment["score"]!) | \(grade)%)"
            
            view.addSubview(label)
            ypos += 70
            lastDate = assignment["date"]!
        }
        view.contentSize = CGSize(width: view.frame.size.width, height: ypos + 80)
    }
}
