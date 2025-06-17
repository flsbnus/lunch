# 🍽️ Lunch (점심 메뉴 추천 iOS 앱)

## 소개
UIKit + Storyboard 기반의 점심 메뉴 추천 앱입니다.  
"오늘 뭐 먹지?" 고민을 한 번에 해결!  
주변 식당 탐색, 지도 기반 탐색, 즐겨찾기, 카테고리별 추천 등 다양한 기능을 제공합니다.

---

## 주요 기능

- **메뉴 추천**: 위치 기반, 카테고리별(한식, 중식, 일식, 양식, 패스트푸드, 카페) 랜덤 추천
- **지도 기반 탐색**: 내 위치 중심, 카테고리별로 주변 식당 마커 표시
- **즐겨찾기**: 추천받은 식당을 즐겨찾기로 저장/삭제, 목록 관리
- **데이터 관리**: 즐겨찾기, 추천 기록 등은 JSON 파일로 안전하게 로컬 저장

---

## 설계 및 구조

### 아키텍처
- **MVC 패턴**: ViewController, Model, DataManager, RecommendationEngine 등으로 분리

### 주요 클래스
- **DataManager**: 싱글톤, JSON 파일로 데이터 저장/불러오기, 즐겨찾기/설정/식당 데이터 관리
- **MenuRecommendationEngine**: 추천 로직, 카테고리별 필터, 중복 방지, 추천 통계
- **ViewController**: 메인 화면, 메뉴 추천
- **MapViewController**: 지도 기반 식당 탐색, 카테고리별 마커 표시
- **FavoritesViewController**: 즐겨찾기 목록 관리
- **ResultViewController**: 추천 결과 표시, 즐겨찾기 추가

### 데이터 모델
```swift
struct Menu: Codable, Identifiable {
    let name: String
    let category: FoodCategory
    let description: String
    let imageURL: String?
}

struct Restaurant: Codable, Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let category: FoodCategory
    let address: String
    let phoneNumber: String?
    let menu: [Menu]
}

enum FoodCategory: String, CaseIterable, Codable {
    case korean = "한식"
    case chinese = "중식"
    case japanese = "일식"
    case western = "양식"
    case fastFood = "패스트푸드"
    case cafe = "카페"
    case all = "전체"
}
```

---

## 외부 API

- **카카오 로컬 API**를 사용하여 주변 음식점 정보를 실시간으로 받아옵니다.  
  [카카오 로컬 API 공식 문서](https://developers.kakao.com/docs/latest/ko/local/dev-guide)

---

## API 키 관리

- 카카오 API 키는 `Secrets.plist` 파일에 저장하며, 이 파일은 Git에 포함되지 않습니다.
- 앱을 실행하려면 본인만의 카카오 REST API 키를 [카카오 개발자센터](https://developers.kakao.com/)에서 발급받아 `Secrets.plist`에 입력해야 합니다.

예시:
```xml
<key>KAKAO_API_KEY</key>
<string>여기에_카카오_API_키_입력</string>
```

---

## 실행 방법

1. Xcode에서 프로젝트 열기
2. `Secrets.plist` 파일에 본인 카카오 API 키 입력
3. 시뮬레이터 또는 실제 기기에서 빌드 및 실행
4. 위치 권한 허용(지도 기능 사용 시)

---

## 요구사항

- iOS 14.0 이상
- Xcode 12.0 이상
- Swift 5.0 이상

---

## UI/UX 특징

- 직관적 인터페이스, 카테고리별 이모지, 현대적 테마
- 지도에서 카테고리별 마커 표시, 반응형 디자인
- 네이티브 컴포넌트(iOS 디자인 가이드라인 준수)

---

## 주의사항

- 카카오 API 사용 시 [카카오 오픈 API 운영정책](https://developers.kakao.com/terms/latest/ko/site-terms-of-use) 및 출처 표기 의무를 준수해야 합니다.
- API 키 등 민감 정보는 절대 Git에 올리지 마세요.

---

## 라이선스

MIT License

---

**🍽️ 더 이상 점심 메뉴 고민하지 마세요! 버튼 한 번으로 맛있는 점심을 찾아보세요! 🍽️** 