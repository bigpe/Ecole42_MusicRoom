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
    var isTracking: Bool
    
    @Binding
    var initialValue: Double?
    
    @Binding
    var shouldAnimatePadding: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.accentColor.opacity(0.3))
                
                Rectangle()
                    .foregroundColor(isTracking ? .accentColor : .accentColor.opacity(0.75))
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
            .frame(height: isTracking ? 8 : 4)
            .cornerRadius(isTracking ? 4 : 2)
            .padding(.vertical, isTracking ? 0 : 2)
            .animation(.easeIn(duration: 0.18), value: shouldAnimatePadding)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isTracking {
                            isTracking = true
                            initialValue = trackProgress.value
                        }
                        
                        guard
                            let value = initialValue,
                            let total = trackProgress.total,
                            total != 0
                        else {
                            return
                        }
                        
                        let trackProgressPercentage = value / total
                        let translationPercentage = gesture.translation.width / geometry.size.width
                        
                        debugPrint(value, total, gesture.translation.width, geometry.size.width)
                        print("\n\n")
                        
                        let percentage = max(
                            0,
                            min(
                                1,
                                trackProgressPercentage + translationPercentage
                            )
                        )
                        
                        trackProgress = ContentView.ViewModel.TrackProgress(
                            value: total * percentage,
                            total: total
                        )
                    }
                    .onEnded { gesture in
                        isTracking = false
                        initialValue = nil
                        
                        guard
                            let value = initialValue,
                            let total = trackProgress.total,
                            total != 0
                        else {
                            return
                        }
                        
                        let trackProgressPercentage = value / total
                        let translationPercentage = gesture.translation.width / geometry.size.width
                        
                        let percentage = max(
                            0,
                            min(
                                1,
                                trackProgressPercentage + translationPercentage
                            )
                        )
                        
                        trackProgress = ContentView.ViewModel.TrackProgress(
                            value: total * percentage,
                            total: total
                        )
                    }
            )
        }
    }
}
