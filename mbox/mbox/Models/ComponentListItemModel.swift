//
//  ComponentListItemModel.swift
//  mbox
//
//  针对不同组件类型的列表项模型
//

import Foundation

/// 视频列表项模型
struct VideoListItemModel: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let badge: String?
}

/// 卡片列表项模型
struct CardListItemModel: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let badge: String?
}

/// 图表列表项模型
struct ChartListItemModel: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let chartType: String
    let period: String?
    let unit: String?
    let chartData: [[String: JSONValue]]?
}
