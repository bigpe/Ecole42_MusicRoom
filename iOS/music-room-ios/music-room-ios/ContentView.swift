//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LazyVStack(alignment: .center, spacing: 64) {
            
            RoundedRectangle(cornerRadius: 8, style: .circular)
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.gray)
            
            LazyVStack(alignment: .leading, spacing: 48) {
                Text("Not Playing")
                    .font(.headline)
                    .dynamicTypeSize(.xLarge)
                
                LazyVStack(spacing: 8) {
                    ProgressView(value: 0.5, total: 1)
                        .tint(.gray)
                    
                    HStack {
                        Text("--:--")
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("--:--")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            LazyHStack(alignment: .center, spacing: 64) {
                Button {
                    print("Backward")
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
                
                Button {
                    print("Play")
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.black)
                }
                
                Button {
                    print("Forward")
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
            }
            
            LazyHStack(alignment: .center, spacing: 72) {
                Button {
                    print("Shuffle")
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Button {
                    print("Settings")
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Button {
                    print("Repeat")
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
