import Foundation

extension Track {
    var flacFile: File? {
        files.first(where: { $0.extension == .flac })
    }
}
