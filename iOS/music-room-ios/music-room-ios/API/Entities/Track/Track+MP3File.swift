import Foundation

extension Track {
    var mp3File: File? {
        files.first(where: { $0.extension == .mp3 })
    }
}
