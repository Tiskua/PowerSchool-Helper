//
//  WatchManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 5/19/23.
//

import Foundation
import WatchConnectivity

class WatchManager: NSObject {
    static let shared = WatchManager()
    
    var session: WCSession?
    
    func setupWatchConnection() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("SETUP WATCH CONNECTION")

        }
    }
    
    func sendMessageToWatch(id: String, data: Any) {
        if let validSession = self.session {
            if validSession.isReachable {
                let dataToWatch: [String : Any] = [id : data]
                validSession.sendMessage(dataToWatch, replyHandler: nil) { error in
                    print("WATCHOS ERROR SENDING MESSAGE")}
                print("SENT MESSAGE TO WATCH")
            } else {
                print("NOT REACHABLE")
            }
        }
    }
}


extension WatchManager: WCSessionDelegate {
  //MARK: Delegate Methodes
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("ACITIVATION DID COMPLETE")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("SESSION DID BECOME INACTIVE")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("SESSION DID BECOME DEACTIVE")
    }
}
