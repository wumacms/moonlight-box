//
//  JsonPathService.swift
//  mbox
//
//  基于 Sextant 的 JsonPath 解析与路径生成服务
//

import Foundation
import Sextant

enum JsonPathError: LocalizedError {
    case invalidJSON(String)
    case invalidPath(String)
    case executionError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON(let msg): return "JSON 解析错误: \(msg)"
        case .invalidPath(let msg): return "无效的 JsonPath: \(msg)"
        case .executionError(let msg): return "执行错误: \(msg)"
        }
    }
}

class JsonPathService {
    static let shared = JsonPathService()
    private init() {}
    
    /// 验证查询路径是否正确
    func validate(query: String, on json: String = "{}") -> String? {
        return json.query(validate: query)
    }
    
    /// 执行 JsonPath 查询
    func query(jsonValue: Any, path: String) -> Any? {
        // Sextant 主要扩展了 String 类型的查询
        // 我们需要先将对象转换为 JSON 字符串
        guard let data = try? JSONSerialization.data(withJSONObject: jsonValue, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        guard let results = jsonString.query(values: path) else {
            return nil
        }
        
        // Sextant 的查询结果数组元素是 JsonAny? (即 Optional<Any?>)
        // 我们需要展开它并返回第一个非空结果
        if let firstResult = results.first {
            // Sextant 可能返回 NSNull()，在此过滤掉以避免产生 "<null>" 字符串
            if firstResult is NSNull { return nil }
            return firstResult
        }
        
        return nil
    }
    
    /// 从 JSON 数据生成所有可能的 JsonPath 列表 (参考 JsonPathExample 中的实现)
    func generatePaths(from jsonObject: Any) -> [String] {
        var paths = Set<String>()
        extractPaths(from: jsonObject, currentPath: "$", paths: &paths)
        return Array(paths).sorted()
    }
    
    private func extractPaths(from value: Any, currentPath: String, paths: inout Set<String>) {
        if currentPath != "$" {
            paths.insert(currentPath)
        }
        
        if let dict = value as? [String: Any] {
            for (key, val) in dict {
                let newPath = formatPath(currentPath: currentPath, key: key)
                extractPaths(from: val, currentPath: newPath, paths: &paths)
            }
        } else if let array = value as? [Any] {
            var allKeys = Set<String>()
            for item in array {
                if let dict = item as? [String: Any] {
                    allKeys.formUnion(dict.keys)
                }
            }
            
            for key in allKeys.sorted() {
                let newPath = formatPath(currentPath: "\(currentPath)[*]", key: key)
                paths.insert(newPath)
                
                for item in array {
                    if let dict = item as? [String: Any],
                       let val = dict[key] {
                        if val is [String: Any] || val is [Any] {
                            extractPaths(from: val, currentPath: newPath, paths: &paths)
                        }
                    }
                }
            }
        }
    }
    
    private func formatPath(currentPath: String, key: String) -> String {
        let needsBracketNotation = key.contains { ":.- ".contains($0) }
        return needsBracketNotation ? "\(currentPath)['\(key)']" : "\(currentPath).\(key)"
    }
}
