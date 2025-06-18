import UIKit
import MessageUI
import FirebaseAuth

class ProfileViewController: UIViewController, MFMailComposeViewControllerDelegate {

    private let stackView = UIStackView()


    private lazy var emailTextField: UITextField = {
          createInputField(
              placeholder: "E-posta",
              icon: UIImage(systemName: "envelope")
          )
      }()

      private lazy var passwordTextField: UITextField = {
          let tf = createInputField(
              placeholder: "Yeni Şifre",
              icon: UIImage(systemName: "lock")
          )
          tf.isSecureTextEntry = true
          return tf
      }()


    private let updateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Bilgileri Güncelle", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ayarlar"
        view.backgroundColor = .systemBackground
        setupLayout()
        loadUserInfo()
    }
    
    private func createInputField(placeholder: String, icon: UIImage?) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .none
        tf.backgroundColor = UIColor.systemGray6
        tf.layer.cornerRadius = 10
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        tf.setLeftPaddingWithIcon(icon: icon, padding: 12)
        return tf
    }

    

    private func setupLayout() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Butonlar
        let clearButton = makeStyledButton(title: "Favorileri Temizle", color: .systemGray5)
        let feedbackButton = makeStyledButton(title: "Geri Bildirim Gönder", color: .systemGray5)
        let logoutButton = makeStyledButton(title: "Çıkış Yap", color: .systemGray5)

        clearButton.addTarget(self, action: #selector(clearFavoritesTapped), for: .touchUpInside)
        feedbackButton.addTarget(self, action: #selector(sendFeedbackTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(updateCredentials), for: .touchUpInside)

        // Stack'e ekle
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(updateButton)
        stackView.addArrangedSubview(clearButton)
        stackView.addArrangedSubview(feedbackButton)
        stackView.addArrangedSubview(logoutButton)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func makeStyledButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 3
        return button
    }

    private func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            emailTextField.text = user.email
            passwordTextField.text = ""
        }
    }

    @objc private func updateCredentials() {
        guard let user = Auth.auth().currentUser else { return }
  
        if let newEmail = emailTextField.text, !newEmail.isEmpty, newEmail != user.email {
            user.updateEmail(to: newEmail) { error in
                if let error = error as NSError? {
                    if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        self.showToast("Lütfen tekrar giriş yap ve yeniden dene.")
                    } else {
                        self.showToast("E-posta güncellenemedi: \(error.localizedDescription)")
                    }
                } else {
                    self.showToast("E-posta başarıyla güncellendi.")
                }
            }
        }


     

        if let newPassword = passwordTextField.text, !newPassword.isEmpty {
            user.updatePassword(to: newPassword) { error in
                if let error = error {
                    self.showToast("Şifre güncellenemedi: \(error.localizedDescription)")
                } else {
                    self.showToast("Şifre güncellendi.")
                }
            }
        }
        
    }

    @objc private func clearFavoritesTapped() {
        UserDefaults.standard.removeObject(forKey: "favoriteEvents")
        showToast("Favoriler temizlendi.")
    }

    @objc private func sendFeedbackTapped() {
        guard MFMailComposeViewController.canSendMail() else {
            showToast("Mail uygulaması açılamıyor.")
            return
        }
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setToRecipients(["destek@uygulama.com"])
        mailVC.setSubject("Etkinlik Uygulaması Geri Bildirim")
        mailVC.setMessageBody("Merhaba, önerim/şikayetim şudur:", isHTML: false)
        present(mailVC, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Çıkış Yapılsın mı?",
            message: "Hesabınızdan çıkış yapılacak.",
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive, handler: { _ in
            do {
                try Auth.auth().signOut()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "ViewController")
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: true)
            } catch {
                self.showToast("Çıkış yapılamadı.")
            }
        }))

        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 14)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 1
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.frame = CGRect(x: 40, y: view.frame.height - 100, width: view.frame.width - 80, height: 35)
        view.addSubview(label)

        UIView.animate(withDuration: 2.5, delay: 0.5, options: .curveEaseOut, animations: {
            label.alpha = 0.0
        }, completion: { _ in
            label.removeFromSuperview()
        })
        
        
    }


}
// MARK: - UITextField + Icon & Padding Extension
extension UITextField {
    func setLeftPaddingWithIcon(icon: UIImage?, padding: CGFloat) {
        let iconView = UIImageView(image: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .gray
        iconView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44 + padding, height: 44))
        iconView.center = CGPoint(x: 22, y: 22)
        paddingView.addSubview(iconView)

        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
