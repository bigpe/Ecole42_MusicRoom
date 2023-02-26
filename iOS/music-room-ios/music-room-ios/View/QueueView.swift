import SwiftUI

struct QueueView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            viewModel.artworkImage(
                viewModel.currentPlayerContent?.name
            )
                .resizable()
                .cornerRadius(4)
                .frame(
                    width: viewModel.playlistArtworkWidth,
                    height: viewModel.playlistArtworkWidth
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentPlayerContent?.title ?? viewModel.placeholderTitle)
                    .foregroundColor(viewModel.primaryControlsColor)
                    .font(.system(size: 18, weight: .semibold))
                
                if let artist = viewModel.currentPlayerContent?.artist {
                    Text(artist)
                        .foregroundColor(viewModel.secondaryControlsColor)
                        .font(.system(size: 16, weight: .regular))
                }
            }
            
            Spacer()
        }
        .padding(.bottom, -32)
        .transition(
            .scale(
                scale: viewModel.artworkScale,
                anchor: .topLeading
            )
            .combined(with: .opacity)
            .combined(with: .offset(
                x: viewModel.playerArtworkPadding / 2 + viewModel.playlistArtworkWidth / 4,
                y: viewModel.playerArtworkPadding / 2 + viewModel.playlistArtworkWidth / 4
            ))
        )
        
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 24) {
                Text("Playing Next")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.primaryControlsColor)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        Task {
                            do {
                                try await viewModel.shuffle()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(viewModel.secondaryControlsColor)
                    }
                }

            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(
                        viewModel.queuedPlayerContent
                    ) {
                        track in
                        
                        Button {
                            guard
                                let sessionTrackID = track.sessionTrackID
                            else {
                                return
                            }
                            
                            Task {
                                try await viewModel.playTrack(
                                    sessionTrackID: sessionTrackID
                                )
                            }
                        } label: {
                            HStack(alignment: .center, spacing: 14) {
                                viewModel.artworks[track.name, default: viewModel.placeholderArtwork]
                                    .resizable()
                                    .cornerRadius(4)
                                    .frame(
                                        width: viewModel.playlistQueueArtworkWidth,
                                        height: viewModel.playlistQueueArtworkWidth
                                    )
                                    .onAppear {
                                        Task {
                                            await viewModel.prepareArtwork(track.name)
                                        }
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title ?? viewModel.defaultTitle)
                                        .foregroundColor(viewModel.primaryControlsColor)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if let artist = track.artist {
                                        Text(artist)
                                            .foregroundColor(viewModel.secondaryControlsColor)
                                            .font(.system(size: 14, weight: .regular))
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    guard
                                        let sessionTrackID = track.sessionTrackID
                                    else {
                                        return
                                    }
                                    
                                    Task {
                                        try await viewModel.delayPlayTrack(
                                            sessionTrackID: sessionTrackID
                                        )
                                        
                                        try await viewModel.playTrack(
                                            sessionTrackID: sessionTrackID
                                        )
                                    }
                                } label: {
                                    Image(systemName: "text.insert")
                                        .foregroundColor(viewModel.primaryControlsColor)
                                }
                            }
                        }

                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
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
}
