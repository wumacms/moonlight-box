//
//  DetailItemModel.swift
//  mbox
//
//  详情协议解析模型（文章/视频详情）
//

import Foundation

/// 详情接口返回协议
struct DetailResponse: Decodable {
    let code: Int
    let data: DetailItemModel?
}

struct DetailItemModel: Decodable {
    let id: String?
    let title: String?
    let content: String?
    let mediaUrl: String?
    let extendInfo: [String: String]?

    var safeId: String { id ?? "" }
    var safeTitle: String { title ?? "" }
    var safeContent: String { content ?? "" }
    var safeMediaUrl: String? { mediaUrl.flatMap { $0.isEmpty ? nil : $0 } }
}
