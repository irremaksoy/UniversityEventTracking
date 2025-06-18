import UIKit
import EventKit
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class DetailViewController: UIViewController {

    var eventTitle: String?
    var eventDate: String?
    var eventLocation: String?
    var eventDescription: String?
    var eventImage: UIImage?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let dateIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.tintColor = .darkGray
        iv.contentMode = .scaleAspectFit
        iv.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return iv
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        return label
    }()

    private let locationIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        iv.tintColor = .gray
        iv.contentMode = .scaleAspectFit
        iv.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return iv
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .gray
        return label
    }()

    private let descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Açıklama"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .label
        return label
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Katıl", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Etkinlik Detayı"
        setupLayout()
        populateData()
        updateJoinButtonTitle()

        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Katılımcılar",
            style: .plain,
            target: self,
            action: #selector(showParticipants)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: isFavorite() ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(toggleFavorite)
        )
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let dateStack = UIStackView(arrangedSubviews: [dateIcon, dateLabel])
        dateStack.axis = .horizontal
        dateStack.spacing = 8
        dateStack.alignment = .center

        let locationStack = UIStackView(arrangedSubviews: [locationIcon, locationLabel])
        locationStack.axis = .horizontal
        locationStack.spacing = 8
        locationStack.alignment = .center

        let stack = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            dateStack,
            locationStack,
            descriptionTitleLabel,
            divider,
            descriptionLabel,
            joinButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 250)
        ])
    }

    private func populateData() {
        imageView.image = eventImage ?? UIImage(systemName: "photo")
        titleLabel.text = eventTitle ?? "Etkinlik Başlığı"
        dateLabel.text = eventDate ?? "Tarih yok"
        locationLabel.text = eventLocation ?? "Lokasyon yok"
        descriptionLabel.text = eventDescription ?? "Açıklama bulunamadı."
    }

    private func updateJoinButtonTitle() {
        guard let title = eventTitle,
              let email = Auth.auth().currentUser?.email else { return }

        let db = Firestore.firestore()
        db.collection("katilimcilar")
            .whereField("title", isEqualTo: title)
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    if let docs = snapshot?.documents, !docs.isEmpty {
                        self.joinButton.setTitle("Vazgeç", for: .normal)
                    } else {
                        self.joinButton.setTitle("Katıl", for: .normal)
                    }
                }
            }
    }

    @objc private func joinTapped() {
        guard let title = eventTitle,
              let description = eventDescription,
              let location = eventLocation,
              let dateString = eventDate,
              let startDate = parseDate(from: dateString),
              let email = Auth.auth().currentUser?.email else {
            return
        }

        let endDate = startDate.addingTimeInterval(2 * 60 * 60)
        let db = Firestore.firestore()

        db.collection("katilimcilar")
            .whereField("title", isEqualTo: title)
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    // Kullanıcı zaten katılmış vazgeç
                    for doc in docs {
                        db.collection("katilimcilar").document(doc.documentID).delete { _ in
                            print("❌ Katılım iptal edildi")
                            DispatchQueue.main.async {
                                self.joinButton.setTitle("Katıl", for: .normal)
                            }
                        }
                    }

                    // 🔥 Firestore'daki bildirimi sil
                    db.collection("users")
                        .document(Auth.auth().currentUser!.uid)
                        .collection("notifications")
                        .whereField("title", isEqualTo: self.eventTitle ?? "")
                        .whereField("message", isEqualTo: "\(title) etkinliği 1 saat içinde başlıyor!")
                        .getDocuments { snapshot, _ in
                            snapshot?.documents.forEach { notifDoc in
                                notifDoc.reference.delete { error in
                                    if let error = error {
                                        print("❌ Firestore bildirimi silinemedi: \(error.localizedDescription)")
                                    } else {
                                        print("🗑️ Firestore bildirimi silindi.")
                                    }
                                }
                            }
                        }

                    // 🔕 Yerel bildirimi iptal et
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    print("🔕 Local notification silindi.")

                } else {
                    // Katılım ekleniyor
                    let data: [String: Any] = [
                        "title": title,
                        "description": description,
                        "location": location,
                        "startDate": Timestamp(date: startDate),
                        "endDate": Timestamp(date: endDate),
                        "email": email,
                        "joinedAt": Timestamp(date: Date())
                    ]
                    db.collection("katilimcilar").addDocument(data: data) { error in
                        if error == nil {
                            print("Katılım eklendi")
                            DispatchQueue.main.async {
                                self.joinButton.setTitle("Vazgeç", for: .normal)
                            }

                            self.addToAppleCalendar(title: title, description: description, location: location, startDate: startDate, endDate: endDate)
                            self.scheduleLocalNotification(
                                title: title, // artık başlık, etkinlik ismi
                                body: "\(title) etkinliği 1 saat içinde başlıyor!",
                                date: Calendar.current.date(byAdding: .hour, value: -1, to: startDate) ?? startDate
                            )
                            self.saveNotificationToFirestore(eventTitle: title, eventDate: startDate)
                        }
                    }
                }
            }
    }

    private func saveNotificationToFirestore(eventTitle: String, eventDate: Date) {
        guard let user = Auth.auth().currentUser else { return }
        guard let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: eventDate) else { return }

        let data: [String: Any] = [
            "title": eventTitle,
            "message": "\(eventTitle) etkinliği 1 saat içinde başlıyor!",
            "eventDate": Timestamp(date: eventDate),
            "triggerDate": Timestamp(date: triggerDate),
            "createdAt": Timestamp(date: Date())
        ]

        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .collection("notifications")
            .addDocument(data: data) { error in
                if let error = error {
                    print("❌ Firestore'a bildirim eklenemedi: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore'a bildirim başarıyla kaydedildi.")
                }
            }
    }

    private func scheduleLocalNotification(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("📱 Bildirim planlanamadı: \(error.localizedDescription)")
            } else {
                print("📱 Bildirim başarıyla planlandı.")
            }
        }
    }

    private func parseDate(from string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd HH:mm",
            "dd.MM.yyyy HH:mm",
            "yyyy-MM-dd",
            "dd.MM.yyyy",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "dd MMM yyyy, HH:mm",
            "dd MMMM yyyy, HH:mm"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        formatter.locale = Locale(identifier: "en_US")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    private func addToAppleCalendar(title: String, description: String, location: String, startDate: Date, endDate: Date) {
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: .event) { granted, error in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.location = location
                event.notes = description
                event.calendar = eventStore.defaultCalendarForNewEvents

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("📆 Apple Takvimi'ne eklendi")
                } catch {
                    print("❌ Apple Takvimi'ne eklenemedi: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func showParticipants() {
        let vc = EventParticipantsViewController()
        vc.eventTitle = eventTitle ?? ""
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func toggleFavorite() {
        guard let title = eventTitle else { return }

        var favorites = UserDefaults.standard.array(forKey: "favorites") as? [String] ?? []

        if let index = favorites.firstIndex(of: title) {
            favorites.remove(at: index)
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "heart")
        } else {
            favorites.append(title)
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: "heart.fill")
        }

        UserDefaults.standard.set(favorites, forKey: "favorites")
    }

    private func isFavorite() -> Bool {
        guard let title = eventTitle else { return false }
        let favorites = UserDefaults.standard.array(forKey: "favorites") as? [String] ?? []
        return favorites.contains(title)
    }
}
