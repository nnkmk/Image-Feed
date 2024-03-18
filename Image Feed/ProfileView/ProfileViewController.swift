import UIKit
import Kingfisher


final class ProfileViewController: UIViewController {
    
    private var userNameLabel: UILabel?
    private var nickNameLabel: UILabel?
    private var descriptionLabel: UILabel?
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    private var profileImageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProfileImageView()
        configureUserNameLabel()
        configureNickNameLabel()
        configureDescriptionLabel()
        configureExitButton()
        view.backgroundColor = .ypBlack

        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.DidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        updateAvatar()
        
        if let profile = profileService.profile {
            userNameLabel?.text = profile.name
            nickNameLabel?.text = profile.loginName
            descriptionLabel?.text = profile.bio
        }
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        profileImageView?.kf.setImage(with: url)
        
    }
    
    
    private func configureProfileImageView() {
       
        let profileImage = UIImage(named: "Photo")
        let imageView = UIImageView(image: profileImage)
        imageView.tintColor = .ypGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        profileImageView = imageView
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true

    }
    
    
    private func configureUserNameLabel() {
        let labelUserName = UILabel()
        labelUserName.textColor = .ypWhite
        labelUserName.font = UIFont.boldSystemFont(ofSize: 23)
        labelUserName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelUserName)
        labelUserName.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        labelUserName.topAnchor.constraint(equalTo: profileImageView?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.userNameLabel = labelUserName
        
    }
    
    
    private func configureNickNameLabel() {
        let labelnickName = UILabel()
        labelnickName.textColor = .ypGray
        labelnickName.font = UIFont(name: "HelveticaNeue", size: 13)
        labelnickName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelnickName)
        labelnickName.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        labelnickName.topAnchor.constraint(equalTo: userNameLabel?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        self.nickNameLabel = labelnickName
    }
    
    private func configureDescriptionLabel() {
        let labelDescription = UILabel()
        labelDescription.textColor = .ypWhite
        labelDescription.font = UIFont(name: "HelveticaNeue", size: 13)
        labelDescription.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelDescription)
        labelDescription.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        labelDescription.topAnchor.constraint(equalTo: nickNameLabel?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        self.descriptionLabel = labelDescription
    }
    
    private func configureExitButton() {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "Exit"), for: .normal)
        button.tintColor = .ypRed
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 55).isActive = true
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }
}
