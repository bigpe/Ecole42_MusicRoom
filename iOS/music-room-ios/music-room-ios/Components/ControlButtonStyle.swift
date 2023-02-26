//
//  ControlButtonStyle.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 01.07.2022.
//

import SwiftUI

struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(16)
            .foregroundColor(configuration.isPressed ? Color(white: 1, opacity: 0.7) : .white)
            .background(configuration.isPressed ? Color(white: 1, opacity: 0.1) : .clear)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
