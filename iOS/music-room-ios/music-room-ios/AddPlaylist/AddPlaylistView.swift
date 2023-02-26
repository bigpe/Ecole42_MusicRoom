import SwiftUI

struct AddPlaylistView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var addPlaylistViewModel: AddPlaylistViewModel
    
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    Picker(selection: $addPlaylistViewModel.accessType) {
                        ForEach(Playlist.AccessType.allCases) { accessType in
                            Text(accessType.description)
                        }
                    } label: {
                        Text("Access")
                    }
                    .pickerStyle(.segmented)

                    TextField(text: $addPlaylistViewModel.nameText) {
                        Text("Playlist Name")
                    }
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.sentences)
                    .focused(focusedField, equals: .addPlaylistName)
                }

                Divider()

                Button {
                    addPlaylistViewModel.isShowingAddMusic = true
                } label: {
                    Label("Add Music", systemImage: "plus.circle.fill")
                }
                .tint(.pink)

                List(
                    addPlaylistViewModel.selectedPlayerContent.indexed(),
                    id: \.index
                ) { index, track in
                    HStack(alignment: .center, spacing: 16) {
                        viewModel.artworks[track.name, default: viewModel.placeholderArtwork]
                            .resizable()
                            .cornerRadius(4)
                            .frame(width: 60, height: 60)
                            .padding(.leading, -16)
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
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            addPlaylistViewModel.selectedPlayerContent.remove(at: index)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal, 16)
            .navigationBarTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        guard
                            addPlaylistViewModel.nameText.isEmpty,
                            addPlaylistViewModel.selectedPlayerContent.isEmpty
                        else {
                            addPlaylistViewModel.showingCancelConfirmation = true

                            return
                        }

                        addPlaylistViewModel.isShowing = false

                        addPlaylistViewModel.reset()
                    } label: {
                        Text("Cancel")
                    }

                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        let playlistName = addPlaylistViewModel.nameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        let accessType = addPlaylistViewModel.accessType

                        guard
                            !playlistName.isEmpty,
                            !addPlaylistViewModel.isLoading,
                            let playlistsWebSocket = api.playlistsWebSocket
                        else {
                            return
                        }

                        let playlistUUID = UUID()

                        Task {
                            do {
                                await MainActor.run {
                                    addPlaylistViewModel.isLoading = true

                                    addPlaylistViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                        guard
                                            let playlistID = $0.first(where: {
                                                $0.name == playlistUUID.description
                                            })?.id
                                        else {
                                            return
                                        }

                                        addPlaylistViewModel.cancellable = nil

                                        Task {
                                            guard
                                                let playlistWebSocket = viewModel.playlistWebSocket
                                            else {
                                                return
                                            }

                                            for playerContent in addPlaylistViewModel.selectedPlayerContent {
                                                guard
                                                    case .track(let trackID, _, _, _, _, _, _, _, _) = playerContent
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

                                            try await playlistsWebSocket.send(
                                                PlaylistsMessage(
                                                    event: .changePlaylist,
                                                    payload: .changePlaylist(
                                                        playlist_id: playlistID,
                                                        playlist_name: playlistName,
                                                        playlist_access_type: accessType
                                                    )
                                                )
                                            )

                                            do {
                                                try await viewModel.updatePlaylists()
                                                try await viewModel.updateOwnPlaylists()
                                            }

                                            await MainActor.run {
                                                addPlaylistViewModel.isLoading = false

                                                addPlaylistViewModel.isShowing = false

                                                addPlaylistViewModel.reset()
                                            }

                                            await MainActor.run {
                                                viewModel.toastType = .systemImage("plus", Color.pink)
                                                viewModel.toastTitle = "Playlist Added"
                                                viewModel.toastSubtitle = playlistName
                                                viewModel.isToastShowing = true
                                            }
                                        }
                                    }
                                }

                                try await playlistsWebSocket.send(
                                    PlaylistsMessage(
                                        event: .addPlaylist,
                                        payload: .addPlaylist(
                                            playlist_name: playlistUUID.description,
                                            access_type: accessType
                                        )
                                    )
                                )
                            } catch {
                                await MainActor.run {
                                    addPlaylistViewModel.isLoading = false
                                }

                                await MainActor.run {
                                    viewModel.toastType = .error(Color.red)
                                    viewModel.toastTitle = "Oops..."
                                    viewModel.toastSubtitle = error.localizedDescription
                                    viewModel.isToastShowing = true
                                }
                            }
                        }
                    } label: {
                        if !addPlaylistViewModel.isLoading {
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
        .interactiveDismissDisabled(
            {
                guard
                    addPlaylistViewModel.nameText.isEmpty,
                    addPlaylistViewModel.selectedPlayerContent.isEmpty
                else {
                    return true
                }

                return false
            }(),
            onAttemptToDismiss: {
                addPlaylistViewModel.showingCancelConfirmation = true
            }
        )
        .onDisappear {
            addPlaylistViewModel.reset()
        }
        .confirmationDialog(
            "Don't Save New Playlist?",
            isPresented: $addPlaylistViewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {

            // MARK: - Add Playlist Dismiss Confirmation Dialog

            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        addPlaylistViewModel.showingCancelConfirmation = false

                        addPlaylistViewModel.isShowing = false

                        addPlaylistViewModel.reset()
                    }
                }
            } label: {
                Text("Yes")
            }

        }
        .sheet(isPresented: $addPlaylistViewModel.isShowingAddMusic, content: {
            AddPlaylistMusicView(
                api: api
            )
            .environmentObject(viewModel)
            .environmentObject(addPlaylistViewModel)
        })
    }
}
