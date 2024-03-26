import UIKit
import Kingfisher

class ImagesListViewController: UIViewController {
    
    var photos: [Photo] = []
    var photo: Photo!
    @IBOutlet private weak var tableView: UITableView!
    private let photosName: [String] = Array(0..<21).map{ "\($0)" }
    private let ShowSingleImageSegueIdentifier = "ShowSingleImage"
    private let imageService = ImagesListService()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableViewAnimated), name: ImagesListService.didChangeNotification, object: nil)
        imageService.fetchPhotosNextPage { result in
            switch result {
            case .success(let photos):
                break
            case .failure(let error):
                print("Ошибка при загрузке: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowSingleImageSegueIdentifier,
           let viewController = segue.destination as? SingleImageViewController,
           let indexPath = sender as? IndexPath {
            viewController.photo = photos[indexPath.row]
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM yyyy"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter
        }()
    
    @objc func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = imageService.photos
        let newCount = newPhotos.count
        
        photos = newPhotos
        
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }
    
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath) {
            if indexPath.row + 1 == imageService.photos.count {
                imageService.fetchPhotosNextPage(completion: { [weak self] result in
                    switch result {
                    case .success(let photos):
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                        
                    case .failure(let error):
                        print("Ошибка при загрузке")
                    }
                })
            }
        }
    
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            return photos.count
        }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
        
    }
    
    
}

extension ImagesListViewController: UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: ShowSingleImageSegueIdentifier, sender: indexPath)
        }
    
    func tableView
    (_ tableView: UITableView,
     heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let photo = photos[indexPath.row]
        let aspectRatio = CGFloat(photo.size.height) / CGFloat(photo.size.width)
        let width = tableView.frame.width
        return width * aspectRatio
    }
}

extension ImagesListViewController {
    
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        
        if let url = URL(string: photo.thumbImageURL) {
            cell.cellImage.kf.indicatorType = .activity
            cell.cellImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "zaglushka")
            )
        }
        
        let isLiked = photo.isLiked
        let likeImage = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}


extension ImagesListViewController: ImagesListCellDelegate {
    
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = imageService.photos[indexPath.row]
        UIBlockingProgressHUD.show()
        let newLikeStatus = !photo.isLiked
        imageService.changeLike(photoId: photo.id, isLike: newLikeStatus) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    cell.setIsLiked(newLikeStatus)
                    self.photos[indexPath.row].isLiked = newLikeStatus
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    UIBlockingProgressHUD.dismiss()
                }
            case .failure:
                DispatchQueue.main.async {
                    UIBlockingProgressHUD.dismiss()
                }
            }
        }
    }
}

