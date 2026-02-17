//
//  APIConfig.swift
//  mbox
//
//  API 注册与组件关联配置（SwiftData 持久化）
//

import Foundation
import SwiftData

/// API 注册与组件关联配置
@Model
final class APIConfig: Identifiable {
    var id: UUID
    var name: String
    var listAPIURL: String
    var detailAPIURL: String?
    var componentType: String  // "card" | "video" | "chart" 等
    var createdAt: Date
    var updatedAt: Date

    /// 字段映射：标准 UI 属性 -> 后端 JSON Key
    /// 例如 ["ui_title": "original_title", "ui_subtitle": "summary"]
    var fieldMappingData: Data?

    var fieldMapping: [String: String] {
        get {
            guard let data = fieldMappingData,
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return APIConfig.defaultListMapping(for: componentType)
            }
            return decoded
        }
        set {
            fieldMappingData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        listAPIURL: String = "",
        detailAPIURL: String? = nil,
        componentType: String = "card",
        fieldMapping: [String: String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.listAPIURL = listAPIURL
        self.detailAPIURL = detailAPIURL
        self.componentType = componentType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fieldMappingData = try? JSONEncoder().encode(fieldMapping ?? APIConfig.defaultListMapping(for: componentType))
    }

    /// 列表项标准属性及默认后端 Key 建议
    static let standardListKeys = ["ui_title", "ui_subtitle", "ui_image", "ui_id", "ui_badge"]
    /// 图表扩展映射（可选）：用于精确指定图表数据字段
    static let standardChartKeys = ["chart_data", "chart_x", "chart_y"]

    /// 按组件类型返回默认字段映射
    static func defaultListMapping(for componentType: String) -> [String: String] {
        switch componentType {
        case "video":
            return [
                "ui_title": "title",
                "ui_subtitle": "subtitle",
                "ui_image": "imageUrl",
                "ui_id": "id",
                "ui_badge": "badge"
            ]
        case "chart":
            return [
                "ui_title": "title",
                "ui_subtitle": "subtitle",
                "ui_image": "imageUrl",
                "ui_id": "id",
                "ui_badge": "chartType",
                "chart_data": "chartData",
                "chart_x": "x",
                "chart_y": "y"
            ]
        default:  // "card"
            return [
                "ui_title": "title",
                "ui_subtitle": "subtitle",
                "ui_image": "imageUrl",
                "ui_id": "id",
                "ui_badge": "badge"
            ]
        }
    }

    /// 详情页标准属性
    static let standardDetailKeys = ["title", "content", "mediaUrl", "id", "extendInfo"]
}
