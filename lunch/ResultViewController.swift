import UIKit
import Foundation
import CoreLocation

class ResultViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuNameLabel: UILabel!
    @IBOutlet weak var menuDescriptionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var addToFavoritesButton: UIButton!
    @IBOutlet weak var recommendAgainButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Properties
    var recommendedRestaurant: Restaurant?
    var currentLocation: CLLocationCoordinate2D?
    private let dataManager = DataManager.shared
    private let recommendationEngine = MenuRecommendationEngine.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayRecommendedMenu()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        titleLabel.text = "🎉 오늘의 점심은..."
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        addToFavoritesButton.setTitle("⭐️ 즐겨찾기 추가", for: .normal)
        addToFavoritesButton.backgroundColor = UIColor.systemOrange
        addToFavoritesButton.setTitleColor(.white, for: .normal)
        addToFavoritesButton.layer.cornerRadius = 8
        
        recommendAgainButton.setTitle("🔄 다시 추천", for: .normal)
        recommendAgainButton.backgroundColor = UIColor.systemBlue
        recommendAgainButton.setTitleColor(.white, for: .normal)
        recommendAgainButton.layer.cornerRadius = 8
        
        backButton.setTitle("← 돌아가기", for: .normal)
        backButton.backgroundColor = UIColor.systemGray
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 8
    }
    
    private func displayRecommendedMenu() {
        guard let restaurant = recommendedRestaurant else { return }
        // 음식점 정보만 표시
        menuNameLabel.text = restaurant.name
        menuNameLabel.font = UIFont.boldSystemFont(ofSize: 32)
        menuNameLabel.textAlignment = .center
        menuDescriptionLabel.text = "주소: \(restaurant.address)\n전화번호: \(restaurant.phoneNumber ?? "-")"
        menuDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        menuDescriptionLabel.textAlignment = .center
        menuDescriptionLabel.numberOfLines = 0
        categoryLabel.text = "음식점"
        categoryLabel.font = UIFont.systemFont(ofSize: 18)
        categoryLabel.textAlignment = .center
    }
    
    // MARK: - Actions
    @IBAction func addToFavoritesButtonTapped(_ sender: UIButton) {
        guard let restaurant = recommendedRestaurant else { return }
        let favorite = Favorite(
            menuName: restaurant.name,
            restaurantName: restaurant.name,
            category: restaurant.category,
            dateAdded: Date()
        )
        dataManager.addFavorite(favorite)
        addToFavoritesButton.setTitle("✅ 추가됨", for: .normal)
        addToFavoritesButton.backgroundColor = UIColor.systemGreen
        addToFavoritesButton.isEnabled = false
        showAlert(title: "즐겨찾기 추가", message: "\(restaurant.name)이(가) 즐겨찾기에 추가되었습니다.")
    }
    
    @IBAction func recommendAgainButtonTapped(_ sender: UIButton) {
        // 메인 화면으로 돌아가서 다시 추천
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
} 