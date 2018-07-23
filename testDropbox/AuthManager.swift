//
//  AuthManager.swift
//  testDropbox
//
//  Created by George Sabanov on 14.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import Foundation
import SwiftyDropbox
class AuthManager {
    static var authObserver: Any?
    static var authorizedClient: DropboxClient? {
        get {
            return DropboxClientsManager.authorizedClient
        }
    }

    class func authorise(controller: UIViewController, completionHandler: @escaping (_ completed: Bool) -> ())
    {
        if(authObserver == nil)
        {
            authObserver = NotificationCenter.default.addObserver(forName: .onDropboxAuth, object: nil, queue: nil) { (notification) in
                let result: DropboxOAuthResult = notification.userInfo!["result"] as? DropboxOAuthResult ?? .cancel
                switch result
                {
                case .success(_): 
                    completionHandler(true)
                case .error(_, _):
                    completionHandler(false)
                case .cancel:
                    break
                }
            }
        }
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: controller,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [String : Any](), completionHandler: nil)
        })
    }
    
}

extension Notification.Name {
    
    static let onDropboxAuth = Notification.Name("on-selected-skin")
}
