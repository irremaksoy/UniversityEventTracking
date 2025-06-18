import UIKit
import FirebaseFirestore
import FirebaseAuth

struct EventParticipant {
    let email: String
    let joinedAt: Date
}

class EventParticipantsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var eventTitle: String = ""
    private var participants: [EventParticipant] = []

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Katılımcı Listesi"
        view.backgroundColor = .systemBackground
        setupTableView()
        fetchParticipants()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func fetchParticipants() {
        let db = Firestore.firestore()
        db.collection("katilimcilar")
            .whereField("title", isEqualTo: eventTitle)
            .order(by: "joinedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Hata: \(error.localizedDescription)")
                    return
                }

                self.participants = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let email = data["email"] as? String,
                          let timestamp = data["joinedAt"] as? Timestamp else { return nil }
                    return EventParticipant(email: email, joinedAt: timestamp.dateValue())
                } ?? []

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: - TableView Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let user = participants[indexPath.row]
        cell.textLabel?.text = user.email
        cell.detailTextLabel?.text = "Katıldı: \(formatDate(user.joinedAt))"
        return cell
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Swipe to Delete (Kendi Katılımı Sil )

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let participant = participants[indexPath.row]

        guard let currentEmail = Auth.auth().currentUser?.email,
              currentEmail == participant.email else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Vazgeç") { [weak self] _, _, completionHandler in
            self?.deleteParticipation(at: indexPath)
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func deleteParticipation(at indexPath: IndexPath) {
        let participant = participants[indexPath.row]
        let db = Firestore.firestore()

        db.collection("katilimcilar")
            .whereField("title", isEqualTo: eventTitle)
            .whereField("email", isEqualTo: participant.email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Silme sorgusu hatası: \(error.localizedDescription)")
                    return
                }

                snapshot?.documents.forEach { document in
                    db.collection("katilimcilar").document(document.documentID).delete { error in
                        if let error = error {
                            print("❌ Firestore silme hatası: \(error.localizedDescription)")
                        } else {
                            print("✅ Katılım silindi")
                            DispatchQueue.main.async {
                                self.participants.remove(at: indexPath.row)
                                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                            }
                        }
                    }
                }
            }
    }
}
