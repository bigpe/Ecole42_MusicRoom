//
//  Track+FLAC.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 17.07.2022.
//

import Foundation

extension Track {
    var flacFile: File? {
        files.first(where: { $0.extension == .flac })
    }
}
