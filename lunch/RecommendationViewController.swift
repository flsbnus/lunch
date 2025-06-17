import UIKit

class RecommendationViewController: UIViewController {
    private var recommendedRestaurants: [Restaurant] = []
    var selectedCategory: FoodCategory = .all
    
    @IBOutlet weak var recommendationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecommendations()
    }
    
    private func setupUI() {
        title = "🍱 점심 메뉴 추천"
        recommendationLabel.text = "오늘의 점심 메뉴를 추천해드릴게요!"
        recommendationLabel.textAlignment = .center
        recommendationLabel.font = UIFont.boldSystemFont(ofSize: 22)
        recommendationLabel.numberOfLines = 0
    }
    
    private func loadRecommendations() {
        Task {
            do {
                // 카테고리별 추천 음식점 가져오기
                let restaurants = try await DataManager.shared.recommendRestaurants(category: selectedCategory)
                await MainActor.run {
                    self.recommendedRestaurants = restaurants
                    self.updateRecommendation()
                }
            } catch {
                print("Error loading recommendations: \(error)")
                // 에러 처리 (사용자에게 알림 등)
            }
        }
    }
    
    private func updateRecommendation() {
        guard !recommendedRestaurants.isEmpty else {
            recommendationLabel.text = "추천할 음식점이 없습니다."
            return
        }
        
        // 랜덤으로 음식점과 메뉴 선택
        let randomRestaurant = recommendedRestaurants.randomElement()!
        let randomMenu = randomRestaurant.menu.randomElement()!
        
        // 추천 메시지 생성
        let message = """
            오늘의 추천 메뉴는 \(randomRestaurant.name)의 \(randomMenu.name)입니다!
            
            주소: \(randomRestaurant.address)
            전화번호: \(randomRestaurant.phoneNumber ?? "정보 없음")
            """
        
        recommendationLabel.text = message
    }
} 