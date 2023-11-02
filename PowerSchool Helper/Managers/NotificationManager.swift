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
        if let reportDay = UserDefaults.standard.value(forKey: "reportDay") as? Int {
            var identifiers: [String] = []
            UNUserNotificationCenter.current().getPendingNotificationRequests() { requests in
                identifiers = requests.map { $0.identifier }
            }
            let identifier = "Day_\(reportDay)"
            if !identifiers.contains(identifier) {
                self.addNotification(day: reportDay)
            }
        }
    }
    
    func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func addNotification(day: Int) {
        let content = UNMutableNotificationContent()
        
        content.title = "Grade Report"
        content.subtitle = "A new weekly grade report has been created! Tap to view the report."
        
        var dateComponents = DateComponents()
        dateComponents.hour = 14
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
            UserDefaults.standard.set(success, forKey: "reports-enabled")
            if UserDefaults.standard.value(forKey: "reportDay") == nil { UserDefaults.standard.set(5, forKey: "reportDay") }
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    public func setReportDate(completion: @escaping (Date) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests() { requests in
            if let calendarNotificationTrigger = requests.first?.trigger as? UNCalendarNotificationTrigger, let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate() {
                UserDefaults.standard.setValue(nextTriggerDate, forKey: "reportDate")
                completion(nextTriggerDate)
            }
        }
    }
    
    func getReportDate(completion: @escaping (Date) -> Void) {
        if UserDefaults.standard.bool(forKey: "reports-enabled") {
            UNUserNotificationCenter.current().getPendingNotificationRequests() { requests in
                if let calendarNotificationTrigger = requests.first?.trigger as? UNCalendarNotificationTrigger, let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate() {
                    completion(nextTriggerDate)
                } else {
                    completion(Date())
                }
            }
        } else {
            if let reportDay = UserDefaults.standard.value(forKey: "reportDay") as? Int {
                var dateComponents = Calendar.current.dateComponents([.year, .month], from: Date())
                var reportDates: [Date] = []
                let currentDate = Date()
                for _ in 0...2 {
                    for w in 1...4 {
                        dateComponents.weekOfMonth = w
                        dateComponents.weekday = reportDay + 1
                        
                        dateComponents.hour = 14
                        if let time = UserDefaults.standard.string(forKey: "reportTime") {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "hh:mm a"
                            let dateTime = formatter.date(from: time)!
                            let calendarDate = Calendar.current.dateComponents([.minute, .hour], from: dateTime)
                            dateComponents.hour = calendarDate.hour
                            dateComponents.minute = calendarDate.minute
                        }
                        let newDate = Calendar.current.date(from: dateComponents)!
                        if newDate > currentDate {
                            reportDates.append(newDate)
                        }
                    }
                    dateComponents.month! += 1
                }
                completion(findClosestDate(reportDates: reportDates))
            }
        }
    }
    
    func findClosestDate(reportDates: [Date]) -> Date {
        let currentDate = Date()
        let timeIntervals = reportDates.map { currentDate.timeIntervalSince($0) }

        if let minIndex = timeIntervals.enumerated().min(by: { abs($0.element) < abs($1.element) })?.offset {
            let closestDate = reportDates[minIndex]
            return closestDate
        } else {
            return Date()
        }
    }
}

