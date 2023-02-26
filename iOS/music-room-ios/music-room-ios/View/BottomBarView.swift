import SwiftUI

struct BottomBarView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 76) {
            Button {
                switch viewModel.interfaceState {
                case .library:
                    viewModel.artworkTransitionAnchor = .center
                    
                case .player, .queue:
                    viewModel.artworkTransitionAnchor = .center
                }
                
                withAnimation {
                    viewModel.interfaceState = {
                        switch viewModel.interfaceState {
                        case .library:
                            return .player
                            
                        case .player, .queue:
                            return .library
                        }
                    }()
                }
            } label: {
                switch viewModel.interfaceState {
                case .player, .queue:
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.secondaryControlsColor)
                    
                case .library:
                    Image(systemName: "music.note.list")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.secondaryControlsColor)
                        .background(
                            viewModel.secondaryControlsColor,
                            in: RoundedRectangle(cornerRadius: 2)
                                .inset(by: -5)
                        )
                        .mask(alignment: .center) {
                            RoundedRectangle(cornerRadius: 2)
                                .inset(by: -5)
                                .overlay(alignment: .center) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 24, weight: .medium))
                                        .blendMode(.destinationOut)
                                }
                        }
                }
            }
            .frame(width: 40, height: 38)
            
            Button {
                viewModel.showingSignOutConfirmation = true
            } label: {
                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.secondaryControlsColor)
            }
            .frame(width: 40, height: 38)
            
            Button {
                switch viewModel.interfaceState {
                case .player, .library:
                    viewModel.artworkTransitionAnchor = .topLeading
                    
                case .queue:
                    viewModel.artworkTransitionAnchor = .topLeading
                }
                
                withAnimation {
                    viewModel.interfaceState = {
                        switch viewModel.interfaceState {
                        case .player, .library:
                            return .queue
                            
                        case .queue:
                            return .player
                        }
                    }()
                }
            } label: {
                switch viewModel.interfaceState {
                case .player, .library:
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.secondaryControlsColor)
                    
                case .queue:
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.secondaryControlsColor)
                        .background(
                            viewModel.secondaryControlsColor,
                            in: RoundedRectangle(cornerRadius: 2)
                                .inset(by: -5)
                        )
                        .mask(alignment: .center) {
                            RoundedRectangle(cornerRadius: 2)
                                .inset(by: -5)
                                .overlay(alignment: .center) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 24, weight: .medium))
                                        .blendMode(.destinationOut)
                                }
                        }
                    
                }
            }
            .frame(width: 40, height: 38)
        }
    }
}
