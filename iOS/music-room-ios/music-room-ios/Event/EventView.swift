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
                            ForEach(Event.AccessType.allCases) { accessType in
                                Text(accessType.description)
                            }
                        } label: {
                            Text("Access")
                        }
                        .pickerStyle(.segmented)

                        TextField(text: $eventViewModel.nameText) {
                            Text("Event Name")
                        }
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                        .focused(focusedField, equals: .playlistName)
                    }
                }

                Divider()
                
//                GroupBox {
//                    Button {
////                        addEventViewModel.isShowingPlaylistSelect = true
//                    } label: {
//                        if let playlist = eventViewModel.selectedPlaylist {
//                            HStack(alignment: .center, spacing: 16) {
//                                Image(uiImage: playlist.cover)
//                                    .resizable()
//                                    .cornerRadius(4)
//                                    .frame(width: 60, height: 60)
//
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text(playlist.name)
//                                        .foregroundColor(viewModel.primaryControlsColor)
//                                        .font(.system(size: 18, weight: .medium))
//
//                                    if let user = viewModel.user(byID: playlist.author) {
//                                        Text("@\(user.username)")
//                                            .foregroundColor(viewModel.secondaryControlsColor)
//                                            .font(.system(size: 16, weight: .regular))
//                                    } else if viewModel.ownPlaylists
//                                        .contains(where: { $0.id == playlist.id }) {
//                                        Text("Yours")
//                                            .foregroundColor(viewModel.secondaryControlsColor)
//                                            .font(.system(size: 16, weight: .regular))
//                                    }
//                                }
//
//                                Spacer()
//                            }
//                        } else {
//                            HStack(alignment: .center, spacing: 16) {
//                                Image(uiImage: viewModel.placeholderCoverImage)
//                                    .resizable()
//                                    .cornerRadius(4)
//                                    .frame(width: 60, height: 60)
//
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("Choose a Playlist")
//                                        .foregroundColor(viewModel.primaryControlsColor)
//                                        .font(.system(size: 18, weight: .medium))
//                                }
//
//                                Spacer()
//                            }
//                        }
//                    }
//                } label: {
//                    Label("Event Playlist", systemImage: "music.note.list")
//                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        if !eventViewModel.isEditing {
                            LabeledContent(
                                "Starts at",
                                value: eventViewModel.selectedEvent?.startDate
                                    .formatted(date: .numeric, time: .shortened) ?? ""
                            )
                            
                            LabeledContent(
                                "Ends at",
                                value: eventViewModel.selectedEvent?.endDate
                                    .formatted(date: .numeric, time: .shortened) ?? ""
                            )
                        } else {
//                            DatePicker(
//                                "Starts at",
//                                selection: $eventViewModel.startDate,
//                                displayedComponents: [.date, .hourAndMinute]
//                            )
//
//                            DatePicker(
//                                "Ends at",
//                                selection: $eventViewModel.endDate,
//                                displayedComponents: [.date, .hourAndMinute]
//                            )
                        }
                    }
                } label: {
                    Label("Event Time", systemImage: "calendar.badge.clock")
                }
                
                Spacer()
                
                Button {
                    guard
                        let eventID = eventViewModel.selectedEvent?.id
                    else {
                        return
                    }
                    
                    viewModel.subscribeToEvent(eventID: eventID)
                    
                    viewModel.interfaceState = .player
                    
                    eventViewModel.isShowing = false
                } label: {
                    Label("Connect", systemImage: "party.popper.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.pink)
                .buttonStyle(.bordered)
                .disabled(!eventViewModel.isInProgress)
            }
            .padding(.horizontal, 16)
            .navigationBarTitle("Event")
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
                                let eventName = eventViewModel.nameText
                                    .trimmingCharacters(in: .whitespacesAndNewlines)

                                let accessType = eventViewModel.accessType

                                guard
                                    eventName != eventViewModel.selectedEvent?.name ||
                                        accessType != eventViewModel.selectedEvent?.accessType
                                else {
                                    eventViewModel.isEditing = false

                                    return
                                }

                                guard
                                    !eventName.isEmpty,
//                                    !addPlaylistViewModel.isLoading, // TODO: Check
                                    let eventID = eventViewModel.selectedEvent?.id,
                                    let eventWebSocket = api.eventWebSocket(eventID: eventID)
                                else {
                                    return
                                }

                                eventViewModel.isLoading = true

//                                Task {
//                                    do {
//                                        playlistViewModel.cancellable = viewModel.$ownPlaylists.sink {
//                                            guard
//                                                let playlist = $0.first(where: {
//                                                    $0.id == playlistID
//                                                })
//                                            else {
//                                                return
//                                            }
//
//                                            playlistViewModel.cancellable = nil
//
//                                            playlistViewModel.selectedPlaylist = playlist
//                                        }
//
//                                        do {
//                                            try await playlistsWebSocket.send(
//                                                PlaylistsMessage(
//                                                    event: .changePlaylist,
//                                                    payload: .changePlaylist(
//                                                        playlist_id: playlistID,
//                                                        playlist_name: playlistName,
//                                                        playlist_access_type: accessType
//                                                    )
//                                                )
//                                            )
//
//                                            await MainActor.run {
//                                                playlistViewModel.isShowing = false
//
//                                                viewModel.toastType = .complete(Color.pink)
//                                                viewModel.toastTitle = "Playlist Saved"
//                                                viewModel.toastSubtitle = playlistName
//                                                viewModel.isToastShowing = true
//                                            }
//                                        } catch {
//
//                                            await MainActor.run {
//                                                viewModel.toastType = .error(Color.red)
//                                                viewModel.toastTitle = "Oops..."
//                                                viewModel.toastSubtitle = error.localizedDescription
//                                                viewModel.isToastShowing = true
//                                            }
//                                        }
//
////                                            do {
////                                                try await viewModel.updatePlaylists()
////                                                try await viewModel.updateOwnPlaylists()
////                                            }
//
//                                        await MainActor.run {
//                                            playlistViewModel.isEditing = false
//                                            playlistViewModel.isLoading = false
//                                        }
//                                    } catch {
//                                        await MainActor.run {
//                                            playlistViewModel.isEditing = false
//                                            playlistViewModel.isLoading = false
//                                        }
//                                    }
//                                }
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

            // MARK: - Event Dismiss Confirmation Dialog

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
