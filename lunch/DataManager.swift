import Foundation
import CoreLocation

// MARK: - Menu Model
struct Menu: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: FoodCategory
    let description: String
    let imageURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, category, description, imageURL
    }
}

// MARK: - Restaurant Model  
struct Restaurant: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let category: FoodCategory
    let address: String
    let phoneNumber: String?
    let menu: [Menu]
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, category, address, phoneNumber, menu
    }
}

// MARK: - Food Category
enum FoodCategory: String, CaseIterable, Codable {
    case korean = "한식"
    case chinese = "중식"
    case japanese = "일식"
    case western = "양식"
    case fastFood = "패스트푸드"
    case cafe = "카페"
    case dessert = "디저트"
    case all = "전체"
    
    var emoji: String {
        switch self {
        case .korean: return "🍚"
        case .chinese: return "🥢"
        case .japanese: return "🍣"
        case .western: return "🍝"
        case .fastFood: return "🍔"
        case .cafe: return "☕️"
        case .dessert: return "🍰"
        case .all: return "🍽️"
        }
    }
}

// MARK: - Favorite Model
struct Favorite: Codable, Identifiable, Equatable {
    let id = UUID()
    let menuName: String
    let restaurantName: String
    let category: FoodCategory
    let dateAdded: Date
    
    private enum CodingKeys: String, CodingKey {
        case menuName, restaurantName, category, dateAdded
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var favoriteCategories: [FoodCategory]
    var recentRecommendations: [Menu]
    var maxRecentCount: Int = 10
    
    init() {
        self.favoriteCategories = []
        self.recentRecommendations = []
    }
}

class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private let favoritesFileName = "favorites.json"
    private let preferencesFileName = "preferences.json"
    private let restaurantsFileName = "restaurants.json"
    private let restaurantsKey = "restaurants"
    private let favoritesKey = "favorites"
    
    private init() {
        _ = loadFavorites()
    }
    
    // MARK: - File URL Methods
    private func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func fileURL(for fileName: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    // MARK: - Favorites Management
    func saveFavorites(_ favorites: [Favorite]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            let fileURL = fileURL(for: favoritesFileName)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving favorites: \(error)")
        }
    }
    
    func loadFavorites() -> [Favorite] {
        do {
            let fileURL = fileURL(for: favoritesFileName)
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Favorite].self, from: data)
        } catch {
            print("Error loading favorites: \(error)")
            return []
        }
    }
    
    func addFavorite(_ favorite: Favorite) {
        var favorites = loadFavorites()
        if !favorites.contains(where: { $0.menuName == favorite.menuName && $0.restaurantName == favorite.restaurantName }) {
            favorites.append(favorite)
            saveFavorites(favorites)
        }
    }
    
    func removeFavorite(_ favorite: Favorite) {
        var favorites = loadFavorites()
        favorites.removeAll { $0.menuName == favorite.menuName && $0.restaurantName == favorite.restaurantName }
        saveFavorites(favorites)
    }
    
    // MARK: - User Preferences Management
    func savePreferences(_ preferences: UserPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: fileURL(for: preferencesFileName))
        } catch {
            print("Error saving preferences: \(error)")
        }
    }
    
    func loadPreferences() -> UserPreferences {
        do {
            let data = try Data(contentsOf: fileURL(for: preferencesFileName))
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            print("Error loading preferences: \(error)")
            return UserPreferences()
        }
    }
    
    // MARK: - Restaurants Data
    // 더 이상 내부 음식점 데이터는 사용하지 않고, 카카오 API에서만 가져옴
    func loadRestaurants(currentLocation: CLLocationCoordinate2D, radius: Int = 1000) async throws -> [Restaurant] {
        return try await recommendRestaurantsByLocation(currentLocation: currentLocation, radius: radius)
    }
    
    // 카카오 API를 활용한 음식점 추천
    func recommendRestaurants(category: FoodCategory? = nil) async throws -> [Restaurant] {
        // 현재 위치 가져오기 (시뮬레이터의 경우 서울시청 좌표 사용)
        let location = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let categoryCode: String? = {
            guard let category = category else { return nil }
            switch category {
            case .korean: return "FD6"
            case .chinese: return "FD7"
            case .japanese: return "FD8"
            case .western: return "FD9"
            case .fastFood: return "FD4"
            case .cafe: return "CE7"
            case .dessert: return "FD6"
            case .all: return nil
            }
        }()
        let places = try await KakaoLocalService.shared.searchPlaces(
            keyword: "",
            category: categoryCode,
            latitude: location.latitude,
            longitude: location.longitude,
            radius: 1000
        )
        return places.map { place in
            Restaurant(
                name: place.placeName,
                latitude: Double(place.y) ?? 0,
                longitude: Double(place.x) ?? 0,
                category: .all,
                address: place.addressName,
                phoneNumber: place.phone,
                menu: []
            )
        }
    }
    
    /// 현재 위치 기반으로 가까운 음식점의 대표 메뉴를 랜덤 추천
    func recommendNearbyMenu(currentLocation: CLLocationCoordinate2D, radius: Int = 1000) async throws -> (restaurant: Restaurant, menu: Menu)? {
        let places = try await KakaoLocalService.shared.searchPlaces(
            keyword: "음식점",
            category: nil,
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
            radius: radius
        )
        guard let place = places.randomElement() else { return nil }
        // 메뉴 없이 Restaurant만 반환
        let restaurant = Restaurant(
            name: place.placeName,
            latitude: Double(place.y) ?? 0,
            longitude: Double(place.x) ?? 0,
            category: .all,
            address: place.addressName,
            phoneNumber: place.phone,
            menu: []
        )
        return (restaurant, Menu(name: "", category: .all, description: "", imageURL: nil)) // menu는 빈 값
    }
    
    /// 현재 위치와 반경을 받아 카카오 API로 음식점 리스트를 반환
    func recommendRestaurantsByLocation(currentLocation: CLLocationCoordinate2D, radius: Int = 1000, category: FoodCategory = .all) async throws -> [Restaurant] {
        // 카테고리에 따라 검색어 설정
        let keyword: String
        switch category {
        case .korean: keyword = "한식"
        case .chinese: keyword = "중식"
        case .japanese: keyword = "일식"
        case .western: keyword = "양식"
        case .fastFood: keyword = "패스트푸드"
        case .cafe: keyword = "카페"
        default: keyword = "음식점"
        }
        // 카카오 API는 한 번에 최대 15개만 반환하므로, page=1,2를 합쳐 30개까지 반환
        var allPlaces: [KakaoPlace] = []
        for page in 1...2 {
            let places = try await KakaoLocalService.shared.searchPlacesWithPage(
                keyword: keyword,
                category: nil,
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
                radius: radius,
                page: page,
                size: 15
            )
            allPlaces.append(contentsOf: places)
        }
        return allPlaces.map { place in
            Restaurant(
                name: place.placeName,
                latitude: Double(place.y) ?? 0,
                longitude: Double(place.x) ?? 0,
                category: foodCategory(from: place.categoryName),
                address: place.addressName,
                phoneNumber: place.phone,
                menu: []
            )
        }
    }

    // 카카오 categoryName에서 FoodCategory 추출
    private func foodCategory(from categoryName: String) -> FoodCategory {
        if categoryName.contains("한식") { return .korean }
        if categoryName.contains("중식") { return .chinese }
        if categoryName.contains("일식") { return .japanese }
        if categoryName.contains("양식") { return .western }
        if categoryName.contains("패스트푸드") { return .fastFood }
        if categoryName.contains("카페") { return .cafe }
        if categoryName.contains("디저트") { return .dessert }
        return .all
    }
} 
