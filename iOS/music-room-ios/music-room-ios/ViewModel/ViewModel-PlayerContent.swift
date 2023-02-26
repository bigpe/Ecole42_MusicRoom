import Foundation
import SwiftUI

extension ViewModel {
    enum PlayerContent: Identifiable {
        case track(
            id: Int,
            title: String,
            artist: String,
            flacFile: File?,
            mp3File: File?,
            progress: Decimal?,
            playerSessionID: Int?,
            sessionTrackID: Int?,
            sessionTrackState: SessionTrack.State?
        )
        
        var id: Int? {
            guard
                case .track(let id, _, _, _, _, _, _, _, _) = self
            else {
                return nil
            }
            
            return id
        }
        
        var title: String? {
            guard
                case .track(_, let title, _, _, _, _, _, _, _) = self
            else {
                return nil
            }
            
            return title
        }
        
        var artist: String? {
            guard
                case .track(_, _, let artist, _, _, _, _, _, _) = self
            else {
                return nil
            }
            
            return artist
        }
        
        var flacFile: File? {
            guard
                case .track(_, _, _, let flacFile, _, _, _, _, _) = self
            else {
                return nil
            }
            
            return flacFile
        }
        
        var mp3File: File? {
            guard
                case .track(_, _, _, _, let mp3File, _, _, _, _) = self
            else {
                return nil
            }
            
            return mp3File
        }
        
        var progress: Decimal? {
            guard
                case .track(_, _, _, _, _, let progress, _, _, _) = self
            else {
                return nil
            }
            
            return progress
        }
        
        var playerSessionID: Int? {
            guard
                case .track(_, _, _, _, _, _, let playerSessionID, _, _) = self
            else {
                return nil
            }
            
            return playerSessionID
        }
        
        var sessionTrackID: Int? {
            guard
                case .track(_, _, _, _, _, _, _, let sessionTrackID, _) = self
            else {
                return nil
            }
            
            return sessionTrackID
        }
        
        var sessionTrackState: SessionTrack.State? {
            guard
                case .track(_, _, _, _, _, _, _, _, let sessionTrackState) = self
            else {
                return nil
            }
            
            return sessionTrackState
        }
        
        var name: String? {
            guard
                case .track(_, let title, let artist, _, _, _, _, _, _) = self
            else {
                return nil
            }
            
            return [
                artist,
                title
            ]
                .compactMap { $0 }
                .joined(separator: " — ")
        }
    }
}
