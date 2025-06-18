import UIKit
import FirebaseFirestore
import FirebaseAuth

struct ParticipatedEvent {
    let title: String
    let date: String
    let description: String
    let location: String
}

class MyParticipatedEventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    private var participatedEvents: [ParticipatedEvent] = []

    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yenile 🔄", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        view.backgroundColor = UIColor(red: 230/255, green: 237/255, blue: 255/255, alpha: 1.0)
        setupTableView()
        setupRefreshButton()
        fetchParticipatedEvents()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60) // refresh button için boşluk
        ])
    }

    private func setupRefreshButton() {
        view.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 160),
            refreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
    }

    @objc private func refreshTapped() {
        fetchParticipatedEvents()
        showToast("Liste yenilendi")
    }

    private func fetchParticipatedEvents() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }

        let db = Firestore.firestore()
        db.collection("katilimcilar")
            .whereField("email", isEqualTo: userEmail)
            .order(by: "joinedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Hata: \(error.localizedDescription)")
                    return
                }

                self.participatedEvents = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let date = data["startDate"] as? Timestamp,
                          let description = data["description"] as? String,
                          let location = data["location"] as? String else { return nil }

                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "tr_TR")
                    formatter.dateFormat = "dd MMM yyyy, HH:mm"
                    let formattedDate = formatter.string(from: date.dateValue())

                    return ParticipatedEvent(title: title, date: formattedDate, description: description, location: location)
                } ?? []

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: TableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participatedEvents.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = participatedEvents[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        let horizontalMargin: CGFloat = 50
        let cardWidth = tableView.frame.width - (horizontalMargin * 2)
        let cardView = UIView(frame: CGRect(x: horizontalMargin, y: 10, width: cardWidth, height: 110))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        let iconView = UIImageView(frame: CGRect(x: 12, y: 30, width: 40, height: 40))
        iconView.image = UIImage(systemName: "calendar.badge.clock")
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel(frame: CGRect(x: 64, y: 25, width: cardView.frame.width - 80, height: 24))
        titleLabel.text = event.title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label

        let dateLabel = UILabel(frame: CGRect(x: 64, y: 54, width: cardView.frame.width - 80, height: 20))
        dateLabel.text = event.date
        dateLabel.font = UIFont.systemFont(ofSize: 13)
        dateLabel.textColor = .systemGray

        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(dateLabel)
        cell.contentView.addSubview(cardView)

        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Detay ekranına geçiş yapılmıyor (isteğe göre kapatıldı)
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
