import Foundation
import Alamofire

extension DataTask {
    func valueOrError<ErrorValue: Error & Decodable>(
        _ errorType: ErrorValue.Type = ErrorValue.self
    ) async throws -> Result<Value, ErrorValue> where Value: Decodable {
        guard
            let data = await response.data
        else {
            throw API.APIError.invalidResponse
        }
        
        let apiDecoder = API.Decoder()
        
        do {
            return .success(try apiDecoder.decode(Value.self, from: data))
        } catch {
            guard
                let errorValue = try? apiDecoder.decode(ErrorValue.self, from: data)
            else {
                throw error
            }
            
            return .failure(errorValue)
        }
    }
}
