import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    let urlSession = URLSession.shared
    private var activeTask: URLSessionTask?
    private var activeCode: String?
    
    
    private(set) var authToken: String? {
        get {
            return OAuth2TokenStorage.token
        }
        set {
            OAuth2TokenStorage.token = newValue
        }
    }
    
    private enum NetworkError: Error {
        case httpStatusCode(Int)
        case urlRequestError(Error)
        case urlSessionError
    }
    
    func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        
        if let activeTask = activeTask, activeCode != code {
            activeTask.cancel()
        } else if activeTask != nil {
            return
        }
        
        activeCode = code
        
        let request = authTokenRequest(code: code)
        let task = self.urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activeTask = nil
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))
                case .failure(let error):
                    self.activeCode = nil
                    completion(.failure(error))
                }
            }
        }
        
        activeTask = task
        task.resume()
    }
    
    
    private func object(
        for request: URLRequest,
        completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.dataTask(with: request) { (data, response, error) in
            if let data = data,
               let response = response as? HTTPURLResponse,
               200 ..< 300 ~= response.statusCode {
                do {
                    let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(responseBody))
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NetworkError.urlSessionError))
            }
        }
    }
    
    private func authTokenRequest(code: String) -> URLRequest {
        let parameters = [
            "client_id": accessKey,
            "client_secret": secretKey,
            "redirect_uri": redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        let url = URL(string: "https://unsplash.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        return request
    }
    
    struct OAuthTokenResponseBody: Codable {
        let accessToken: String
        let tokenType: String
        let scope: String
        let createdAt: Int
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case scope
            case createdAt = "created_at"
        }
    }
}

