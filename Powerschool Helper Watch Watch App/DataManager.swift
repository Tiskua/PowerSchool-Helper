//
//  DataManager.swift
//  Powerschool Helper Watch Watch App
//
//  Created by Branson Campbell on 5/15/23.
//

import Foundation
import WatchConnectivity
import SwiftUI

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    @Published var recievedMessage = ""
    
    var session: WCSession
    init(session: WCSession = WCSession.default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }
    

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let recievedData: [[String : String]] = (message["classinfo"] as? [[String : String]]) {
                UserDefaults.standard.set(recievedData, forKey: "classdata")
            } else if let recievedData: String = (message["term"] as? String) {
                UserDefaults.standard.set(recievedData, forKey: "term")
            } else if let recievedData:String = (message["themeColor"]) as? String {
                UserDefaults.standard.set(recievedData, forKey: "themeColor")
            } else {
                print("ERROR")
            }
           
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("ACTIVATED")
    }
    
}

extension String {
    func stringToColor() -> Color {
        let componentsString = self.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        let components = componentsString.components(separatedBy: ", ")
        return Color(
            red: CGFloat((components[0] as NSString).floatValue),
            green: CGFloat((components[1] as NSString).floatValue),
            blue: CGFloat((components[2] as NSString).floatValue))
    }
}
