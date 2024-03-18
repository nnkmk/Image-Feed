import Foundation

struct ProfileImageURL: Codable {
    let small: String
    let medium: String
    let large: String
    
}

struct UserResult: Codable {
    let profileImage: ProfileImageURL
    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?
    private enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String?
    let loginName: String
    let bio: String?
}
