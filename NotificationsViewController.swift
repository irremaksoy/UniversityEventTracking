import UIKit
import FirebaseAuth
import FirebaseFirestore

class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var notifications: [[String: Any]] = []
    private let tableView = UITableView()

    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yenile 🔄", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bildirimler"
        view.backgroundColor = UIColor(red: 230/255, green: 237/255, blue: 255/255, alpha: 1.0)
        setupViews()
        fetchNotifications()
    }

    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(refreshButton)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")

        NSLayoutConstraint.activate([
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 160),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: refreshButton.topAnchor, constant: -12)
        ])

        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
    }

    @objc private func refreshTapped() {
        fetchNotifications()
        showToast("Bildirimler yenilendi")
    }

    private func fetchNotifications() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let notifRef = db.collection("users").document(user.uid).collection("notifications")

        notifRef.order(by: "triggerDate", descending: false).getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
              
                let now = Date()
                for doc in documents {
                    let data = doc.data()
                    if let isRead = data["isRead"] as? Bool,
                       let triggerTs = data["triggerDate"] as? Timestamp,
                       isRead == true,
                       triggerTs.dateValue() < now.addingTimeInterval(-3 * 24 * 60 * 60) {
                        db.collection("users").document(user.uid).collection("notifications").document(doc.documentID).delete()
                        print("🗑️ Eski okundu bildirim silindi.")
                    }
                }

                self.notifications = documents.compactMap {
                    let data = $0.data()
                    if let triggerTs = data["triggerDate"] as? Timestamp,
                       triggerTs.dateValue() <= now {
                        return data
                    } else {
                        return nil
                    }
                }

                let unreadCount = self.notifications.filter { ($0["isRead"] as? Bool) == false }.count

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tabBarItem.badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
                }

                let batch = db.batch()
                for doc in documents {
                    batch.updateData(["isRead": true], forDocument: doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Okundu işaretleme hatası: \(error.localizedDescription)")
                    } else {
                        print("✅ Bildirimler okundu olarak işaretlendi.")
                    }
                }

            } else {
                print("🔴 Bildirimler alınamadı: \(error?.localizedDescription ?? "Bilinmeyen hata")")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "NotificationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) ?? UITableViewCell(style: .default, reuseIdentifier: reuseId)

        let notif = notifications[indexPath.row]
        let title = notif["title"] as? String ?? "Etkinlik"
        var dateText = ""
        if let ts = notif["triggerDate"] as? Timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, HH:mm"
            dateText = formatter.string(from: ts.dateValue())
        }

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let horizontalMargin: CGFloat = 50
        let verticalOffset: CGFloat = 100
        let cardWidth = tableView.frame.width - (horizontalMargin * 2)

        let cardView = UIView(frame: CGRect(x: horizontalMargin, y: verticalOffset, width: cardWidth, height: 100))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        let iconView = UIImageView(frame: CGRect(x: 12, y: 30, width: 40, height: 40))
        iconView.image = UIImage(systemName: "bell.fill")
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true

        let titleLabel = UILabel(frame: CGRect(x: 64, y: 25, width: cardView.frame.width - 80, height: 24))
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label

        let subLabel = UILabel(frame: CGRect(x: 64, y: 54, width: cardView.frame.width - 80, height: 20))
        subLabel.text = dateText
        subLabel.font = UIFont.systemFont(ofSize: 13)
        subLabel.textColor = .systemGray

        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subLabel)
        cell.contentView.addSubview(cardView)

        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        return cell
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
        label.frame = CGRect(x: 40, y: view.frame.height - 120, width: view.frame.width - 80, height: 35)
        view.addSubview(label)

        UIView.animate(withDuration: 2.5, delay: 0.5, options: .curveEaseOut, animations: {
            label.alpha = 0.0
        }, completion: { _ in
            label.removeFromSuperview()
        })
    }
}
