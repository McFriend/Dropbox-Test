//
//  Helpers.swift
//  testDropbox
//
//  Created by George Sabanov on 15.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import Foundation
import UIKit

class DateToString
{
    class func process(date: Date) -> String
    {
        return DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.short)
    }
}
