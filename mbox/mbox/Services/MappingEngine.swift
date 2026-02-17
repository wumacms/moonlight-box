//
//  MappingEngine.swift
//  mbox
//
//  通过映射表将后端 JSON 解析为标准 ListItemModel
//

import Foundation

struct MappingEngine {
    /// 将列表接口返回的 data 数组 + 映射表 解析为 [ListItemModel]
    static func parseList(
        rawItems: [[String: Any]],
        fieldMapping: [String: String]
    ) -> [ListItemModel] {
        rawItems.map { ListItemModel.from(json: $0, mapping: fieldMapping) }
    }
}
