import SwiftUI

struct EventView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var eventViewModel: EventViewModel
    
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    if !eventViewModel.isEditing {
                        Text(eventViewModel.selectedEvent?.name ?? "")
                            .font(.title)
                    } else {
                        Picker(selection: $eventViewModel.accessType) {
                            ForEach(Playlist.AccessType.allCases) { accessType in
                                Text(accessType.description)
                            }
                        } label: {
                            Text("Access")
                        }
                        .pickerStyle(.segmented)

                        TextField(text: $eventViewModel.nameText) {
                            Text("Playlist Name")
                        }
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                        .focused(focusedField, equals: .eventName)
                    }
                }

                Divider()

                HStack {
                    Button {
                        Task {
                            guard
                                let eventID = eventViewModel.selectedEvent?.id
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

                            let playlistName = eventViewModel.selectedEvent?.name

                            eventViewModel.selectedEvent = nil

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
                                let playlistID = eventViewModel.selectedEvent?.id
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

                            let playlistName = eventViewModel.selectedEvent?.name

                            eventViewModel.selectedEvent = nil

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
                    eventViewModel.playerContent
                ) { track in
                    LazyHStack(alignment: .center, spacing: 16) {
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
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 60 }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if eventViewModel.isEditable {
                            Button(role: .destructive) {
                                guard
                                    let trackID = track.id,
                                    let playlistID = eventViewModel.selectedEvent?.id,
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

                                    eventViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                        guard
                                            let playlist = $0.first(where: {
                                                $0.id == playlistID
                                            })
                                        else {
                                            return
                                        }

                                        eventViewModel.cancellable = nil

                                        eventViewModel.selectedEvent = playlist
                                    }
                                }
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                }
                .listStyle(.plain)

                if eventViewModel.isEditable {
                    HStack {
                        Button {
                            eventViewModel.showingDeleteConfirmation = true
                        } label: {
                            if !eventViewModel.isDeleteLoading {
                                Label("Delete Playlist", systemImage: "trash.circle.fill")
                            } else {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                        .tint(.pink)

                        Spacer()

                        Button {
                            eventViewModel.isShowingAddMusic = true
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
                        let playlistName = eventViewModel.nameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        let accessType = eventViewModel.accessType

                        guard
                            playlistName == eventViewModel.selectedEvent?.name,
                            accessType == eventViewModel.selectedEvent?.accessType
                        else {
                            eventViewModel.showingCancelConfirmation = true

                            return
                        }

                        eventViewModel.selectedEvent = nil
                    } label: {
                        Text("Cancel")
                    }

                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if eventViewModel.isEditable {
                        Button {
                            if !eventViewModel.isEditing {
                                eventViewModel.isEditing = true
                            } else {
                                let playlistName = eventViewModel.nameText
                                    .trimmingCharacters(in: .whitespacesAndNewlines)

                                let accessType = eventViewModel.accessType

                                guard
                                    playlistName != eventViewModel.selectedEvent?.name ||
                                        accessType != eventViewModel.selectedEvent?.accessType
                                else {
                                    eventViewModel.isEditing = false

                                    return
                                }

                                guard
                                    !playlistName.isEmpty,
//                                    !addPlaylistViewModel.isLoading, // TODO: Check
                                    let playlistID = eventViewModel.selectedEvent?.id,
                                    let playlistsWebSocket = api.playlistsWebSocket
                                else {
                                    return
                                }

                                eventViewModel.isLoading = true

                                Task {
                                    do {
                                        eventViewModel.cancellable = viewModel.$ownPlaylists.sink {
                                            guard
                                                let playlist = $0.first(where: {
                                                    $0.id == playlistID
                                                })
                                            else {
                                                return
                                            }

                                            eventViewModel.cancellable = nil

                                            eventViewModel.selectedEvent = playlist
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
                                                eventViewModel.isShowing = false

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
                                            eventViewModel.isEditing = false
                                            eventViewModel.isLoading = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            eventViewModel.isEditing = false
                                            eventViewModel.isLoading = false
                                        }
                                    }
                                }
                            }
                        } label: {
                            if !eventViewModel.isLoading {
                                if !eventViewModel.isEditing {
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
                isPresented: $eventViewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {

                // MARK: - Delete Playlist Confirmation Dialog

                Button(role: .destructive) {
                    Task {
                        guard
                            let playlistID = eventViewModel.selectedEvent?.id,
                            let playlistWebSocket = api.playlistsWebSocket
                        else {
                            return
                        }

                        await MainActor.run {
                            eventViewModel.isDeleteLoading = true
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
                                eventViewModel.isDeleteLoading = false

                                viewModel.toastType = .systemImage("trash.circle", Color.pink)
                                viewModel.toastTitle = "Playlist Deleted"
                                viewModel.toastSubtitle = eventViewModel.selectedEvent?.name
                                viewModel.isToastShowing = true
                            }
                        } catch {
                            await MainActor.run {
                                eventViewModel.isDeleteLoading = false

                                viewModel.toastType = .error(Color.red)
                                viewModel.toastTitle = "Oops..."
                                viewModel.toastSubtitle = error.localizedDescription
                                viewModel.isToastShowing = true
                            }
                        }

                        eventViewModel.showingDeleteConfirmation = false

                        eventViewModel.selectedEvent = nil
                    }
                } label: {
                    Text("Yes")
                }

            }
        }
        .accentColor(.pink)
        .interactiveDismissDisabled(
            {
                let playlistName = eventViewModel.nameText
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let accessType = eventViewModel.accessType

                guard
                    playlistName == eventViewModel.selectedEvent?.name,
                    accessType == eventViewModel.selectedEvent?.accessType
                else {
                    return true
                }

                return false
            }(),
            onAttemptToDismiss: {
                eventViewModel.showingCancelConfirmation = true
            }
        )
        .confirmationDialog(
            "Don't Save Event Edits?",
            isPresented: $eventViewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {

            // MARK: - Playlist Dismiss Confirmation Dialog

            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        eventViewModel.showingCancelConfirmation = false

                        eventViewModel.selectedEvent = nil
                    }
                }
            } label: {
                Text("Yes")
            }

        }
        .onDisappear {
            eventViewModel.selectedEvent = nil
        }
    }
}
