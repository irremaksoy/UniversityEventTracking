import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Kullanıcı zaten giriş yaptıysa doğrudan ana ekrana geç
        if Auth.auth().currentUser != nil {
            navigateToMainScreen()
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text else { return }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Giriş başarısız: \(error.localizedDescription)")
            } else {
                print("Giriş başarılı: \(authResult?.user.email ?? "")")
                self.navigateToMainScreen()
            }
        }
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Şifre Sıfırlama", message: "Lütfen e-posta adresinizi girin", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Email"
        }

        let sendAction = UIAlertAction(title: "Gönder", style: .default) { _ in
            guard let email = alert.textFields?.first?.text, !email.isEmpty else {
                return
            }

            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("Hata oluştu: \(error.localizedDescription)")
                } else {
                    print("📨 Şifre sıfırlama e-postası gönderildi.")
                }
            }
        }

        alert.addAction(sendAction)
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))

        present(alert, animated: true)
    }

    private func navigateToMainScreen() {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBar") as? UITabBarController {
                tabBarController.modalPresentationStyle = .fullScreen
                self.present(tabBarController, animated: true, completion: nil)
            }
        }
    }
}
