//
//  NotificationManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/4/23.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()

    public func scheduleNotification() {
        if UserDefaults.standard.bool(forKey: "reports-enabled") == false { return }
        if let reportDays = UserDefaults.standard.array(forKey: "reportDays") as? [Int] {
            var identifiers: [String] = []
            UNUserNotificationCenter.current().getPendingNotificationRequests() { requests in
                identifiers = requests.map { $0.identifier }
            }
               
            for day in reportDays {
                let identifier = "Day_\(day)"
                if !identifiers.contains(identifier) {
                    self.addNotification(day: day)
                }
            }
        }
    }
    
    func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func addNotification(day: Int) {
        let content = UNMutableNotificationContent()
        
        content.title = "Grade Report"
        content.subtitle = "A grade report has been created. Click to view the report"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "NotifcationSound.mp3"))
        
        var dateComponents = DateComponents()
        dateComponents.hour = 13
        if let time = UserDefaults.standard.string(forKey: "reportTime") {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            let dateTime = formatter.date(from: time)!
            let calendarDate = Calendar.current.dateComponents([.minute, .hour], from: dateTime)
            dateComponents.hour = calendarDate.hour
            dateComponents.minute = calendarDate.minute
        }
        dateComponents.weekday = day + 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "Day_\(day)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    public func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                UserDefaults.standard.set(true, forKey: "reports-enabled")
                if UserDefaults.standard.value(forKey: "reportDays") == nil || (UserDefaults.standard.array(forKey: "reportDays") as? [Int])!.isEmpty {
                    UserDefaults.standard.set([1,3,6], forKey: "reportDays")

                }
            }
            if let error = error {
                print(error.localizedDescription)
            }
            
        }
    }
}

