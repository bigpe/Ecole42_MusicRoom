import SwiftUI

struct PlaylistView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var playlistViewModel: PlaylistViewModel
    
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    if !playlistViewModel.isEditing {
                        Text(playlistViewModel.selectedPlaylist?.name ?? "")
                            .font(.title)
                    } else {
                        Picker(selection: $playlistViewModel.accessType) {
                            ForEach(Playlist.AccessType.allCases) { accessType in
                                Text(accessType.description)
                            }
                        } label: {
                            Text("Access")
                        }
                        .pickerStyle(.segmented)

                        TextField(text: $playlistViewModel.nameText) {
                            Text("Playlist Name")
                        }
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                        .focused(focusedField, equals: .playlistName)
                    }
                }

                Divider()

                HStack {
                    Button {
                        Task {
                            guard
                                let playlistID = playlistViewModel.selectedPlaylist?.id
                            else {
                                return
                            }

                            do {
                                try await viewModel.createSession(
                                    playlistID: playlistID,
                                    shuffle: false
                                )
                            } catch {
                                await MainActor.run {
                                    viewModel.toastType = .error(Color.red)
                                    viewModel.toastTitle = "Oops..."
                                    viewModel.toastSubtitle = error.localizedDescription
                                    viewModel.isToastShowing = true
                                }
                            }

                            api.playlistWebSockets.removeValue(forKey: playlistID)

                            let playlistName = playlistViewModel.selectedPlaylist?.name

                            playlistViewModel.selectedPlaylist = nil

                            viewModel.interfaceState = .player

                            await MainActor.run {
                                viewModel.toastType = .systemImage("play.circle", Color.pink)
                                viewModel.toastTitle = playlistName
                                viewModel.toastSubtitle = "Now Playing"
                                viewModel.isToastShowing = true
                            }
                        }
                    } label: {
                        Label("Play Now", systemImage: "play.circle.fill")
                    }
                    .tint(.pink)

                    Spacer()

                    Button {
                        Task {
                            guard
                                let playlistID = playlistViewModel.selectedPlaylist?.id
                            else {
                                return
                            }

                            do {
                                try await viewModel.createSession(
                                    playlistID: playlistID,
                                    shuffle: true
                                )
                            } catch {

                                await MainActor.run {
                                    viewModel.toastType = .error(Color.red)
                                    viewModel.toastTitle = "Oops..."
                                    viewModel.toastSubtitle = error.localizedDescription
                                    viewModel.isToastShowing = true
                                }
                            }

                            api.playlistWebSockets.removeValue(forKey: playlistID)

                            let playlistName = playlistViewModel.selectedPlaylist?.name

                            playlistViewModel.selectedPlaylist = nil

                            viewModel.interfaceState = .player

                            await MainActor.run {
                                viewModel.toastType = .systemImage("shuffle.circle", Color.pink)
                                viewModel.toastTitle = playlistName
                                viewModel.toastSubtitle = "Shuffle"
                                viewModel.isToastShowing = true
                            }
                        }
                    } label: {
                        Label("Shuffle", systemImage: "shuffle.circle.fill")
                    }
                    .tint(.pink)
                }

                List(
                    playlistViewModel.playerContent
                ) { track in
                    HStack(alignment: .center, spacing: 16) {
//                        cachedArtworkImage(track.name)
                        Image(systemName: "Scribble")
                            .resizable()
                            .cornerRadius(4)
                            .frame(width: 60, height: 60)
                            .padding(.leading, -16)

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
                        if playlistViewModel.isEditable {
                            Button(role: .destructive) {
                                guard
                                    let trackID = track.id,
                                    let playlistID = playlistViewModel.selectedPlaylist?.id,
                                    let playlistWebSocket = api.playlistWebSocket(
                                        playlistID: playlistID
                                    )
                                else {
                                    return
                                }

                                Task {
                                    try await playlistWebSocket.send(
                                        PlaylistMessage(
                                            event: .removeTrack,
                                            payload: .removeTrack(track_id: trackID)
                                        )
                                    )

                                    playlistViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                        guard
                                            let playlist = $0.first(where: {
                                                $0.id == playlistID
                                            })
                                        else {
                                            return
                                        }

                                        playlistViewModel.cancellable = nil

                                        playlistViewModel.selectedPlaylist = playlist
                                    }
                                }
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                }
                .listStyle(.plain)

                if playlistViewModel.isEditable {
                    HStack {
                        Button {
                            playlistViewModel.showingDeleteConfirmation = true
                        } label: {
                            if !playlistViewModel.isDeleteLoading {
                                Label("Delete Playlist", systemImage: "trash.circle.fill")
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                        .tint(.pink)

                        Spacer()

                        Button {
                            playlistViewModel.isShowingAddMusic = true
                        } label: {
                            Label("Add Music", systemImage: "plus.circle.fill")
                        }
                        .tint(.pink)
                    }
                    .padding(.bottom, 12)
                }

            }
            .padding(.horizontal, 16)
            .navigationBarTitle("Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        let playlistName = playlistViewModel.nameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        let accessType = playlistViewModel.accessType

                        guard
                            playlistName == playlistViewModel.selectedPlaylist?.name,
                            accessType == playlistViewModel.selectedPlaylist?.accessType
                        else {
                            playlistViewModel.showingCancelConfirmation = true

                            return
                        }

                        playlistViewModel.selectedPlaylist = nil
                    } label: {
                        Text("Cancel")
                    }

                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if playlistViewModel.isEditable {
                        Button {
                            if !playlistViewModel.isEditing {
                                playlistViewModel.isEditing = true
                            } else {
                                let playlistName = playlistViewModel.nameText
                                    .trimmingCharacters(in: .whitespacesAndNewlines)

                                let accessType = playlistViewModel.accessType

                                guard
                                    playlistName != playlistViewModel.selectedPlaylist?.name ||
                                        accessType != playlistViewModel.selectedPlaylist?.accessType
                                else {
                                    playlistViewModel.isEditing = false

                                    return
                                }

                                guard
                                    !playlistName.isEmpty,
//                                    !addPlaylistViewModel.isLoading, // TODO: Check
                                    let playlistID = playlistViewModel.selectedPlaylist?.id,
                                    let playlistsWebSocket = api.playlistsWebSocket
                                else {
                                    return
                                }

                                playlistViewModel.isLoading = true

                                Task {
                                    do {
                                        playlistViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                            guard
                                                let playlist = $0.first(where: {
                                                    $0.id == playlistID
                                                })
                                            else {
                                                return
                                            }

                                            playlistViewModel.cancellable = nil

                                            playlistViewModel.selectedPlaylist = playlist
                                        }

                                        do {
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

                                            await MainActor.run {
                                                playlistViewModel.isShowing = false

                                                viewModel.toastType = .complete(Color.pink)
                                                viewModel.toastTitle = "Playlist Saved"
                                                viewModel.toastSubtitle = playlistName
                                                viewModel.isToastShowing = true
                                            }
                                        } catch {

                                            await MainActor.run {
                                                viewModel.toastType = .error(Color.red)
                                                viewModel.toastTitle = "Oops..."
                                                viewModel.toastSubtitle = error.localizedDescription
                                                viewModel.isToastShowing = true
                                            }
                                        }

//                                            do {
//                                                try await viewModel.updatePlaylists()
//                                                try await viewModel.updateOwnPlaylists()
//                                            }

                                        await MainActor.run {
                                            playlistViewModel.isEditing = false
                                            playlistViewModel.isLoading = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            playlistViewModel.isEditing = false
                                            playlistViewModel.isLoading = false
                                        }
                                    }
                                }
                            }
                        } label: {
                            if !playlistViewModel.isLoading {
                                if !playlistViewModel.isEditing {
                                    Text("Edit")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Done")
                                        .fontWeight(.semibold)
                                }
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Playlist?",
                isPresented: $playlistViewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {

                // MARK: - Delete Playlist Confirmation Dialog

                Button(role: .destructive) {
                    Task {
                        guard
                            let playlistID = playlistViewModel.selectedPlaylist?.id,
                            let playlistWebSocket = api.playlistsWebSocket
                        else {
                            return
                        }

                        await MainActor.run {
                            playlistViewModel.isDeleteLoading = true
                        }

                        do {
                            try await playlistWebSocket.send(
                                PlaylistsMessage(
                                    event: .removePlaylist,
                                    payload: .removePlaylist(
                                        playlist_id: playlistID,
                                        playlist_name: nil,
                                        playlist_access_type: nil
                                    )
                                )
                            )

                            await MainActor.run {
                                playlistViewModel.isDeleteLoading = false

                                viewModel.toastType = .systemImage("trash.circle", Color.pink)
                                viewModel.toastTitle = "Playlist Deleted"
                                viewModel.toastSubtitle = playlistViewModel.selectedPlaylist?.name
                                viewModel.isToastShowing = true
                            }
                        } catch {
                            await MainActor.run {
                                playlistViewModel.isDeleteLoading = false

                                viewModel.toastType = .error(Color.red)
                                viewModel.toastTitle = "Oops..."
                                viewModel.toastSubtitle = error.localizedDescription
                                viewModel.isToastShowing = true
                            }
                        }

                        playlistViewModel.showingDeleteConfirmation = false

                        playlistViewModel.selectedPlaylist = nil
                    }
                } label: {
                    Text("Yes")
                }

            }
        }
        .accentColor(.pink)
        .interactiveDismissDisabled(
            {
                let playlistName = playlistViewModel.nameText
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let accessType = playlistViewModel.accessType

                guard
                    playlistName == playlistViewModel.selectedPlaylist?.name,
                    accessType == playlistViewModel.selectedPlaylist?.accessType
                else {
                    return true
                }

                return false
            }(),
            onAttemptToDismiss: {
                playlistViewModel.showingCancelConfirmation = true
            }
        )
        .confirmationDialog(
            "Don't Save Playlist Edits?",
            isPresented: $playlistViewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {

            // MARK: - Playlist Dismiss Confirmation Dialog

            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        playlistViewModel.showingCancelConfirmation = false

                        playlistViewModel.selectedPlaylist = nil
                    }
                }
            } label: {
                Text("Yes")
            }

        }
        .onDisappear {
            playlistViewModel.selectedPlaylist = nil
        }
        .sheet(isPresented: $playlistViewModel.isShowingAddMusic, content: {

            // MARK: - Playlist Add Music Sheet

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
        })
    }
}
