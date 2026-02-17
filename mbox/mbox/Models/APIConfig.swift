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
    var componentType: String  // "card"(图文列表) | "video"(视频列表) | "chart"(图表列表) 等
    var createdAt: Date
    var updatedAt: Date
    /// 列表字段映射：标准 UI 属性 -> 后端 JSON Key
    var listMappingData: Data?
    /// 详情字段映射：标准 UI 属性 -> 后端 JSON Key
    var detailMappingData: Data?
    
    var httpMethod: String = "GET"
    var headersData: Data?

    var listMapping: [String: String] {
        get {
            guard let data = listMappingData,
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return APIConfig.defaultListMapping(for: componentType)
            }
            return decoded
        }
        set {
            listMappingData = try? JSONEncoder().encode(newValue)
        }
    }

    var detailMapping: [String: String] {
        get {
            guard let data = detailMappingData,
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return APIConfig.defaultDetailMapping()
            }
            return decoded
        }
        set {
            detailMappingData = try? JSONEncoder().encode(newValue)
        }
    }

    var headers: [String: String] {
        get {
            guard let data = headersData,
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            headersData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        listAPIURL: String = "",
        detailAPIURL: String? = nil,
        componentType: String = "card",
        httpMethod: String = "GET",
        headers: [String: String]? = nil,
        listMapping: [String: String]? = nil,
        detailMapping: [String: String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.listAPIURL = listAPIURL
        self.detailAPIURL = detailAPIURL
        self.componentType = componentType
        self.httpMethod = httpMethod
        self.headersData = try? JSONEncoder().encode(headers ?? [:])
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.listMappingData = try? JSONEncoder().encode(listMapping ?? APIConfig.defaultListMapping(for: componentType))
        self.detailMappingData = try? JSONEncoder().encode(detailMapping ?? APIConfig.defaultDetailMapping())
    }

    /// 列表项标准属性及默认后端 Key 建议
    static let standardListKeys = ["ui_title", "ui_subtitle", "ui_image", "ui_id", "ui_badge"]
    /// 图表扩展映射（可选）：用于精确指定图表数据字段
    static let standardChartKeys = ["chart_data", "chart_x", "chart_y"]

    /// 按组件类型返回默认列表字段映射
    static func defaultListMapping(for componentType: String) -> [String: String] {
        var mapping = [String: String]()
        for key in standardListKeys {
            mapping[key] = ""
        }
        if componentType == "chart" {
            for key in standardChartKeys {
                mapping[key] = ""
            }
        }
        return mapping
    }

    /// 返回默认详情字段映射
    static func defaultDetailMapping() -> [String: String] {
        var mapping = [String: String]()
        for key in standardDetailKeys {
            mapping[key] = ""
        }
        return mapping
    }

    /// 详情页标准属性
    static let standardDetailKeys = ["title", "content", "mediaUrl", "id"]
}
