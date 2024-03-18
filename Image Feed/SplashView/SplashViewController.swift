import UIKit
import ProgressHUD

final class SplashViewController: UIViewController {
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let profileService = ProfileService.shared
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let imageView = UIImageView(image: UIImage(named: "auth_screen_logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        if let token = OAuth2TokenStorage.token {
            UIBlockingProgressHUD.show()
            fetchProfile(token: token)
            switchToTabBarController()
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController {
                authViewController.modalPresentationStyle = .fullScreen
                authViewController.delegate = self
                present(authViewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Invalid Configuration") }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
    
    func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in
                    UIBlockingProgressHUD.dismiss()
                    self?.switchToTabBarController() }
            case .failure(let error):
                print("Network request failed: \(error)")
                UIBlockingProgressHUD.dismiss()
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Что-то пошло не так(", message: "Не удалось загрузить профиль", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ок", style: .default))
                    self?.present(alertController, animated: true, completion: nil)
                }
                break
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
                self.fetchOAuthToken(code)
        }
    }
    
    private func fetchOAuthToken(_ code: String) {
        
        OAuth2Service.shared.fetchOAuthToken(code) { [weak self] result in
            
            guard let self = self else { return }
            switch result {
            case .success(let authToken):
                UIBlockingProgressHUD.dismiss()
                OAuth2TokenStorage.token = authToken
                self.fetchProfile(token: authToken)
            case .failure:
                UIBlockingProgressHUD.dismiss()
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Что-то пошло не так(", message: "Не удалось войти в систему", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ок", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                }
                break
            }
        }
    }
    
}
