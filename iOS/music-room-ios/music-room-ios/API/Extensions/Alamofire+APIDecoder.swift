//
//  Alamofire+APIDecoder.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

extension DataRequest {
    public class APIDecoder: JSONDecoder {
        public override init() {
            super.init()
            
            dateDecodingStrategy =
                .custom({ decoder in
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
                })
        }
    }
    
    public func serializingAPI<Value: Decodable>(
        _ type: Value.Type = Value.self,
        automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
        dataPreprocessor: DataPreprocessor = DecodableResponseSerializer<Value>
            .defaultDataPreprocessor,
        decoder: DataDecoder = APIDecoder(),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<Value>.defaultEmptyResponseCodes,
        emptyRequestMethods: Set<HTTPMethod> = DecodableResponseSerializer<Value>
            .defaultEmptyRequestMethods
    ) -> DataTask<Value> {
        serializingResponse(
            using: DecodableResponseSerializer<Value>(
                dataPreprocessor: dataPreprocessor,
                decoder: decoder,
                emptyResponseCodes: emptyResponseCodes,
                emptyRequestMethods: emptyRequestMethods
            ),
            automaticallyCancelling: shouldAutomaticallyCancel
        )
    }
}
