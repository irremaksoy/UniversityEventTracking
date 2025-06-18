import UIKit
import FirebaseFirestore

struct EventModel {
    let title: String
    let date: Date
    let description: String
    let location: String
}


class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationSegmentedControl: UISegmentedControl!
    
    @IBAction func profileTapped(_ sender: UITapGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
          let settingsVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController")
          settingsVC.modalPresentationStyle = .fullScreen
          self.present(settingsVC, animated: true)
    }
 

        var events: [EventModel] = []
        var filteredEvents: [EventModel] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            tableView.delegate = self
            tableView.dataSource = self
            searchBar.delegate = self
            locationSegmentedControl.selectedSegmentIndex = 0

            tableView.separatorStyle = .none
            tableView.backgroundColor = UIColor.clear
            view.backgroundColor = UIColor(red: 230/255, green: 237/255, blue: 255/255, alpha: 1.0)

            fetchEventsFromFirebase()
        }

        func fetchEventsFromFirebase() {
            let db = Firestore.firestore()
            db.collection("events").getDocuments { snapshot, error in
                if let error = error {
                    print("Hata: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.events = documents.compactMap { doc in
                    let data = doc.data()
                    let title = data["title"] as? String ?? "Başlıksız"
                    let description = data["description"] as? String ?? ""
                    let location = data["location"] as? String ?? ""
                    guard let timestamp = data["date"] as? Timestamp else { return nil }
                    let date = timestamp.dateValue()
                    return EventModel(title: title, date: date, description: description, location: location)
                }

                self.filteredEvents = self.events
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }

        @IBAction func locationSegmentChanged(_ sender: UISegmentedControl) {
            filterByLocationAndSearch()
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            filterByLocationAndSearch()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func filterByLocationAndSearch() {
            let searchText = searchBar.text ?? ""
            let selectedIndex = locationSegmentedControl.selectedSegmentIndex
            let selectedLocation = locationSegmentedControl.titleForSegment(at: selectedIndex)

            filteredEvents = events.filter { event in
                let matchesSearch = searchText.isEmpty ||
                    event.title.lowercased().contains(searchText.lowercased()) ||
                    event.description.lowercased().contains(searchText.lowercased())

                let matchesLocation = selectedLocation == "Tümü" ||
                    event.location.lowercased().contains(selectedLocation!.lowercased())

                return matchesSearch && matchesLocation
            }

            tableView.reloadData()
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filteredEvents.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let event = filteredEvents[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

            let cardView = UIView(frame: CGRect(x: 16, y: 10, width: tableView.frame.width - 32, height: 80))
            cardView.backgroundColor = .white
            cardView.layer.cornerRadius = 12
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOpacity = 0.1
            cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
            cardView.layer.shadowRadius = 4

            let dateView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 80))
            dateView.backgroundColor = UIColor(white: 0.95, alpha: 1)
            dateView.layer.cornerRadius = 12

            let dateLabel = UILabel(frame: CGRect(x: 0, y: 10, width: 60, height: 60))
            dateLabel.text = formatDateForCard(event.date)
            dateLabel.font = UIFont.boldSystemFont(ofSize: 16)
            dateLabel.textAlignment = .center
            dateLabel.numberOfLines = 2

            dateView.addSubview(dateLabel)
            cardView.addSubview(dateView)

            let titleLabel = UILabel(frame: CGRect(x: 70, y: 10, width: cardView.frame.width - 150, height: 20))
            titleLabel.text = event.title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)

            let descriptionLabel = UILabel(frame: CGRect(x: 70, y: 35, width: cardView.frame.width - 150, height: 30))
            descriptionLabel.text = event.description
            descriptionLabel.font = UIFont.systemFont(ofSize: 13)
            descriptionLabel.textColor = .darkGray
            descriptionLabel.numberOfLines = 2

            let detailButton = UIButton(type: .system)
            detailButton.frame = CGRect(x: cardView.frame.width - 70, y: 25, width: 60, height: 30)
            detailButton.setTitle("Detay", for: .normal)
            detailButton.setTitleColor(.white, for: .normal)
            detailButton.backgroundColor = UIColor.systemBlue
            detailButton.layer.cornerRadius = 8
            detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            detailButton.tag = indexPath.row
            detailButton.addTarget(self, action: #selector(detailTapped(_:)), for: .touchUpInside)

            cardView.addSubview(titleLabel)
            cardView.addSubview(descriptionLabel)
            cardView.addSubview(detailButton)

            cell.contentView.addSubview(cardView)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none

            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedEvent = filteredEvents[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
                detailVC.eventTitle = selectedEvent.title
                detailVC.eventDate = formatDateFull(selectedEvent.date)
                detailVC.eventLocation = selectedEvent.location
                detailVC.eventDescription = selectedEvent.description
                detailVC.eventImage = UIImage(named: "etkinlikDefault")
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }

        @objc func detailTapped(_ sender: UIButton) {
            let event = filteredEvents[sender.tag]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
                detailVC.eventTitle = event.title
                detailVC.eventDate = formatDateFull(event.date)
                detailVC.eventLocation = event.location
                detailVC.eventDescription = event.description
                detailVC.eventImage = UIImage(named: "etkinlikDefault")
                navigationController?.pushViewController(detailVC, animated: true)
            }
        }

        func formatDateForCard(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM\ndd"
            return formatter.string(from: date)
        }

        func formatDateFull(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMMM yyyy, HH:mm"
            return formatter.string(from: date)
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 100
        }
    }
