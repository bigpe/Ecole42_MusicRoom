//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI
import AlertToast
import AVFoundation
import MusicKit

struct ContentView: View {
    
    private let api = API()
    
    @StateObject
    private var viewModel = ViewModel()
    
    @StateObject
    private var authViewModel = AuthViewModel()
    
    @StateObject
    private var addPlaylistViewModel = AddPlaylistViewModel()
    
    @StateObject
    private var playlistViewModel = PlaylistViewModel()
    
    @StateObject
    private var addEventViewModel = AddEventViewModel()
    
    @StateObject
    private var eventViewModel = EventViewModel()
    
    // MARK: - Focused Field
    
    @FocusState
    var focusedField: Field?
    
    var body: some View {
        
        // MARK: - Main Layout
        
        ZStack {
            if let proxyColor = viewModel.artworkProxyPrimaryColor {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                proxyColor,
                                viewModel.gradient.backgroundColor,
                            ],
                            center: viewModel.gradient.center,
                            startRadius: viewModel.gradient.startRadius,
                            endRadius: viewModel.gradient.endRadius
                        )
                    )
                    .blur(radius: viewModel.gradient.blurRadius)
                    .overlay(viewModel.gradient.material)
                    .edgesIgnoringSafeArea(viewModel.gradient.ignoresSafeAreaEdges)
                    .transition(viewModel.gradient.transition)
            } else {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                viewModel.artworkPrimaryColor,
                                viewModel.gradient.backgroundColor,
                            ],
                            center: viewModel.gradient.center,
                            startRadius: viewModel.gradient.startRadius,
                            endRadius: viewModel.gradient.endRadius
                        )
                    )
                    .blur(radius: viewModel.gradient.blurRadius)
                    .overlay(viewModel.gradient.material)
                    .edgesIgnoringSafeArea(viewModel.gradient.ignoresSafeAreaEdges)
                    .transition(viewModel.gradient.transition)
            }
            
            VStack(alignment: .center, spacing: 64) {
                switch viewModel.interfaceState {
                    
                case .player:
                    PlayerView(api: api)
                        .environmentObject(viewModel)
                    
                case .queue:
                    QueueView(api: api)
                        .environmentObject(viewModel)
                    
                case .library:
                    LibraryView(api: api)
                        .environmentObject(viewModel)
                        .environmentObject(addPlaylistViewModel)
                        .environmentObject(playlistViewModel)
                        .environmentObject(addEventViewModel)
                        .environmentObject(eventViewModel)
                        .mask(
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(white: 0, opacity: 1))
                                
                                LinearGradient(
                                    colors: [
                                        Color(white: 0, opacity: 1),
                                        Color(white: 0, opacity: 0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 24)
                            }
                        )
                        .padding(.bottom, -64)
                        .transition(
                            .move(edge: .bottom)
                            .combined(with: .opacity)
                        )
                }
                
                ControlBarView(api: api)
                    .environmentObject(viewModel)
                
                BottomBarView(api: api)
                    .environmentObject(viewModel)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sheet(
            isPresented: $addPlaylistViewModel.isShowing,
            content: {
                AddPlaylistView(
                    api: api,
                    focusedField: $focusedField
                )
                    .environmentObject(viewModel)
                    .environmentObject(addPlaylistViewModel)
            }
        )
        .sheet(
            isPresented: $playlistViewModel.isShowing,
            content: {
                PlaylistView(
                    api: api,
                    focusedField: $focusedField
                )
                .environmentObject(viewModel)
                .environmentObject(playlistViewModel)
            }
        )
        .sheet(
            isPresented: $addEventViewModel.isShowing,
            content: {
                AddEventView(
                    api: api,
                    focusedField: $focusedField
                )
                .environmentObject(viewModel)
                .environmentObject(addEventViewModel)
            }
        )
        .sheet(
            isPresented: $eventViewModel.isShowing,
            content: {
                EventView(
                    api: api,
                    focusedField: $focusedField
                )
                .environmentObject(viewModel)
                .environmentObject(eventViewModel)
            }
        )
        .ignoresSafeArea(.keyboard)
        .confirmationDialog(
            "Sign Out?",
            isPresented: $viewModel.showingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            
            // MARK: - Sign Out Confirmation Dialog
            
            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        viewModel.showingSignOutConfirmation = false
                    }
                    
                    try await viewModel.signOut()
                    
                    await MainActor.run {
                        authViewModel.isShowing = true
                    }
                    
                    await MainActor.run {
                        viewModel.signInToastType = .complete(Color.pink)
                        viewModel.signInToastTitle = "Signed Out"
                        viewModel.signInToastSubtitle = "Bye"
                        viewModel.isSignInToastShowing = true
                    }
                }
            } label: {
                Text("Yes")
            }

        }
        .sheet(
            isPresented: $authViewModel.isShowing,
            content: {
                AuthView(api: api, focusedField: $focusedField)
                    .environmentObject(viewModel)
                    .environmentObject(authViewModel)
            }
        )
        .toast(
            isPresenting: $viewModel.isToastShowing,
            duration: 3,
            tapToDismiss: true,
            offsetY: 0,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: viewModel.toastType,
                    title: viewModel.toastTitle,
                    subTitle: viewModel.toastSubtitle,
                    style: nil
                )
            }
        )
        .onAppear {
            
            if MusicAuthorization.currentStatus == .notDetermined {
                Task {
                    _ = await MusicAuthorization.request()
                }
            }
            
            // MARK: - On Appear
            
            viewModel.api = api
            
            playlistViewModel.viewModel = viewModel
            eventViewModel.viewModel = viewModel
            
            if viewModel.isAuthorized {
                viewModel.updateData()
            } else {
                authViewModel.isShowing = !viewModel.isAuthorized
            }
        }
    }
}
