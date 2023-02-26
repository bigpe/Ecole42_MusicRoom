import SwiftUI
import Combine

@MainActor
class EventViewModel: ObservableObject {
    
    weak var viewModel: ViewModel!
    
    // MARK: - Data
    
    @Published
    var nameText = ""
    
    @Published
    var accessType = Event.AccessType.private
    
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
    
    @Published
    var isInProgress = false
    
    var startTimer: Timer?
    
    // MARK: - Delete
    
    @Published
    var isDeleteLoading = false
    
    @Published
    var showingDeleteConfirmation = false
    
    // MARK: - Selected Event
    
    @Published
    var selectedEvent: Event? {
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
                
                let nowDate = Date()
                
                if nowDate >= selectedEvent.startDate, nowDate < selectedEvent.endDate {
                    isInProgress = true
                } else if nowDate < selectedEvent.endDate {
                    startTimer?.invalidate()
                    
                    startTimer = Timer(timeInterval: 1, repeats: true, block: { t in
                        guard
                            Date() >= selectedEvent.startDate
                        else {
                            return
                        }
                        
                        t.invalidate()
                        
                        Task { @MainActor in
                            self.isInProgress = false
                        }
                    })
                }
                
            } else {
                viewModel.eventWebSocket?.close()
                viewModel.eventWebSocket = nil
                
                nameText = ""
                accessType = .private
                
                isShowing = false
                isLoading = false
                isEditable = false
                isEditing = false
                isInProgress = false
                
                startTimer?.invalidate()
                startTimer = nil
                
                cancellable = nil
            }
        }
    }
    
    var cancellable: AnyCancellable?
}
