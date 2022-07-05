//
//  Alamofire+APIDecoder.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

extension DataRequest {
    public func serializingAPI<Value: Decodable>(
        _ type: Value.Type = Value.self,
        automaticallyCancelling shouldAutomaticallyCancel: Bool = false,
        dataPreprocessor: DataPreprocessor = DecodableResponseSerializer<Value>
            .defaultDataPreprocessor,
        decoder: DataDecoder = API.Decoder(),
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
