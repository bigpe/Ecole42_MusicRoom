import SwiftUI

struct LibraryView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var addPlaylistViewModel: AddPlaylistViewModel
    
    @EnvironmentObject
    var playlistViewModel: PlaylistViewModel
    
    @EnvironmentObject
    var addEventViewModel: AddEventViewModel
    
    @EnvironmentObject
    var eventViewModel: EventViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Menu {
                    Button {
                        withAnimation {
                            viewModel.libraryState = .ownPlaylists
                        }
                    } label: {
                        Label("My Playlists", systemImage: "text.badge.star")
                    }

                    
                    Button {
                        withAnimation {
                            viewModel.libraryState = .playlists
                        }
                    } label: {
                        Label("Playlists", systemImage: "music.note.list")
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.libraryState = .events
                        }
                    } label: {
                        Label("Events", systemImage: "party.popper.fill")
                    }
                } label: {
                    ZStack(alignment: .leading) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("My Playlists")
                                .font(.system(
                                    size: 32,
                                    weight: .bold
                                ))
                                .foregroundColor(viewModel.primaryControlsColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(
                                    size: 16,
                                    weight: .medium
                                ))
                                .padding(.top, 4)
                                .foregroundColor(viewModel.primaryControlsColor)
                        }
                        .opacity(viewModel.libraryState == .ownPlaylists ? 1 : 0)
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text("Playlists")
                                .font(.system(
                                    size: 32,
                                    weight: .bold
                                ))
                                .foregroundColor(viewModel.primaryControlsColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(
                                    size: 16,
                                    weight: .medium
                                ))
                                .padding(.top, 4)
                                .foregroundColor(viewModel.primaryControlsColor)
                        }
                        .opacity(viewModel.libraryState == .playlists ? 1 : 0)
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text("Events")
                                .font(.system(
                                    size: 32,
                                    weight: .bold
                                ))
                                .foregroundColor(viewModel.primaryControlsColor)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(
                                    size: 16,
                                    weight: .medium
                                ))
                                .padding(.top, 4)
                                .foregroundColor(viewModel.primaryControlsColor)
                        }
                        .opacity(viewModel.libraryState == .events ? 1 : 0)
                    }
                }
                
                Spacer()
                
                switch viewModel.libraryState {
                case .ownPlaylists, .playlists:
                    Button {
                        addPlaylistViewModel.isShowing = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.pink)
                    }
                    .transition(.opacity)
                    
                case .events:
                    Button {
                        addEventViewModel.isShowing = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.pink)
                    }
                    .transition(.opacity)
                }
            }
            
            ScrollView(showsIndicators: false) {
                switch viewModel.libraryState {
                case .ownPlaylists:
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(viewModel.ownPlaylists) { playlist in
                            Button {
                                guard
                                    let playlistID = playlist.id
                                else {
                                    return
                                }
                                
                                playlistViewModel.selectedPlaylist = playlist
                                
                                viewModel.subscribeToPlaylist(playlistID: playlistID)
                            } label: {
                                LazyHStack(alignment: .center, spacing: 16) {
                                    Image(uiImage: playlist.cover)
                                        .resizable()
                                        .cornerRadius(4)
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(playlist.name)
                                            .foregroundColor(viewModel.primaryControlsColor)
                                            .font(.system(size: 18, weight: .medium))
                                        
                                        Text(playlist.accessType.description)
                                            .foregroundColor(viewModel.secondaryControlsColor)
                                            .font(.system(size: 16, weight: .regular))
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    
                case .playlists:
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(viewModel.playlists) { playlist in
                            Button {
                                guard
                                    let playlistID = playlist.id
                                else {
                                    return
                                }
                                
                                playlistViewModel.selectedPlaylist = playlist
                                
                                viewModel.subscribeToPlaylist(playlistID: playlistID)
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
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    
                case .events:
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(viewModel.events) { event in
                            Button {
                                guard
                                    let eventID = event.id
                                else {
                                    return
                                }
                                
                                eventViewModel.selectedEvent = event
                            } label: {
                                HStack(alignment: .center, spacing: 16) {
                                    Image(uiImage: event.cover)
                                        .resizable()
                                        .cornerRadius(4)
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.name)
                                            .foregroundColor(viewModel.primaryControlsColor)
                                            .font(.system(size: 18, weight: .medium))
                                        
                                        if let user = viewModel.user(byID: event.author) {
                                            Text("@\(user.username)")
                                                .foregroundColor(viewModel.secondaryControlsColor)
                                                .font(.system(size: 16, weight: .regular))
                                        } else if viewModel.ownPlaylists
                                            .contains(where: { $0.id == event.id }) {
                                            Text("Yours")
                                                .foregroundColor(viewModel.secondaryControlsColor)
                                                .font(.system(size: 16, weight: .regular))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                }
            }
        }
    }
}
