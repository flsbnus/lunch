import Foundation
import CoreLocation

class MenuRecommendationEngine {
    static let shared = MenuRecommendationEngine()
    
    private let dataManager = DataManager.shared
    private init() {}
    
    // MARK: - Recommendation Methods
    func recommendMenu(for category: FoodCategory = .all, currentLocation: CLLocationCoordinate2D, excludeRecent: Bool = true) async -> Menu? {
        guard let restaurants = try? await dataManager.loadRestaurants(currentLocation: currentLocation) else { return nil }
        var availableMenus: [Menu] = []
        
        // 카테고리에 따라 메뉴 필터링
        if category == .all {
            availableMenus = restaurants.flatMap { $0.menu }
        } else {
            availableMenus = restaurants.flatMap { restaurant in
                restaurant.menu.filter { $0.category == category }
            }
        }
        
        // 최근 추천 메뉴 제외 (선택적)
        if excludeRecent {
            let preferences = dataManager.loadPreferences()
            let recentMenuNames = Set(preferences.recentRecommendations.map { $0.name })
            availableMenus = availableMenus.filter { !recentMenuNames.contains($0.name) }
        }
        
        // 메뉴가 없으면 모든 메뉴에서 선택
        if availableMenus.isEmpty {
            availableMenus = restaurants.flatMap { restaurant in
                category == .all ? restaurant.menu : restaurant.menu.filter { $0.category == category }
            }
        }
        
        guard !availableMenus.isEmpty else { return nil }
        
        // 랜덤 선택
        let selectedMenu = availableMenus.randomElement()!
        
        // 추천 기록 저장
        saveRecommendationHistory(selectedMenu)
        
        return selectedMenu
    }
    
    func recommendMenuByPreference(currentLocation: CLLocationCoordinate2D) async -> Menu? {
        let preferences = dataManager.loadPreferences()
        
        // 즐겨하는 카테고리가 있으면 그 중에서 선택
        if let randomCategory = preferences.favoriteCategories.randomElement() {
            return await recommendMenu(for: randomCategory, currentLocation: currentLocation)
        }
        // 그렇지 않으면 전체에서 선택
        return await recommendMenu(for: .all, currentLocation: currentLocation)
    }
    
    func getPopularMenus(currentLocation: CLLocationCoordinate2D, limit: Int = 5) async -> [Menu] {
        guard let restaurants = try? await dataManager.loadRestaurants(currentLocation: currentLocation) else { return [] }
        let allMenus = restaurants.flatMap { $0.menu }
        return Array(allMenus.shuffled().prefix(limit))
    }
    
    func getMenusByCategory(_ category: FoodCategory, currentLocation: CLLocationCoordinate2D) async -> [Menu] {
        guard let restaurants = try? await dataManager.loadRestaurants(currentLocation: currentLocation) else { return [] }
        if category == .all {
            return restaurants.flatMap { $0.menu }
        } else {
            return restaurants.flatMap { restaurant in
                restaurant.menu.filter { $0.category == category }
            }
        }
    }
    
    func findRestaurantForMenu(_ menu: Menu, currentLocation: CLLocationCoordinate2D) async -> Restaurant? {
        guard let restaurants = try? await dataManager.loadRestaurants(currentLocation: currentLocation) else { return nil }
        return restaurants.first { restaurant in
            restaurant.menu.contains { $0.name == menu.name }
        }
    }
    
    // MARK: - History Management
    private func saveRecommendationHistory(_ menu: Menu) {
        var preferences = dataManager.loadPreferences()
        
        // 중복 제거
        preferences.recentRecommendations.removeAll { $0.name == menu.name }
        
        // 최신 항목을 맨 앞에 추가
        preferences.recentRecommendations.insert(menu, at: 0)
        
        // 최대 개수 제한
        if preferences.recentRecommendations.count > preferences.maxRecentCount {
            preferences.recentRecommendations = Array(preferences.recentRecommendations.prefix(preferences.maxRecentCount))
        }
        
        dataManager.savePreferences(preferences)
    }
    
    func getRecommendationHistory() -> [Menu] {
        return dataManager.loadPreferences().recentRecommendations
    }
    
    func clearRecommendationHistory() {
        var preferences = dataManager.loadPreferences()
        preferences.recentRecommendations.removeAll()
        dataManager.savePreferences(preferences)
    }
    
    // MARK: - Statistics
    func getRecommendationStats() -> [FoodCategory: Int] {
        let history = getRecommendationHistory()
        var stats: [FoodCategory: Int] = [:]
        
        for menu in history {
            stats[menu.category, default: 0] += 1
        }
        
        return stats
    }
    
    func getMostRecommendedCategory() -> FoodCategory? {
        let stats = getRecommendationStats()
        return stats.max(by: { $0.value < $1.value })?.key
    }
} 