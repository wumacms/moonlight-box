//
//  ListItemModel.swift
//  mbox
//
//  动态解析后的列表项标准模型（运行时使用，非持久化）
//

import Foundation

/// 列表项标准模型：由映射表从后端 JSON 动态解析得到
struct ListItemModel: Identifiable {
    var id: String
    var uiTitle: String
    var uiSubtitle: String
    var uiImage: String?
    var uiBadge: String?
    var raw: [String: Any]  // 原始条目，便于详情请求时带 extendInfo 等

    static func from(json: [String: Any], mapping: [String: String]) -> ListItemModel {
        func string(from key: String) -> String {
            let backendKey = mapping[key] ?? key
            if let v = json[backendKey] as? String { return v }
            if let v = json[backendKey] as? Int { return String(v) }
            if let v = json[backendKey] { return String(describing: v) }
            return ""
        }
        let idKey = mapping["ui_id"] ?? "id"
        let idVal = json[idKey].flatMap { v in (v as? String) ?? (v as? Int).map { String($0) } } ?? ""
        return ListItemModel(
            id: idVal,
            uiTitle: string(from: "ui_title"),
            uiSubtitle: string(from: "ui_subtitle"),
            uiImage: (json[mapping["ui_image"] ?? "ui_image"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            uiBadge: (json[mapping["ui_badge"] ?? "ui_badge"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            raw: json
        )
    }
}
