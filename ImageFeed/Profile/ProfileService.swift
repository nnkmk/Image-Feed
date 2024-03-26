import Foundation
final class ProfileService {
    
    static let shared = ProfileService()
    private(set) var profile: Profile?
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        let url = URL(string: "https://api.unsplash.com/me")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let profileResult):
                    let name = "\(profileResult.firstName) \(profileResult.lastName ?? "")"
                    let profile = Profile(
                        username: profileResult.username,
                        name: name,
                        loginName: "@\(profileResult.username)",
                        bio: profileResult.bio
                    )
                    self.profile = profile
                    completion(.success(profile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        
    }
    
}
