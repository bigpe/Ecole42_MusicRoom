//
//  API+Decoder.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 05.07.2022.
//

import Foundation

extension API {
    public class Decoder: JSONDecoder {
        public override init() {
            super.init()
            
            dateDecodingStrategy = .custom(
                { decoder in
                    let container = try decoder.singleValueContainer()
                    
                    let dateText = try container.decode(String.self)
                    
                    let dateTimeFormatter = DateFormatter()
                    
                    dateTimeFormatter.calendar = Calendar(identifier: .iso8601)
                    dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
                    
                    let dateDayFormatter = DateFormatter()
                    
                    dateDayFormatter.calendar = Calendar(identifier: .iso8601)
                    dateDayFormatter.dateFormat = "yyyy-MM-dd"
                    
                    if let dateTime = dateTimeFormatter.date(from: dateText) {
                        return dateTime
                    } else if let dateDay = dateDayFormatter.date(from: dateText) {
                        return dateDay
                    } else {
                        throw DecodingError.typeMismatch(
                            Date.self,
                            DecodingError.Context(
                                codingPath: container.codingPath,
                                debugDescription:
                                    "Can't decode \(container.codingPath) as DateTime or DateDay"
                            )
                        )
                    }
                }
            )
        }
    }
    
    public class Encoder: JSONEncoder {
        public override init() {
            super.init()
            
            dateEncodingStrategy = .formatted(
                {
                    let dateFormatter = DateFormatter()
                    
                    dateFormatter.calendar = Calendar(identifier: .iso8601)
                    
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
                    
                    return dateFormatter
                }()
            )
        }
    }
}
