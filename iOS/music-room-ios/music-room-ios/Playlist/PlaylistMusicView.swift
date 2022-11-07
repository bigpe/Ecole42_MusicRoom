import SwiftUI

struct PlaylistMusicView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var playlistViewModel: PlaylistViewModel
    
    var body: some View {
        NavigationView {
            List(
                viewModel.tracksPlayerContent
            ) { track in
                Button {
                    if playlistViewModel.selectedAddMusicTracks.contains(track.id) {
                        playlistViewModel.selectedAddMusicTracks.removeAll(where: {
                            $0 == track.id
                        })
                    } else {
                        playlistViewModel.selectedAddMusicTracks.append(track.id)
                    }
                } label: {
                    ZStack {
                        HStack(alignment: .center, spacing: 16) {
                            viewModel.artworks[track.name, default: viewModel.placeholderArtwork]
                                .resizable()
                                .cornerRadius(4)
                                .frame(width: 60, height: 60)
                                .onAppear {
                                    Task {
                                        await viewModel.prepareArtwork(track.name)
                                    }
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title ?? viewModel.defaultTitle)
                                    .foregroundColor(viewModel.primaryControlsColor)
                                    .font(.system(size: 18, weight: .medium))

                                if let artist = track.artist {
                                    Text(artist)
                                        .foregroundColor(viewModel.secondaryControlsColor)
                                        .font(.system(size: 16, weight: .regular))
                                }
                            }

                            Spacer()
                        }

                        if let index = playlistViewModel.selectedAddMusicTracks
                            .firstIndex(where: { $0 == track.id }) {

                            HStack(alignment: .center) {
                                Spacer()

                                Label("\(index + 1)", systemImage: "checkmark")
                                    .font(.system(
                                        size: 16,
                                        weight: .medium
                                    ))
                                    .padding(.top, 4)
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }
            }
            .listStyle(.inset)
            .padding(.horizontal, 16)
            .navigationBarTitle("Add Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        playlistViewModel.isLoadingAddMusic = true

                        guard
                            let playlistID = playlistViewModel.selectedPlaylist?.id,
                            let playlistWebSocket = api.playlistWebSocket(
                                playlistID: playlistID
                            )
                        else {
                            return
                        }

                        Task {
                            playlistViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                guard
                                    let playlist = $0.first(where: {
                                        $0.id == playlistID
                                    })
                                else {
                                    return
                                }

                                playlistViewModel.selectedPlaylist = playlist
                            }

                            for trackID in playlistViewModel.selectedAddMusicTracks {
                                guard
                                    let trackID = trackID
                                else {
                                    continue
                                }

                                try await playlistWebSocket.send(
                                    PlaylistMessage(
                                        event: .addTrack,
                                        payload: .addTrack(track_id: trackID)
                                    )
                                )
                            }

                            await MainActor.run {
                                playlistViewModel.selectedAddMusicTracks = []

                                playlistViewModel.isLoadingAddMusic = false

                                playlistViewModel.isShowingAddMusic = false
                            }
                        }
                    } label: {
                        if !playlistViewModel.isLoadingAddMusic {
                            Text("Done")
                                .fontWeight(.semibold)
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }

                }
            }
        }
        .accentColor(.pink)
    }
}
