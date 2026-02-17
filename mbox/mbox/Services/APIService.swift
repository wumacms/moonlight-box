//
//  APIService.swift
//  mbox
//
//  列表/详情 API 请求与动态解析
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpStatus(404): return "内容不存在"
        case .httpStatus(let code): return "请求失败 (HTTP \(code))"
        case .decode(let msg): return "解析失败: \(msg)"
        }
    }
}

@Observable
final class APIService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    /// 请求列表数据（分页），返回原始 JSON 数组
    /// - Parameters:
    ///   - urlString: 列表 API URL（不含 query）
    ///   - page: 页码，默认 1
    ///   - size: 每页条数，默认 10
    ///   - method: HTTP 方法，默认 "GET"
    ///   - headers: 自定义 Header
    func fetchList(
        urlString: String,
        page: Int = 1,
        size: Int = 10,
        method: String = "GET",
        headers: [String: String] = [:]
    ) async throws -> (items: [[String: Any]], total: Int) {
        let isPost = method.uppercased() == "POST"
        guard var components = URLComponents(string: urlString) else { throw APIError.invalidURL }
        
        var request: URLRequest
        
        if isPost {
            guard let url = components.url else { throw APIError.invalidURL }
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["page": page, "size": size]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else {
            components.queryItems = (components.queryItems ?? []) + [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "size", value: "\(size)")
            ]
            guard let url = components.url else { throw APIError.invalidURL }
            request = URLRequest(url: url)
            request.httpMethod = "GET"
        }
        
        // 应用自定义 Header
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let code = json["code"] as? Int, code == 200 else {
            throw APIError.decode("code != 200 或缺失")
        }
        guard let dataObj = json["data"] as? [String: Any] else {
            if json["data"] != nil { return ([], 0) }
            throw APIError.decode("data 缺失")
        }
        guard let dataArray = dataObj["list"] as? [[String: Any]] else {
            throw APIError.decode("data.list 不是数组")
        }
        let total = dataObj["total"] as? Int ?? dataArray.count
        return (dataArray, total)
    }

    /// 请求详情：GET {url}?id={id} 或 POST {url} Body: {id: id}
    func fetchDetail(
        urlString: String,
        id: String,
        method: String = "GET",
        headers: [String: String] = [:]
    ) async throws -> JSONValue {
        let isPost = method.uppercased() == "POST"
        guard var components = URLComponents(string: urlString) else { throw APIError.invalidURL }
        
        var request: URLRequest
        
        if isPost {
            guard let url = components.url else { throw APIError.invalidURL }
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["id": id])
        } else {
            // 保留配置中已有 query，仅覆盖/追加 id，避免误写死 id=1 或丢失其他参数
            var queryItems = components.queryItems ?? []
            queryItems.removeAll { $0.name == "id" }
            queryItems.append(URLQueryItem(name: "id", value: id))
            components.queryItems = queryItems
            guard let url = components.url else { throw APIError.invalidURL }
            request = URLRequest(url: url)
            request.httpMethod = "GET"
        }
        
        // 应用自定义 Header
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        let res = try decoder.decode(DetailResponse.self, from: data)
        guard let detail = res.data else { throw APIError.decode("data 为空") }
        return detail
    }
}
