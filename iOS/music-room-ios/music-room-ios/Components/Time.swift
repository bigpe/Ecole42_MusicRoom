//
//  Decimal+Time.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

extension Decimal {
    var time: String {
        (self as NSDecimalNumber).doubleValue.time
    }
}

extension Optional where Wrapped == Decimal {
    var time: String {
        ((self as? NSDecimalNumber)?.doubleValue).time
    }
}

extension Double {
    var time: String {
        let formatter = DateComponentsFormatter()
        
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter.string(from: self) ?? Self.unknownTime
    }
    
    static var unknownTime: String {
        "--:--"
    }
}

extension Optional where Wrapped == Double {
    var time: String {
        guard let self = self else {
            return Wrapped.unknownTime
        }
        
        return self.time
    }
}
