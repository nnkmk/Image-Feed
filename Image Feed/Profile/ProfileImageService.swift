import Foundation

final class ProfileImageService {
    
    static let shared = ProfileImageService()
    private (set) var avatarURL: String?
    static let DidChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        
        let urlString = "https://api.unsplash.com/users/\(username)"
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let userResult):
                    self?.avatarURL = userResult.profileImage.small
                    if let avatarURL = self?.avatarURL {
                        completion(.success(avatarURL))
                        NotificationCenter.default.post(
                            name: ProfileImageService.DidChangeNotification,
                            object: self,
                            userInfo: ["URL": avatarURL]
                        )
                    }
                case .failure(let error):
                    print("Error fetching profile image: \(error)")
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
