import Foundation

// 기존 모델들...

// 카카오 로컬 API 응답 모델
struct KakaoLocalResponse: Codable {
    let documents: [KakaoPlace]
    let meta: KakaoMeta
}

struct KakaoPlace: Codable {
    let id: String
    let placeName: String
    let categoryName: String
    let categoryGroupCode: String
    let categoryGroupName: String
    let phone: String
    let addressName: String
    let roadAddressName: String
    let x: String // longitude
    let y: String // latitude
    let distance: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case categoryName = "category_name"
        case categoryGroupCode = "category_group_code"
        case categoryGroupName = "category_group_name"
        case phone
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x
        case y
        case distance
    }
}

struct KakaoMeta: Codable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}

// API 서비스 클래스
class KakaoLocalService {
    static let shared = KakaoLocalService()
    private let baseURL = "https://dapi.kakao.com/v2/local/search"
    
    private init() {}
    
    private var apiKey: String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let key = plist["KAKAO_API_KEY"] as? String
        else {
            fatalError("KAKAO_API_KEY가 Secrets.plist에 없습니다.")
        }
        return key
    }
    
    func searchPlaces(keyword: String, category: String? = nil, latitude: Double, longitude: Double, radius: Int = 1000) async throws -> [KakaoPlace] {
        var components = URLComponents(string: "\(baseURL)/keyword.json")!
        
        var queryItems = [
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "x", value: String(longitude)),
            URLQueryItem(name: "y", value: String(latitude)),
            URLQueryItem(name: "radius", value: String(radius))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category_group_code", value: category))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        // API 응답을 print
        if let jsonString = String(data: data, encoding: .utf8) {
            print("카카오 API 응답: \(jsonString)")
        }
        let response = try JSONDecoder().decode(KakaoLocalResponse.self, from: data)
        return response.documents
    }
    
    // page, size 지정해서 여러 페이지를 받아올 수 있는 함수 추가
    func searchPlacesWithPage(keyword: String, category: String? = nil, latitude: Double, longitude: Double, radius: Int = 1000, page: Int = 1, size: Int = 15) async throws -> [KakaoPlace] {
        var components = URLComponents(string: "\(baseURL)/keyword.json")!
        var queryItems = [
            URLQueryItem(name: "query", value: keyword),
            URLQueryItem(name: "x", value: String(longitude)),
            URLQueryItem(name: "y", value: String(latitude)),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        if let category = category {
            queryItems.append(URLQueryItem(name: "category_group_code", value: category))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("카카오 API 응답: \(jsonString)")
        }
        let response = try JSONDecoder().decode(KakaoLocalResponse.self, from: data)
        return response.documents
    }
    
    // 카테고리 코드 매핑
    static let categoryCodes: [String: String] = [
        "한식": "FD6",
        "중식": "FD7",
        "일식": "FD8",
        "양식": "FD9",
        "카페": "CE7",
        "패스트푸드": "FD4"
    ]
} 
