//
//  WebPageManager.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 12/22/22.
//

import Foundation
import UIKit
import WebKit

class WebpageManager {
    static let shared = WebpageManager()
    
    let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 100), configuration: configuration)
        webView.isHidden = true
        return webView
    }()
    
    
    
    private var pageLoadingStatus: PageLoadingStatus = .unknown
    enum PageLoadingStatus {
        case inital
        case login
        case main
        case classMenu
        case signOut
        case unknown
    }
    
    
    public func setPageLoadingStatus(status: PageLoadingStatus) {
        pageLoadingStatus = status
    }
    public func getPageLoadingStatus() -> PageLoadingStatus {
        return pageLoadingStatus
    }
}
