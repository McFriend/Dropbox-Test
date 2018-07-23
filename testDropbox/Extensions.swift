//
//  Extensions.swift
//  testDropbox
//
//  Created by George Sabanov on 14.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import Foundation
import UIKit
import SwiftyDropbox

extension UIViewController
{
    func showAlert(title: String, message: String, cancelTitle: String)
    {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelButton = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertVC.addAction(cancelButton)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func showErrorAlert(message: String)
    {
        self.showAlert(title: NSLocalizedString("Error", comment: ""), message: message, cancelTitle: NSLocalizedString("OK", comment: ""))
    }
}
