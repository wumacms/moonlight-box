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
    
    // 图表专用字段
    var chartType: String?
    var period: String?
    var unit: String?
    var chartData: Any? // [[String: Any]]
    
    var raw: [String: Any]  // 原始条目，便于详情请求时带 extendInfo 等

    static func from(json: [String: Any], mapping: [String: String]) -> ListItemModel {
        func value(for uiKey: String) -> Any? {
            let path = mapping[uiKey] ?? uiKey
            if path.hasPrefix("$") {
                return JsonPathService.shared.query(jsonValue: json, path: path)
            } else {
                return json[path]
            }
        }

        func string(from uiKey: String) -> String {
            if let v = value(for: uiKey) as? String { return v }
            if let v = value(for: uiKey) as? Int { return String(v) }
            if let v = value(for: uiKey) { return String(describing: v) }
            return ""
        }

        let idVal = (value(for: "ui_id") as? String) ?? (value(for: "ui_id") as? Int).map { String($0) } ?? ""
        
        return ListItemModel(
            id: idVal,
            uiTitle: string(from: "ui_title"),
            uiSubtitle: string(from: "ui_subtitle"),
            uiImage: (value(for: "ui_image") as? String).flatMap { $0.isEmpty ? nil : $0 },
            uiBadge: (value(for: "ui_badge") as? String).flatMap { $0.isEmpty ? nil : $0 },
            chartType: value(for: "chart_type") as? String ?? (value(for: "chartType") as? String),
            period: value(for: "period") as? String,
            unit: value(for: "unit") as? String,
            chartData: value(for: "chart_data") ?? value(for: "chartData"),
            raw: json
        )
    }
}
