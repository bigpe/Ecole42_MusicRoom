//
//  ContentView+ViewModel-Player.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 13.07.2022.
//

import Foundation
import SwiftUI
import MediaPlayer
import AVFoundation

extension ContentView.ViewModel {
    func playCurrentTrack() {
        guard
            let currentTrackFile = currentTrackFile,
            let currentTrackURL = URL(string: currentTrackFile.file)
        else {
            return
        }
        
        guard
            (player.currentItem?.asset as? AVURLAsset)?.url != currentTrackURL
        else {
            return player.play()
        }
        
        let playerItem = AVPlayerItem(url: currentTrackURL)
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: []
            )
            
            try audioSession.setActive(true)
        } catch {
            debugPrint(error.localizedDescription)
        }
        
        if let progress = currentSessionTrack?.progress { // FIXME: Remove `false`
            let progress = NSDecimalNumber(decimal: progress).doubleValue
            let timeScale = CMTimeScale(1)
            let time = CMTime(seconds: progress, preferredTimescale: timeScale)
            
            guard time < playerItem.duration else { return }
            
            player.replaceCurrentItem(with: playerItem)
            
            updateNowPlayingInfo()
            
            player.automaticallyWaitsToMinimizeStalling = false
            
            playerItemStatusObserver = player.currentItem?.observe(\.status) {
                [unowned self] (playerItem, _) in
                
                guard
                    playerItem.status == .readyToPlay
                else {
                    if let error = playerItem.error {
                        debugPrint(error)
                    }
                    
                    return
                }
                
                @MainActor
                func seek() {
                    guard
                        let currentSessionTrackProgress = currentSessionTrack?.progress
                    else {
                        return player.play()
                    }
                    
                    let progress = NSDecimalNumber(decimal: currentSessionTrackProgress).doubleValue
                    let timeScale = CMTimeScale(1)
                    let time = CMTime(seconds: progress, preferredTimescale: timeScale)
                    
                    player.seek(to: time) { [unowned self] (status) in
                        guard status else { return seek() }
                        
                        player.play()
                    }
                }
                
                seek()
            }
        } else {
            player.replaceCurrentItem(with: playerItem)
            
            player.play()
        }
        
        let progress = (self.currentSessionTrack?.progress as? NSDecimalNumber)
        
        if let playerProgressTimeObserver = playerProgressTimeObserver {
            player.removeTimeObserver(playerProgressTimeObserver)
        }
        
        if let playerSyncTimeObserver = playerSyncTimeObserver {
            player.removeTimeObserver(playerSyncTimeObserver)
        }
        
        playerProgressTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { cmTime in
            let value = cmTime.seconds
            let total = (self.currentTrackFile?.duration as? NSDecimalNumber)
            
            let bufferedRanges: [(start: Double, duration: Double)] = self.player.currentItem?.loadedTimeRanges.map { timeRange in
                let startSeconds = timeRange.timeRangeValue.start.seconds
                let durationSeconds = timeRange.timeRangeValue.duration.seconds
                
                return (start: startSeconds, duration: durationSeconds)
            } ?? []
            
            if !self.isProgressTracking {
                DispatchQueue.main.async { [unowned self] in
                    shouldAnimateProgressSlider.toggle()
                    
                    trackProgress = TrackProgress(value: value, total: total?.doubleValue)
                }
            }
            
            if (progress?.intValue ?? 0) >= (total?.intValue ?? 0) || Int(value) >= (total?.intValue ?? 0) {
                if let playerProgressTimeObserver = self.playerProgressTimeObserver {
                    self.player.removeTimeObserver(playerProgressTimeObserver)
                    
                    self.playerProgressTimeObserver = nil
                }
                
                if let playerSyncTimeObserver = self.playerSyncTimeObserver {
                    self.player.removeTimeObserver(playerSyncTimeObserver)
                    
                    self.playerSyncTimeObserver = nil
                }
                
                Task {
                    try await self.forward()
                }
            }
        }
        
        playerSyncTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .global(qos: .background)
        ) { cmTime in
            guard
                let sessionID = self.playerSession?.id
            else {
                return
            }
            
            let value = cmTime.seconds
            
            guard
                !self.isProgressTracking
            else {
                return
            }
            
            Task {
                try await self.api.playerWebSocket?.send(
                    PlayerMessage(
                        event: .syncTrack,
                        payload: .syncTrack(
                            player_session_id: sessionID,
                            progress: Int(value)
                        )
                    )
                )
            }
        }
    }
    
    func pauseCurrentTrack() {
        Task {
            try await pauseCurrentTrack()
        }
    }
    
    func pauseCurrentTrack() async throws {
        player.pause()
        
        guard
            let sessionID = self.playerSession?.id
        else {
            return
        }
        
        let value: Int = {
            let seconds = player.currentTime().seconds
            
            guard seconds.isFinite else {
                return 0
            }
            
            return Int(seconds)
        }()
        
        try await self.api.playerWebSocket?.send(
            PlayerMessage(
                event: .syncTrack,
                payload: .syncTrack(
                    player_session_id: sessionID,
                    progress: value
                )
            )
        )
    }
    
    func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack?.meta.title ?? "Untitled"
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentTrack?.meta.artist ?? "Unknown"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSDecimalNumber(decimal: currentTrackFile?.duration ?? 0)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        
        if let trackName = currentTrack?.name {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                boundsSize: CGSize(width: 1000, height: 1000),
                requestHandler: { boundsSize in
                    self.cachedArtworkImage(trackName) ?? UIImage()
                }
            )
        }
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        if #available(macOS 10, *) {
            nowPlayingInfoCenter.playbackState = player.rate == 0 ? .paused : .playing
        }
    }
}