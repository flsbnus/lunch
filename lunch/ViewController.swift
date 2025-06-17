//
//  ViewController.swift
//  lunch
//
//  Created by user on 6/7/25.
//

import UIKit
import Foundation
import CoreLocation

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var recommendButton: UIButton!
    @IBOutlet weak var categorySegmentedControl: UISegmentedControl!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    
    // MARK: - Properties
    private var selectedCategory: FoodCategory = .all
    private let dataManager = DataManager.shared
    private let recommendationEngine = MenuRecommendationEngine.shared
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategorySegmentedControl()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground

        titleLabel.text = "🍽️ 오늘 뭐 먹지?"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label

        recommendButton.setTitle("메뉴 추천받기", for: .normal)
        recommendButton.backgroundColor = UIColor.systemIndigo
        recommendButton.setTitleColor(.white, for: .normal)
        recommendButton.layer.cornerRadius = 16
        recommendButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        recommendButton.layer.shadowColor = UIColor.black.cgColor
        recommendButton.layer.shadowOpacity = 0.15
        recommendButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        recommendButton.layer.shadowRadius = 8

        favoritesButton.setTitle("⭐️ 즐겨찾기", for: .normal)
        favoritesButton.backgroundColor = UIColor.systemTeal
        favoritesButton.setTitleColor(.white, for: .normal)
        favoritesButton.layer.cornerRadius = 12
        favoritesButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        favoritesButton.layer.shadowColor = UIColor.black.cgColor
        favoritesButton.layer.shadowOpacity = 0.10
        favoritesButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoritesButton.layer.shadowRadius = 6

        mapButton.setTitle("🗺️ 주변 식당", for: .normal)
        mapButton.backgroundColor = UIColor.systemOrange
        mapButton.setTitleColor(.white, for: .normal)
        mapButton.layer.cornerRadius = 12
        mapButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        mapButton.layer.shadowColor = UIColor.black.cgColor
        mapButton.layer.shadowOpacity = 0.10
        mapButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        mapButton.layer.shadowRadius = 6
    }
    
    private func setupCategorySegmentedControl() {
        categorySegmentedControl.removeAllSegments()
        let categories: [FoodCategory] = [.all, .korean, .chinese, .japanese, .western, .fastFood, .cafe]
        for (index, category) in categories.enumerated() {
            categorySegmentedControl.insertSegment(withTitle: "\(category.emoji)", at: index, animated: false)
        }
        categorySegmentedControl.selectedSegmentIndex = 0
        categorySegmentedControl.backgroundColor = UIColor.secondarySystemGroupedBackground
        categorySegmentedControl.selectedSegmentTintColor = UIColor.systemIndigo
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label,
                                   NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .medium)]
        categorySegmentedControl.setTitleTextAttributes(titleTextAttributes, for: .normal)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                                      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .semibold)]
        categorySegmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        categorySegmentedControl.apportionsSegmentWidthsByContent = true
        selectedCategory = .all
    }
    
    // MARK: - Actions
    @IBAction func recommendButtonTapped(_ sender: UIButton) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            showAlert(title: "위치 권한 필요", message: "메뉴 추천을 위해 위치 권한이 필요합니다.")
        }
    }
    
    @IBAction func categoryChanged(_ sender: UISegmentedControl) {
        let categories: [FoodCategory] = [.all, .korean, .chinese, .japanese, .western, .fastFood, .cafe]
        selectedCategory = categories[sender.selectedSegmentIndex]
    }
    
    @IBAction func favoritesButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showFavorites", sender: nil)
    }
    
    @IBAction func mapButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showMap", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResult",
           let resultVC = segue.destination as? ResultViewController,
           let restaurant = sender as? Restaurant {
            resultVC.recommendedRestaurant = restaurant
            resultVC.currentLocation = self.currentLocation
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            showAlert(title: "위치 오류", message: "위치 정보를 가져올 수 없습니다.")
            return
        }
        // 현재 위치 콘솔 출력
        print("현재 위치: 위도 \(location.coordinate.latitude), 경도 \(location.coordinate.longitude)")
        currentLocation = location.coordinate
        Task {
            // 7km 반경 음식점 데이터 받아오기
            let restaurants: [Restaurant]
            do {
                restaurants = try await DataManager.shared.recommendRestaurantsByLocation(currentLocation: location.coordinate, radius: 7000, category: self.selectedCategory)
            } catch {
                await MainActor.run {
                    self.showAlert(title: "추천 실패", message: "API 호출에 실패했습니다.")
                }
                return
            }
            // [카테고리별 필터링 추가]
            let filteredRestaurants: [Restaurant]
            if self.selectedCategory == .all {
                filteredRestaurants = restaurants
            } else {
                filteredRestaurants = restaurants.filter { $0.category == self.selectedCategory }
            }
            // 음식점 하나를 랜덤으로 추천
            guard let randomRestaurant = filteredRestaurants.randomElement() else {
                await MainActor.run {
                    self.showAlert(title: "추천 실패", message: "근처에 추천할 음식점이 없습니다.")
                }
                return
            }
            await MainActor.run {
                // 음식점 정보만 전달
                self.performSegue(withIdentifier: "showResult", sender: randomRestaurant)
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showAlert(title: "위치 오류", message: "위치 정보를 가져올 수 없습니다.")
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}

