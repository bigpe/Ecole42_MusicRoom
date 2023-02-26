import SwiftUI

struct AddEventView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var addEventViewModel: AddEventViewModel
    
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    Picker(selection: $addEventViewModel.accessType) {
                        ForEach(EventCreate.AccessType.allCases) { accessType in
                            Text(accessType.description)
                        }
                    } label: {
                        Text("Access")
                    }
                    .pickerStyle(.segmented)

                    TextField(text: $addEventViewModel.nameText) {
                        Text("Event Name")
                    }
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.sentences)
                    .focused(focusedField, equals: .addEventName)
                }
                
                GroupBox {
                    Button {
                        addEventViewModel.isShowingPlaylistSelect = true
                    } label: {
                        if let playlist = addEventViewModel.selectedPlaylist {
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
                            }
                        } else {
                            HStack(alignment: .center, spacing: 16) {
                                Image(uiImage: viewModel.placeholderCoverImage)
                                    .resizable()
                                    .cornerRadius(4)
                                    .frame(width: 60, height: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose a Playlist")
                                        .foregroundColor(viewModel.primaryControlsColor)
                                        .font(.system(size: 18, weight: .medium))
                                }
                                
                                Spacer()
                            }
                        }
                    }
                } label: {
                    Label("Event Playlist", systemImage: "music.note.list")
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker(
                            "Starts at",
                            selection: $addEventViewModel.startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        DatePicker(
                            "Ends at",
                            selection: $addEventViewModel.endDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                } label: {
                    Label("Event Time", systemImage: "calendar.badge.clock")
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .navigationBarTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        guard
                            addEventViewModel.nameText.isEmpty
                        else {
                            addEventViewModel.showingCancelConfirmation = true

                            return
                        }

                        addEventViewModel.isShowing = false

                        addEventViewModel.reset()
                    } label: {
                        Text("Cancel")
                    }

                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        guard
                            let selectedPlaylistID = addEventViewModel.selectedPlaylist?.id
                        else {
                            return
                        }
                        
                        let eventName = addEventViewModel.nameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        let accessType = addEventViewModel.accessType
                        
                        let startDate = addEventViewModel.startDate
                        let endDate = addEventViewModel.endDate

                        guard
                            !eventName.isEmpty,
                            endDate > startDate,
                            !addEventViewModel.isLoading
                        else {
                            return
                        }
                        
                        Task {
                            do {
                                await MainActor.run {
                                    addEventViewModel.isLoading = true
                                }
                                
                                let eventCreate = try await api.eventAddRequest(
                                    eventCreate: EventCreate(
                                        playlist: selectedPlaylistID,
                                        name: eventName,
                                        accessType: accessType,
                                        startDate: startDate,
                                        endDate: endDate
                                    )
                                )

                                do {
                                    try await viewModel.updateEvents()
                                }

                                await MainActor.run {
                                    addEventViewModel.isLoading = false

                                    addEventViewModel.isShowing = false

                                    addEventViewModel.reset()
                                }

                                await MainActor.run {
                                    viewModel.toastType = .systemImage("plus", Color.pink)
                                    viewModel.toastTitle = "Event Added"
                                    viewModel.toastSubtitle = eventCreate.name
                                    viewModel.isToastShowing = true
                                }
                            } catch {
                                await MainActor.run {
                                    addEventViewModel.isLoading = false
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
                        if !addEventViewModel.isLoading {
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
                    addEventViewModel.nameText.isEmpty
                else {
                    return true
                }

                return false
            }(),
            onAttemptToDismiss: {
                addEventViewModel.showingCancelConfirmation = true
            }
        )
        .onDisappear {
            addEventViewModel.reset()
        }
        .sheet(isPresented: $addEventViewModel.isShowingPlaylistSelect, content: {
            AddEventPlaylistView(
                api: api
            )
            .environmentObject(viewModel)
            .environmentObject(addEventViewModel)
        })
        .confirmationDialog(
            "Don't Save New Event?",
            isPresented: $addEventViewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {

            // MARK: - Add Event Dismiss Confirmation Dialog

            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        addEventViewModel.showingCancelConfirmation = false

                        addEventViewModel.isShowing = false

                        addEventViewModel.reset()
                    }
                }
            } label: {
                Text("Yes")
            }

        }
    }
}
