//
//  ProgressSlider.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 13.07.2022.
//

import SwiftUI

struct ProgressSlider: View {
    
    @Binding
    var trackProgress: ContentView.ViewModel.TrackProgress
    
    @Binding
    var isProgressTracking: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.accentColor.opacity(0.3))
                
                Rectangle()
                    .foregroundColor(.accentColor)
                    .frame(
                        width: {
                            guard
                                let value = trackProgress.value,
                                let total = trackProgress.total,
                                total != 0
                            else {
                                return 0
                            }
                            
                            return geometry.size.width * CGFloat(value / total)
                        }()
                    )
            }
            .cornerRadius(2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isProgressTracking = true
                        
                        let percentage = min(max(0, Double(value.location.x / geometry.size.width)), 1)
                        
                        guard
                            let total = trackProgress.total
                        else {
                            return
                        }
                        
                        let value = total * percentage
                        
                        trackProgress = ContentView.ViewModel.TrackProgress(
                            value: value,
                            total: total
                        )
                    }
                    .onEnded { value in
                        isProgressTracking = false
                        
                        let percentage = min(max(0, Double(value.location.x / geometry.size.width)), 1)
                        
                        guard
                            let total = trackProgress.total
                        else {
                            return
                        }
                        
                        let value = total * percentage
                        
                        trackProgress = ContentView.ViewModel.TrackProgress(
                            value: value,
                            total: total
                        )
                    }
            )
        }
    }
}
