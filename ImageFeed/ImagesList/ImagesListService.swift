import Foundation
import UIKit

final class ImagesListService {
    
    private (set) var photos: [Photo] = []
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    private var currentTask: URLSessionDataTask?
    var lastLoadedPage: Int = 1
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    func displayDate(from date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    //    func fetchPhotosNextPage(
    //        completion: @escaping (Result<[Photo], Error>) -> Void) {
    //            let nextPage = lastLoadedPage
    //            guard let url = URL(string: "https://api.unsplash.com/photos?page=\(nextPage)") else {
    //                return
    //            }
    //            var request = URLRequest(url:url)
    //            if let currentTask = currentTask, currentTask.state == .running {
    //                return
    //            }
    //            if let token = OAuth2TokenStorage.token {
    //
    //                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    //            }
    //            let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
    //                guard let self = self else { return }
    //                if let error = error {
    //                    completion(.failure(error))
    //                    return
    //                }
    //                guard let data = data else {
    //                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
    //                    return
    //                }
    //                do {
    //                    let photoResults = try self.decoder.decode([PhotoResult].self, from: data)
    //
    //                    let photos = photoResults.map {
    //                        Photo(
    //                            id: $0.id,
    //                            size: CGSize(width: $0.width, height: $0.height),
    //                            createdAt: $0.createdAt,
    //                            welcomeDescription: $0.description,
    //                            thumbImageURL: $0.urls.thumb,
    //                            largeImageURL: $0.urls.full,
    //                            fullImageUrl: $0.urls.full,
    //                            isLiked: $0.likedByUser
    //                        )
    //                    }
    //                    DispatchQueue.main.async {
    //                        self.photos += photos
    //                        self.lastLoadedPage += 1
    //                        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
    //                        completion(.success(photos))
    //                    }
    //
    //                }
    //                catch {
    //                    print("Ошибка декодирования: \(error)")
    //                }
    //                self.currentTask = nil
    //            }
    //            task.resume()
    //            currentTask = task
    //        }
    
    func fetchPhotosNextPage(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let nextPage = lastLoadedPage
        guard let url = URL(string: "https://api.unsplash.com/photos?page=\(nextPage)") else {
            return
        }
        var request = URLRequest(url: url)
        if let currentTask = currentTask, currentTask.state == .running {
            return
        }
        if let token = OAuth2TokenStorage.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Вот тут начинается обновление
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let dateFormats = ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ", "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"]
            
            for dateFormat in dateFormats {
                dateFormatter.dateFormat = dateFormat
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Не удалось декодировать дату: \(dateString)")
        })
        // Обновление заканчивается здесь
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                return
            }
            do {
                let photoResults = try decoder.decode([PhotoResult].self, from: data)
                let photos = photoResults.map {
                    Photo(
                        id: $0.id,
                        size: CGSize(width: $0.width, height: $0.height),
                        createdAt: $0.createdAt,
                        welcomeDescription: $0.description,
                        thumbImageURL: $0.urls.thumb,
                        largeImageURL: $0.urls.full,
                        fullImageUrl: $0.urls.full,
                        isLiked: $0.likedByUser
                    )
                }
                DispatchQueue.main.async {
                    self.photos += photos
                    self.lastLoadedPage += 1
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                    completion(.success(photos))
                }
            } catch {
                print("Ошибка декодирования: \(error)")
            }
            self.currentTask = nil
        }
        task.resume()
        currentTask = task
    }
    
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
            return
        }
        var request = URLRequest(url:url)
        request.addValue("Bearer \(OAuth2TokenStorage.token ?? "")", forHTTPHeaderField: "Authorization")
        request.httpMethod = isLike ? "POST" : "DELETE"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                }
                return
            }
            do {
                
                let likeResponse = try self.decoder.decode(LikeResponse.self, from: data)
                let photoResult = likeResponse.photo
                let updatedPhoto = Photo(
                    id: photoResult.id,
                    size: CGSize(width: photoResult.width, height: photoResult.height),
                    createdAt: photoResult.createdAt,
                    welcomeDescription: photoResult.description,
                    thumbImageURL: photoResult.urls.thumb,
                    largeImageURL: photoResult.urls.full,
                    fullImageUrl: photoResult.urls.full,
                    isLiked: photoResult.likedByUser
                )
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        self.photos[index] = updatedPhoto
                        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
                        completion(.success(()))
                        
                    }
                }
            } catch {
                print("Ошибка декодирования: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

struct PhotoResult: Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let width: Int
    let height: Int
    let color: String
    let blurHash: String
    let likes: Int
    let likedByUser: Bool
    let description: String?
    let urls: UrlsResult
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width
        case height
        case color
        case blurHash = "blur_hash"
        case likes
        case likedByUser = "liked_by_user"
        case description
        case urls
    }
}

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageUrl: String
    var isLiked: Bool
}

struct LikeResponse: Codable {
    let photo: PhotoResult
    let user: UserResult
}
