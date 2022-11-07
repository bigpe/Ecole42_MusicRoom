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
                        ForEach(Playlist.AccessType.allCases) { accessType in
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
                        let eventName = addEventViewModel.nameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        let accessType = addEventViewModel.accessType

                        guard
                            !eventName.isEmpty,
                            !addEventViewModel.isLoading
                        else {
                            return
                        }

                        let eventUUID = UUID()
                        
                        Task {
                            do {
                                await MainActor.run {
                                    addEventViewModel.isLoading = true
                                }
                                
                                let eventCreate = try await api.eventAddRequest(
                                    eventCreate: EventCreate(
                                        playlist: 0,
                                        name: eventName,
                                        accessType: accessType,
                                        startDate: Date(),
                                        endDate: Date()
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
        .confirmationDialog(
            "Don't Save New Playlist?",
            isPresented: $addEventViewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {

            // MARK: - Add Playlist Dismiss Confirmation Dialog

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
