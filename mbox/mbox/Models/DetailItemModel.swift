//
//  DetailItemModel.swift
//  mbox
//
//  通用的动态详情模型，支持不同结构的后端响应
//

import Foundation

/// 详情响应包装器
struct DetailResponse: Decodable {
    let code: Int
    let data: JSONValue?
}

/// 辅助扩展，方便从 JSONValue 获取字段
extension JSONValue {
    var dictValue: [String: JSONValue]? {
        if case .object(let dict) = self {
            return dict
        }
        return nil
    }
    
    func findString(_ key: String) -> String {
        dictValue?[key]?.stringValue ?? ""
    }
}
