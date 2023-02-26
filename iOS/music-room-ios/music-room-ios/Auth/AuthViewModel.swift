//
//  AuthViewModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 28.06.2022.
//

import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published
    var isShowing = false
    
    @Published
    var usernameText = ""
    
    @Published
    var passwordText = ""
    
    @Published
    var isLoading = false
}
