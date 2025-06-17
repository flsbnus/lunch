# 🍽️ 점심 메뉴 추천 앱 (Lunch Menu Recommendation App)

매일 점심 메뉴 고민하는 직장인, 대학생을 위한 iOS 앱입니다. 
"오늘 뭐 먹지?" 버튼 하나로 메뉴를 추천받고, 주변 식당을 지도에서 확인할 수 있습니다.

## 📱 주요 기능

### 1. 메뉴 추천
- **랜덤 추천**: 전체 메뉴에서 랜덤으로 추천
- **카테고리별 추천**: 한식, 중식, 일식, 양식, 패스트푸드, 카페 등
- **중복 방지**: 최근 추천된 메뉴는 제외하고 추천
- **추천 기록**: 사용자의 추천 히스토리 저장

### 2. 지도 기반 식당 탐색
- **위치 서비스**: CoreLocation을 활용한 현재 위치 파악
- **지도 표시**: MapKit을 사용한 주변 식당 표시
- **카테고리 필터**: 지도에서 특정 카테고리 식당만 보기
- **식당 정보**: 주소, 전화번호, 메뉴 정보 제공

### 3. 즐겨찾기 관리
- **즐겨찾기 추가**: 마음에 드는 메뉴를 즐겨찾기에 저장
- **즐겨찾기 목록**: 저장된 메뉴들을 날짜순으로 정렬
- **즐겨찾기 삭제**: 스와이프로 간편한 삭제
- **상세 정보**: 카테고리, 식당, 추가일 확인

### 4. 데이터 관리
- **JSON 저장**: 즐겨찾기와 설정을 JSON 파일로 로컬 저장
- **샘플 데이터**: 서울 주요 지역의 식당 데이터 제공
- **설정 저장**: 사용자 선호도와 추천 기록 관리

## 🛠️ 기술 스택

- **언어**: Swift
- **UI**: UIKit + Storyboard
- **지도**: MapKit
- **위치**: CoreLocation  
- **데이터**: JSON + Codable
- **파일 관리**: FileManager
- **아키텍처**: MVC 패턴

## 📁 프로젝트 구조

```
lunch/
├── AppDelegate.swift           # 앱 델리게이트
├── SceneDelegate.swift         # 씬 델리게이트
├── DataManager.swift           # 데이터 모델 및 매니저
├── MenuRecommendationEngine.swift # 메뉴 추천 엔진
├── ViewController.swift        # 메인 화면
├── ResultViewController.swift  # 추천 결과 화면
├── MapViewController.swift     # 지도 화면
├── FavoritesViewController.swift # 즐겨찾기 화면
├── Base.lproj/
│   ├── Main.storyboard        # 메인 스토리보드
│   └── LaunchScreen.storyboard # 런치 스크린
├── Assets.xcassets/           # 앱 아이콘 및 이미지
└── Info.plist                 # 앱 설정 (위치 권한 포함)
```

## 🎯 핵심 클래스 설명

### DataManager
- 싱글톤 패턴으로 구현
- JSON 파일을 통한 데이터 저장/로드
- 즐겨찾기, 사용자 설정, 식당 데이터 관리

### MenuRecommendationEngine  
- 메뉴 추천 로직 담당
- 카테고리별 필터링
- 중복 추천 방지
- 추천 통계 및 히스토리 관리

### View Controllers
- **MainViewController**: 메인 화면, 메뉴 추천 시작
- **ResultViewController**: 추천 결과 표시, 즐겨찾기 추가
- **MapViewController**: 지도 기반 식당 탐색
- **FavoritesViewController**: 즐겨찾기 목록 관리

## 🗂️ 데이터 모델

### Menu
```swift
struct Menu: Codable, Identifiable {
    let name: String
    let category: FoodCategory
    let description: String
    let imageURL: String?
}
```

### Restaurant
```swift
struct Restaurant: Codable, Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let category: FoodCategory
    let address: String
    let phoneNumber: String?
    let menu: [Menu]
}
```

### FoodCategory
```swift
enum FoodCategory: String, CaseIterable, Codable {
    case korean = "한식"
    case chinese = "중식"
    case japanese = "일식"
    case western = "양식"
    case fastFood = "패스트푸드"
    case cafe = "카페"
    case dessert = "디저트"
    case all = "전체"
}
```

## 🚀 실행 방법

1. Xcode에서 프로젝트 열기
2. iOS 시뮬레이터 또는 실제 기기 선택
3. Product > Run (⌘R) 또는 빌드 버튼 클릭
4. 위치 권한 허용 (지도 기능 사용 시)

## 📋 요구사항

- **iOS**: 14.0 이상
- **Xcode**: 12.0 이상
- **Swift**: 5.0 이상
- **권한**: 위치 서비스 (선택적)

## 🎨 UI/UX 특징

- **직관적 인터페이스**: 메뉴 추천부터 즐겨찾기까지 간단한 탭으로 이동
- **시각적 피드백**: 카테고리별 이모지와 색상으로 구분
- **반응형 디자인**: 다양한 기기 크기에 대응
- **네이티브 컴포넌트**: iOS 디자인 가이드라인 준수

## 🔧 개발 시 고려사항

### 1. 위치 권한
- Info.plist에 위치 사용 권한 설명 추가
- 사용자가 권한을 거부해도 기본 기능 동작

### 2. 데이터 관리
- JSON 파일로 로컬 저장하여 오프라인에서도 동작
- 사용자 데이터는 Documents 디렉토리에 저장

### 3. 에러 처리
- 네트워크 연결 없이도 기본 기능 제공
- 사용자에게 친화적인 에러 메시지 표시

## 🤝 기여하기

1. 이 저장소를 포크하세요
2. 새로운 기능 브랜치를 만드세요 (`git checkout -b feature/AmazingFeature`)
3. 변경사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`)
5. Pull Request를 생성하세요

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의

프로젝트에 대한 질문이나 제안사항이 있으시면 이슈를 생성해주세요.

---

**🍽️ 더 이상 점심 메뉴 고민하지 마세요! 버튼 한 번으로 맛있는 점심을 찾아보세요! 🍽️** 