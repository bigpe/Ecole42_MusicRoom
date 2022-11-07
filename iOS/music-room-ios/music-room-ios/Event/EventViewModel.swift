import SwiftUI
import Combine

@MainActor
class EventViewModel: ObservableObject {
    
    weak var viewModel: ViewModel!
    
    // MARK: - Data
    
    @Published
    var nameText = ""
    
    @Published
    var accessType = EventList.AccessType.private
    
    // MARK: - States
    
    @Published
    var isShowing = false
    
    @Published
    var isLoading = false
    
    @Published
    var isEditable = false
    
    @Published
    var isEditing = false
    
    @Published
    var showingCancelConfirmation = false
    
    // MARK: - Delete
    
    @Published
    var isDeleteLoading = false
    
    @Published
    var showingDeleteConfirmation = false
    
    // MARK: - Selected Event
    
    @Published
    var selectedEvent: EventList? {
        didSet {
            if let selectedEvent {
                if !isEditing {
                    nameText = selectedEvent.name
                    accessType = selectedEvent.accessType
                }
                
                isShowing = true
                
                if let userID = viewModel.playerSession?.author {
                    isEditable = selectedEvent.author == userID
                }
            } else {
                nameText = ""
                accessType = .private
                
                isShowing = false
                isLoading = false
                isEditable = false
                isEditing = false
                
                cancellable = nil
            }
        }
    }
    
    var cancellable: AnyCancellable?
}
