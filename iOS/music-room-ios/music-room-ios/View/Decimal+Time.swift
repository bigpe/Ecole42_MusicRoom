//
//  Decimal+Time.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

extension Decimal {
    var time: String {
        let formatter = DateComponentsFormatter()
        
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter.string(from: (self as NSDecimalNumber).doubleValue) ?? "--:--"
    }
}
