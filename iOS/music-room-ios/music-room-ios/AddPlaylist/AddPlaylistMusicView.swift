import SwiftUI

struct AddPlaylistMusicView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var addPlaylistViewModel: AddPlaylistViewModel
    
    var body: some View {
        NavigationView {
            List(
                viewModel.tracksPlayerContent
            ) { track in
                Button {
                    if addPlaylistViewModel.selectedAddMusicTracks.contains(track.id) {
                        addPlaylistViewModel.selectedAddMusicTracks.removeAll(where: {
                            $0 == track.id
                        })
                    } else {
                        addPlaylistViewModel.selectedAddMusicTracks.append(track.id)
                    }
                } label: {
                    ZStack {
                        HStack(alignment: .center, spacing: 16) {
//                                cachedArtworkImage(track.name)
                            Image(systemName: "scribble")
                                .resizable()
                                .cornerRadius(4)
                                .frame(width: 60, height: 60)

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

                        if let index = addPlaylistViewModel.selectedAddMusicTracks
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
                        addPlaylistViewModel.selectedPlayerContent.append(
                            contentsOf: addPlaylistViewModel.selectedAddMusicTracks
                                .compactMap { trackID in
                                    viewModel.tracksPlayerContent.first(where: { $0.id == trackID })
                                }
                        )

                        addPlaylistViewModel.selectedAddMusicTracks.removeAll()

                        addPlaylistViewModel.isShowingAddMusic = false
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
