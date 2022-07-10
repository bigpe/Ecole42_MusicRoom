//
//  ContentView+AuthSheet.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 28.06.2022.
//

import SwiftUI

extension ContentView {
    @MainActor
    class AuthSheet: ObservableObject {
        
        @Published
        var isShowing = false
        
        @Published
        var usernameText = ""
        
        @Published
        var passwordText = ""
        
        @Published
        var isLoading = false
    }
}
