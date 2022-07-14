//
//  APIAuthenticator.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

public class APIAuthenticator: Authenticator {
    public typealias Credential = APICredential
    
    // MARK: - Refresh Token Closure
    
    public typealias RefreshTokenClosure = ((String) async throws -> APICredential)
    
    public var refreshToken: RefreshTokenClosure
    
    // MARK: - Init
    
    public init(
        refreshToken: @escaping RefreshTokenClosure
    ) {
        self.refreshToken = refreshToken
    }
    
    // MARK: - Authenticator
    
    public func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.setValue(
            "Bearer \(credential.token.access)",
            forHTTPHeaderField: "Authorization"
        )
    }
    
    public func refresh(
        _ credential: Credential,
        for session: Session,
        completion: @escaping (Result<Credential, Error>) -> Void
    ) {
        Task {
            do {
                let credential = try await refreshToken(credential.token.refresh)
                
                completion(.success(credential))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    public func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: Error
    ) -> Bool {
        error.asAFError?.responseCode == 401
    }
    
    public func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: Credential
    ) -> Bool {
        urlRequest.headers.contains { header in
            header.name == "Authorization"
            && header.value == "Bearer \(credential.token.access)"
        }
    }
    
}

public typealias APIInterceptor = AuthenticationInterceptor<APIAuthenticator>
