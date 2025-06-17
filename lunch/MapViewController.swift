import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var categoryFilterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var locationButton: UIButton!
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let dataManager = DataManager.shared
    private var restaurants: [Restaurant] = []
    private var selectedCategory: FoodCategory = .all
    private var searchResults: [KakaoPlace] = []
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        setupMapView()
        setupLocationManager()
        setupUI()
        setupSearchController()
        loadRestaurantsFromAPI()
        setupCategoryFilter()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "🗺️ 주변 식당"
        
        locationButton.setTitle("📍 내 위치", for: .normal)
        locationButton.backgroundColor = UIColor.systemIndigo
        locationButton.setTitleColor(.white, for: .normal)
        locationButton.layer.cornerRadius = 16
        locationButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        locationButton.layer.shadowColor = UIColor.black.cgColor
        locationButton.layer.shadowOpacity = 0.12
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        locationButton.layer.shadowRadius = 6
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // 기본 위치 설정 (서울 시청)
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let region = MKCoordinateRegion(center: defaultLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    private func setupCategoryFilter() {
        categoryFilterSegmentedControl.removeAllSegments()
        
        let categories: [FoodCategory] = [.all, .korean, .chinese, .japanese, .western, .fastFood, .cafe]
        for (index, category) in categories.enumerated() {
            categoryFilterSegmentedControl.insertSegment(withTitle: "\(category.emoji)", at: index, animated: false)
        }
        
        categoryFilterSegmentedControl.selectedSegmentIndex = 0
        categoryFilterSegmentedControl.backgroundColor = UIColor.secondarySystemGroupedBackground
        categoryFilterSegmentedControl.selectedSegmentTintColor = UIColor.systemIndigo
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        categoryFilterSegmentedControl.setTitleTextAttributes(titleTextAttributes, for: .normal)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        categoryFilterSegmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        selectedCategory = .all
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "음식점 검색"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func loadRestaurantsFromAPI() {
        guard let location = locationManager.location?.coordinate else { return }
        // 카테고리에 따라 검색어 설정
        let keyword: String
        switch selectedCategory {
        case .korean: keyword = "한식"
        case .chinese: keyword = "중식"
        case .japanese: keyword = "일식"
        case .western: keyword = "양식"
        case .fastFood: keyword = "패스트푸드"
        case .cafe: keyword = "카페"
        default: keyword = "음식점"
        }
        Task {
            do {
                let places = try await KakaoLocalService.shared.searchPlaces(
                    keyword: keyword,
                    category: nil,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    radius: 1000
                )
                await MainActor.run {
                    self.restaurants = places.map { place in
                        Restaurant(
                            name: place.placeName,
                            latitude: Double(place.y) ?? 0,
                            longitude: Double(place.x) ?? 0,
                            category: foodCategory(from: place.categoryName),
                            address: place.addressName,
                            phoneNumber: place.phone,
                            menu: self.generateMenuForCategory(place.categoryGroupCode)
                        )
                    }
                    self.displayRestaurants()
                }
            } catch {
                print("카카오 API 연동 실패: \(error)")
            }
        }
    }
    
    private func displayRestaurants() {
        // 기존 어노테이션 제거
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // 카테고리에 따라 필터링
        let filteredRestaurants = selectedCategory == .all ? restaurants : restaurants.filter { $0.category == selectedCategory }
        
        // 새 어노테이션 추가
        for restaurant in filteredRestaurants {
            let annotation = RestaurantAnnotation(restaurant: restaurant)
            mapView.addAnnotation(annotation)
        }
    }
    
    private func searchNearbyRestaurants(keyword: String? = nil, category: String? = nil) {
        guard let location = locationManager.location?.coordinate else { return }
        
        Task {
            do {
                let places = try await KakaoLocalService.shared.searchPlaces(
                    keyword: keyword ?? "",
                    category: category,
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                
                await MainActor.run {
                    self.searchResults = places
                    self.displaySearchResults()
                }
            } catch {
                print("Error searching places: \(error)")
                // 에러 처리 (사용자에게 알림 등)
            }
        }
    }
    
    private func displaySearchResults() {
        // 기존 마커 제거
        mapView.removeAnnotations(mapView.annotations)
        
        // 검색 결과를 마커로 표시
        for place in searchResults {
            let annotation = MKPointAnnotation()
            annotation.title = place.placeName
            annotation.subtitle = place.categoryName
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: Double(place.y) ?? 0,
                longitude: Double(place.x) ?? 0
            )
            mapView.addAnnotation(annotation)
        }
        
        // 검색 결과가 있다면 첫 번째 결과로 지도 이동
        if let firstPlace = searchResults.first,
           let latitude = Double(firstPlace.y),
           let longitude = Double(firstPlace.x) {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Actions
    @IBAction func categoryFilterChanged(_ sender: UISegmentedControl) {
        let categories: [FoodCategory] = [.all, .korean, .chinese, .japanese, .western, .fastFood, .cafe]
        selectedCategory = categories[sender.selectedSegmentIndex]
        loadRestaurantsFromAPI()
    }
    
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        guard CLLocationManager.locationServicesEnabled() else {
            showAlert(title: "위치 서비스 사용 불가", message: "위치 서비스를 활성화해주세요.")
            return
        }
        
        locationManager.requestLocation()
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func generateMenuForCategory(_ category: String) -> [Menu] {
        switch category {
        case "FD6": // 한식
            return [
                Menu(name: "김치찌개", category: .korean, description: "매콤한 김치찌개", imageURL: nil),
                Menu(name: "된장찌개", category: .korean, description: "구수한 된장찌개", imageURL: nil),
                Menu(name: "비빔밥", category: .korean, description: "건강한 비빔밥", imageURL: nil)
            ]
        case "FD7": // 중식
            return [
                Menu(name: "짜장면", category: .chinese, description: "고소한 짜장면", imageURL: nil),
                Menu(name: "짬뽕", category: .chinese, description: "얼큰한 짬뽕", imageURL: nil),
                Menu(name: "탕수육", category: .chinese, description: "바삭한 탕수육", imageURL: nil)
            ]
        case "FD8": // 일식
            return [
                Menu(name: "초밥", category: .japanese, description: "신선한 초밥", imageURL: nil),
                Menu(name: "라멘", category: .japanese, description: "진한 국물 라멘", imageURL: nil),
                Menu(name: "돈카츠", category: .japanese, description: "바삭한 돈카츠", imageURL: nil)
            ]
        case "FD9": // 양식
            return [
                Menu(name: "파스타", category: .western, description: "크리미한 파스타", imageURL: nil),
                Menu(name: "피자", category: .western, description: "치즈 가득 피자", imageURL: nil),
                Menu(name: "스테이크", category: .western, description: "부드러운 스테이크", imageURL: nil)
            ]
        case "FD4": // 패스트푸드
            return [
                Menu(name: "햄버거", category: .fastFood, description: "맛있는 햄버거", imageURL: nil),
                Menu(name: "치킨", category: .fastFood, description: "바삭한 치킨", imageURL: nil),
                Menu(name: "피자", category: .fastFood, description: "치즈 가득 피자", imageURL: nil)
            ]
        case "CE7": // 카페
            return [
                Menu(name: "아메리카노", category: .cafe, description: "깔끔한 아메리카노", imageURL: nil),
                Menu(name: "카페라떼", category: .cafe, description: "부드러운 카페라떼", imageURL: nil),
                Menu(name: "카푸치노", category: .cafe, description: "크리미한 카푸치노", imageURL: nil)
            ]
        default:
            return []
        }
    }
    
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

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showAlert(title: "위치 오류", message: "현재 위치를 가져올 수 없습니다.")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            showAlert(title: "위치 권한 필요", message: "지도 기능을 사용하려면 위치 권한이 필요합니다.")
        default:
            break
        }
    }
}

// MARK: - UISearchResultsUpdating
extension MapViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            return
        }
        searchNearbyRestaurants(keyword: searchText)
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let identifier = "RestaurantAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // 상세 정보 버튼 추가
            let detailButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = detailButton
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("calloutAccessoryControlTapped 호출됨")
        guard let annotation = view.annotation else {
            print("annotation이 nil임")
            return
        }
        print("annotation.title: \(annotation.title ?? "nil")")
        print("searchResults placeNames: \(searchResults.map { $0.placeName })")
        // 1. searchResults에서 찾기
        if let place = searchResults.first(where: { $0.placeName == annotation.title }) {
            print("place 찾음: \(place.placeName)")
            // 거리 계산 (현재 위치와의 거리)
            var distanceString = "-"
            if let userLocation = mapView.userLocation.location,
               let lat = Double(place.y), let lon = Double(place.x) {
                let placeLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = userLocation.distance(from: placeLocation)
                if distance >= 1000 {
                    distanceString = String(format: "%.1fkm", distance/1000)
                } else {
                    distanceString = String(format: "%.0fm", distance)
                }
            }
            let favorites = DataManager.shared.loadFavorites()
            let isFavorite = favorites.contains(where: { $0.restaurantName == place.placeName })
            let kakaoMapURL = "https://place.map.kakao.com/" + place.id
            let phoneURL = "tel://" + place.phone.filter { $0.isNumber }
            let message = """
🏷️ 카테고리: \(place.categoryName)
📍 주소: \(place.roadAddressName.isEmpty ? place.addressName : place.roadAddressName)
📞 전화번호: \(place.phone.isEmpty ? "-" : place.phone)
📏 거리: \(distanceString)
"""
            let alert = UIAlertController(title: "🍽️  \(place.placeName)", message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "카카오맵으로 열기", style: .default, handler: { _ in
                if let url = URL(string: kakaoMapURL) {
                    UIApplication.shared.open(url)
                }
            }))
            if !place.phone.isEmpty, let url = URL(string: phoneURL), UIApplication.shared.canOpenURL(url) {
                alert.addAction(UIAlertAction(title: "전화걸기", style: .default, handler: { _ in
                    UIApplication.shared.open(url)
                }))
            }
            let favoriteTitle = isFavorite ? "⭐️ 즐겨찾기 제거" : "⭐️ 즐겨찾기 추가"
            alert.addAction(UIAlertAction(title: favoriteTitle, style: .default, handler: { _ in
                let favorite = Favorite(menuName: place.placeName, restaurantName: place.placeName, category: .all, dateAdded: Date())
                if isFavorite {
                    DataManager.shared.removeFavorite(favorite)
                } else {
                    DataManager.shared.addFavorite(favorite)
                }
            }))
            alert.addAction(UIAlertAction(title: "공유", style: .default, handler: { _ in
                let shareText = "[\(place.placeName)]\n\(place.roadAddressName.isEmpty ? place.addressName : place.roadAddressName)\n\(place.phone)\n\(kakaoMapURL)"
                let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = self.view
                    popover.sourceRect = view.frame
                }
                self.present(activityVC, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = view.frame
            }
            present(alert, animated: true)
            return
        }
        // 2. restaurants에서 찾기
        if let restaurant = restaurants.first(where: { $0.name == annotation.title }) {
            print("restaurant 찾음: \(restaurant.name)")
            // 거리 계산 (현재 위치와의 거리)
            var distanceString = "-"
            if let userLocation = mapView.userLocation.location {
                let placeLocation = CLLocation(latitude: restaurant.latitude, longitude: restaurant.longitude)
                let distance = userLocation.distance(from: placeLocation)
                if distance >= 1000 {
                    distanceString = String(format: "%.1fkm", distance/1000)
                } else {
                    distanceString = String(format: "%.0fm", distance)
                }
            }
            let favorites = DataManager.shared.loadFavorites()
            let isFavorite = favorites.contains(where: { $0.restaurantName == restaurant.name })
            let phoneURL = "tel://" + (restaurant.phoneNumber ?? "").filter { $0.isNumber }
            let message = """
🏷️ 카테고리: \(restaurant.category.emoji) \(restaurant.category.rawValue)
📍 주소: \(restaurant.address)
📞 전화번호: \(restaurant.phoneNumber ?? "-")
📏 거리: \(distanceString)
"""
            let alert = UIAlertController(title: "🍽️  \(restaurant.name)", message: message, preferredStyle: .actionSheet)
            // 전화걸기
            if let phone = restaurant.phoneNumber, !phone.isEmpty, let url = URL(string: phoneURL), UIApplication.shared.canOpenURL(url) {
                alert.addAction(UIAlertAction(title: "전화걸기", style: .default, handler: { _ in
                    UIApplication.shared.open(url)
                }))
            }
            // 즐겨찾기 추가/제거
            let favoriteTitle = isFavorite ? "⭐️ 즐겨찾기 제거" : "⭐️ 즐겨찾기 추가"
            alert.addAction(UIAlertAction(title: favoriteTitle, style: .default, handler: { _ in
                let favorite = Favorite(menuName: restaurant.name, restaurantName: restaurant.name, category: restaurant.category, dateAdded: Date())
                if isFavorite {
                    DataManager.shared.removeFavorite(favorite)
                } else {
                    DataManager.shared.addFavorite(favorite)
                }
            }))
            // 공유
            alert.addAction(UIAlertAction(title: "공유", style: .default, handler: { _ in
                let shareText = "[\(restaurant.name)]\n\(restaurant.address)\n\(restaurant.phoneNumber ?? "-")"
                let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = self.view
                    popover.sourceRect = view.frame
                }
                self.present(activityVC, animated: true)
            }))
            // 닫기
            alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = view.frame
            }
            present(alert, animated: true)
            return
        }
        print("place/restaurant를 찾지 못함")
    }
}

// MARK: - RestaurantAnnotation
class RestaurantAnnotation: NSObject, MKAnnotation {
    let restaurant: Restaurant
    
    var coordinate: CLLocationCoordinate2D {
        return restaurant.coordinate
    }
    
    var title: String? {
        return restaurant.name
    }
    
    var subtitle: String? {
        return "\(restaurant.category.emoji) \(restaurant.category.rawValue)"
    }
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        super.init()
    }
} 