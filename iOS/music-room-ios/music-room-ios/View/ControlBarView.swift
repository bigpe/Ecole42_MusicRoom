import SwiftUI

struct ControlBarView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Button {
                Task {
                    try await viewModel.backward()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.primaryControlsColor)
            }
            .buttonStyle(SubControlButtonStyle())
            
            Button {
                Task {
                    do {
                        switch viewModel.playerState {
                        case .playing:
                            try await viewModel.pause()

                        case .paused:
                            try await viewModel.resume()
                        }
                        
                        await MainActor.run {
                            viewModel.animatingPlayerState.toggle()
                            
                            viewModel.playerState.toggle()
                        }
                    } catch {
                        print(error)
                    }
                }
            } label: {
                switch viewModel.playerState {
                case .playing:
                    Image(systemName: "pause.fill")
                        .font(.system(size: 48))

                case .paused:
                    Image(systemName: "play.fill")
                        .font(.system(size: 48))
                }
            }
            .frame(width: 80, height: 80)
            .buttonStyle(ControlButtonStyle())
            .transition(.opacity)
            .animation(
                .linear(duration: 0.34),
                value: viewModel.animatingPlayerState
            )
            
            Button {
                Task {
                    try await viewModel.forward()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.primaryControlsColor)
            }
            .frame(width: 80, height: 80)
            .buttonStyle(SubControlButtonStyle())
        }
    }
}
