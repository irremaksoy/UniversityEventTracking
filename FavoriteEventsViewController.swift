import UIKit

class FavoriteEventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var favoriteTitles: [String] = []

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

        view.backgroundColor = UIColor(red: 230/255, green: 237/255, blue: 255/255, alpha: 1.0)

        setupViews()
        loadFavorites()
    }

    private func setupViews() {
        view.addSubview(refreshButton)
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

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
        loadFavorites()
        showToast("Liste yenilendi")
    }

    private func loadFavorites() {
        favoriteTitles = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteTitles.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = "favoriteCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) ?? UITableViewCell(style: .default, reuseIdentifier: reuseId)

        let title = favoriteTitles[indexPath.row]
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let horizontalMargin: CGFloat = 50  // Yanlardan daralt
        let verticalOffset: CGFloat = 100     // Hafif yukarı boşluk

        let cardWidth = tableView.frame.width - (horizontalMargin * 2)
        let cardView = UIView(frame: CGRect(x: horizontalMargin, y: verticalOffset, width: cardWidth, height: 100))
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6

        let iconView = UIImageView(frame: CGRect(x: 12, y: 30, width: 40, height: 40))
        iconView.image = UIImage(systemName: "star.fill")
        iconView.tintColor = .systemYellow
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true

        let titleLabel = UILabel(frame: CGRect(x: 64, y: 25, width: cardView.frame.width - 80, height: 24))
        titleLabel.text = title.isEmpty ? "Başlıksız" : title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label

        let subLabel = UILabel(frame: CGRect(x: 64, y: 54, width: cardView.frame.width - 80, height: 20))
        subLabel.text = "Favori etkinlik"
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
