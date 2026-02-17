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
        let preferredOrder = ["author", "date", "pubDate", "duration", "resolution", "chartType", "period", "category", "unit"]
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
        case "pubDate": return "发布日期"
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
            VStack(alignment: .leading, spacing: 10) {
                ForEach(displayKeys, id: \.0) { label, value in
                    HStack(alignment: .top, spacing: 12) {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                            .frame(width: 80, alignment: .leading)
                        Text(value)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                    }
                }
            }
            .padding(12)
            .background(AppTheme.secondaryBackgroundColor(colorScheme).opacity(0.5))
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor(colorScheme), lineWidth: 1)
            )
            .padding(.vertical, 8)
        }
    }
}
