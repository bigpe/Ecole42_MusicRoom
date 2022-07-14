//
//  ContentView+ViewModel-Player.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 13.07.2022.
//

import Foundation
import MediaPlayer
import AVFoundation

extension ContentView.ViewModel {
    func playCurrentTrack() {
        guard
            let currentTrackFile = self.currentTrack?.file
                .replacingOccurrences(of: "http://", with: "https://"), // FIXME: Remove
            let currentTrackURL = URL(string: currentTrackFile)
        else {
            return
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
        
        if let progress = currentSessionTrack?.progress {
            let progress = NSDecimalNumber(decimal: progress).doubleValue
            let timeScale = CMTimeScale(1)
            let time = CMTime(seconds: progress, preferredTimescale: timeScale)
            
            guard time < playerItem.duration else { return }
            
            player.replaceCurrentItem(with: playerItem)
            
            updateNowPlayingInfo()
            
            player.automaticallyWaitsToMinimizeStalling = false
            
            playerSeekableTimeObserver = player.currentItem?.observe(\.status) {
                [unowned self] (playerItem, _) in
                
                guard
                    playerItem.status == .readyToPlay
                else {
                    return
                }
                
                @MainActor
                func seek() {
                    player.seek(to: time) { [unowned self] (status) in
                        print("\n\n\nWas Seeked?")
                        debugPrint(status)
                        print("\n\n\n")
                        
                        guard status else { return seek() }
                        
                        player.play()
                    }
                }
            }
        } else {
            player.play()
        }
        
        let total = (self.currentTrack?.duration as NSDecimalNumber?)?.doubleValue
        
        if let playerProgressTimeObserver = playerProgressTimeObserver {
            player.removeTimeObserver(playerProgressTimeObserver)
        }
        
        if let playerSyncTimeObserver = playerSyncTimeObserver {
            player.removeTimeObserver(playerSyncTimeObserver)
        }
        
        playerProgressTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.0001, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { cmTime in
            let value = cmTime.seconds
            
            self.trackProgress = TrackProgress(value: value, total: total)
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
        
        Task {
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
    }
    
    func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack?.name ?? "Untitled"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Music Room"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSDecimalNumber(decimal: currentTrack?.duration ?? 0)
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
        
        #if os(OSX)
        nowPlayingInfoCenter.playbackState = player.rate == 0 ? .paused : .playing
        #endif
    }
}
