import SwiftUI
import Combine

@MainActor
class AddEventViewModel: ObservableObject {
    
    // MARK: - States
    
    @Published
    var isShowing = false
    
    @Published
    var isLoading = false
    
    @Published
    var showingCancelConfirmation = false
    
    // MARK: - Data
    
    @Published
    var nameText = ""
    
    @Published
    var accessType = EventCreate.AccessType.private
    
    @Published
    var selectedPlaylist: Playlist?
    
    func reset() {
        nameText = ""
        accessType = .private
        isLoading = false
        selectedPlaylist = nil
    }
}
