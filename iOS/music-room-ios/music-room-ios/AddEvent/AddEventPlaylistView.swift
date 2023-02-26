import SwiftUI

struct AddEventPlaylistView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var addEventViewModel: AddEventViewModel
    
    @State
    var selectedPlaylist: Playlist?
    
    var body: some View {
        NavigationView {
            List(
                viewModel.playlists.indexed(),
                id: \.index
            ) { index, playlist in
                Button {
                    selectedPlaylist = playlist
                } label: {
                    HStack(alignment: .center, spacing: 16) {
                        Image(uiImage: playlist.cover)
                            .resizable()
                            .cornerRadius(4)
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.name)
                                .foregroundColor(viewModel.primaryControlsColor)
                                .font(.system(size: 18, weight: .medium))

                            if let user = viewModel.user(byID: playlist.author) {
                                Text("@\(user.username)")
                                    .foregroundColor(viewModel.secondaryControlsColor)
                                    .font(.system(size: 16, weight: .regular))
                            } else if viewModel.ownPlaylists
                                .contains(where: { $0.id == playlist.id }) {
                                Text("Yours")
                                    .foregroundColor(viewModel.secondaryControlsColor)
                                    .font(.system(size: 16, weight: .regular))
                            }
                        }

                        Spacer()

                        if let selectedPlaylistID = addEventViewModel.selectedPlaylist?.id,
                           let selectedPlaylistIndex = viewModel.playlists.firstIndex(where: {
                               $0.id == selectedPlaylistID
                        }),
                           index == selectedPlaylistIndex {
                            Label("", systemImage: "checkmark")
                                .font(.system(
                                    size: 16,
                                    weight: .medium
                                ))
                                .padding(.top, 4)
                                .foregroundColor(.pink)
                        }
                    }
                }
                .onChange(of: selectedPlaylist) { playlist in
                    addEventViewModel.selectedPlaylist = playlist

                    addEventViewModel.isShowingPlaylistSelect = false
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, 16)
            .navigationBarTitle("Choose a Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        addEventViewModel.selectedPlaylist = selectedPlaylist

                        addEventViewModel.isShowingPlaylistSelect = false
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }

                }
            }
        }
        .accentColor(.pink)
    }
}
