//
//  DateExtensions.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 07/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
extension Date {
    
    func isoDate() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "yyyy:MM:dd"
        return f.string(from: self)
    }
    
    func isoTime() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "HH:mm:ss.SSSSSS"
        return f.string(from: self)
    }
}
