import SwiftUI

struct PlayerView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    var body: some View {
        
//                    VStack(alignment: .leading, spacing: 64) {
        HStack(alignment: .bottom) {
            GeometryReader { geometry in
//                                VStack {
//                                    Spacer()
                
                    viewModel.artworkImage(
                        viewModel.currentPlayerContent?.name,
                        geometry: geometry
                    )
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(8)
                    .shadow(color: Color(white: 0, opacity: 0.3), radius: 8, x: 0, y: 8)
//                                }
            }
        }
            .scaleEffect(
                viewModel.playerScale,
                anchor: .center
            )
            .transition(
                .scale(
                    scale: viewModel.artworkScale,
                    anchor: viewModel.artworkTransitionAnchor
                )
                .combined(with: .opacity)
                .combined(with: .offset(
                    x: {
                        switch viewModel.playerState {
                        case .paused:
                            return -viewModel.playlistArtworkWidth / 4

                        case .playing:
                            return 0
                        }
                    }(),
                    y: {
                        switch viewModel.playerState {
                        case .paused:
                            return -viewModel.playlistArtworkWidth / 4

                        case .playing:
                            return 0
                        }
                    }()
                ))
            )
            .animation(
                .interpolatingSpring(
                    mass: 1.0,
                    stiffness: 1,
                    damping: 1,
                    initialVelocity: 0.0
                )
                .speed(12),
                value: viewModel.animatingPlayerState
            )
        
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentPlayerContent?.title ?? viewModel.placeholderTitle)
                        .foregroundColor(viewModel.primaryControlsColor)
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    if let artist = viewModel.currentPlayerContent?.artist {
                        Text(artist)
                            .foregroundColor(viewModel.secondaryControlsColor)
                            .font(.title2)
                            .fontWeight(.regular)
                    }
                }
                
                Spacer()
                
                Button {
                    switch viewModel.playerQuality {
                    case .standard:
                        viewModel.playerQuality = .highFidelity
                        
                    case .highFidelity:
                        viewModel.playerQuality = .standard
                    }
                } label: {
                    switch viewModel.playerQuality {
                    case .standard:
                        Text("HiFi")
                            .foregroundColor(viewModel.tertiaryControlsColor)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .dynamicTypeSize(.large)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .inset(by: -5)
                                    .strokeBorder(lineWidth: 1.5)
                                    .foregroundColor(viewModel.tertiaryControlsColor)
                            )
                            .padding(5)
                        
                    case .highFidelity:
                        Text("HiFi")
                            .foregroundColor(viewModel.primaryControlsColor)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.semibold)
                            .dynamicTypeSize(.large)
                            .background(
                                viewModel.primaryControlsColor,
                                in: RoundedRectangle(cornerRadius: 2)
                                    .inset(by: -5)
                            )
                            .mask(alignment: .center) {
                                RoundedRectangle(cornerRadius: 2)
                                    .inset(by: -5)
                                    .overlay(alignment: .center) {
                                        Text("HiFi")
                                            .foregroundColor(viewModel.primaryControlsColor)
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.semibold)
                                            .dynamicTypeSize(.large)
                                            .blendMode(.destinationOut)
                                    }
                            }
                            .padding(5)
                    }
                }
            }
            
            VStack(spacing: 8) {
                ProgressSlider(
                    trackProgress: $viewModel.trackProgress,
                    isTracking: $viewModel.isProgressTracking,
                    initialValue: $viewModel.initialProgressValue,
                    shouldAnimatePadding: $viewModel.shouldAnimateProgressPadding
                )
                    .frame(height: 8)
                    .accentColor(viewModel.primaryControlsColor)
                    .animation(
                        .linear(duration: 1),
                        value: viewModel.shouldAnimateProgressSlider
                    )
                
                HStack {
                    Text(viewModel.trackProgress.value.time)
                        .foregroundColor(viewModel.secondaryControlsColor)
                    
                    Spacer()
                    
                    Text(viewModel.trackProgress.remaining.time)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(viewModel.secondaryControlsColor)
                }
            }
        }
        .transition(
            .move(edge: .top)
            .combined(with: .opacity)
        )
//                    }
    }
}
