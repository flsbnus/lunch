import UIKit

class FavoritesViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    // MARK: - Properties
    private var favorites: [Favorite] = []
    private let dataManager = DataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadFavorites()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "⭐️ 즐겨찾기"
        
        emptyStateLabel.text = "아직 즐겨찾기한 메뉴가 없어요!\n메뉴 추천을 받고 마음에 드는 메뉴를 추가해보세요 😊"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.isHidden = true
        
        // 네비게이션 바 설정
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "편집",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FavoriteCell")
        tableView.tableFooterView = UIView()
    }
    
    private func loadFavorites() {
        favorites = dataManager.loadFavorites().sorted { $0.dateAdded > $1.dateAdded }
        updateUI()
    }
    
    private func updateUI() {
        let isEmpty = favorites.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if !isEmpty {
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc private func editButtonTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.rightBarButtonItem?.title = tableView.isEditing ? "완료" : "편집"
    }
    
    private func deleteFavorite(at indexPath: IndexPath) {
        let favorite = favorites[indexPath.row]
        
        let alert = UIAlertController(
            title: "즐겨찾기 삭제",
            message: "\(favorite.menuName)을(를) 즐겨찾기에서 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            self.dataManager.removeFavorite(favorite)
            self.favorites.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.updateUI()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        let favorite = favorites[indexPath.row]
        
        cell.textLabel?.text = favorite.menuName
        cell.detailTextLabel?.text = "\(favorite.category.emoji) \(favorite.category.rawValue) • \(favorite.restaurantName)"
        
        // 날짜 표시
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        cell.accessoryType = .none
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let favorite = favorites[indexPath.row]
        
        let alert = UIAlertController(
            title: favorite.menuName,
            message: """
            카테고리: \(favorite.category.emoji) \(favorite.category.rawValue)
            식당: \(favorite.restaurantName)
            추가일: \(DateFormatter.localizedString(from: favorite.dateAdded, dateStyle: .medium, timeStyle: .none))
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFavorite(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "삭제"
    }
} 
