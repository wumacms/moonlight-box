//
//  ExtendInfoView.swift
//  mbox
//
//  展示 extendInfo 扩展信息（作者、日期、时长、图表类型等）
//

import SwiftUI

struct ExtendInfoView: View {
    let extendInfo: [String: String]?
    @Environment(\.colorScheme) private var colorScheme

    private var displayKeys: [(String, String)] {
        guard let info = extendInfo, !info.isEmpty else { return [] }
        let preferredOrder = ["author", "date", "duration", "resolution", "chartType", "period", "category", "unit"]
        var ordered: [(String, String)] = []
        for key in preferredOrder {
            if let value = info[key], !value.isEmpty {
                ordered.append((labelForKey(key), value))
            }
        }
        let remaining = info.filter { !preferredOrder.contains($0.key) }
        for (k, v) in remaining.sorted(by: { $0.key < $1.key }) where !v.isEmpty {
            ordered.append((labelForKey(k), v))
        }
        return ordered
    }

    private func labelForKey(_ key: String) -> String {
        switch key {
        case "author": return "作者"
        case "date": return "日期"
        case "duration": return "时长"
        case "resolution": return "分辨率"
        case "chartType": return "图表类型"
        case "period": return "周期"
        case "category": return "分类"
        case "unit": return "单位"
        default: return key
        }
    }

    var body: some View {
        if !displayKeys.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(displayKeys, id: \.0) { label, value in
                    HStack(alignment: .top, spacing: 8) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.deepBlue(colorScheme))
                            .frame(width: 72, alignment: .leading)
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
