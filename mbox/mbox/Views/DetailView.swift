//
//  DetailView.swift
//  mbox
//
//  详情页：动态适配不同结构的详情接口数据
//

import SwiftUI
import Charts

struct DetailView: View {
    let detailURL: String
    let itemId: String
    var componentType: String = "card"
    var detailMapping: [String: String] = [:]
    var chartListDataJSON: String? = nil
    @State private var detail: JSONValue?
    @State private var loading = true
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    private let apiService = APIService()

    private var detailDict: [String: JSONValue] {
        detail?.dictValue ?? [:]
    }

    private func mappedValue(for uiKey: String) -> String {
        // 如果用户没配置，使用标准 Key 作为默认后端字段名
        let mapping = detailMapping[uiKey] ?? ""
        let path = mapping.isEmpty ? uiKey : mapping
        
        guard let data = detail?.anyValue else { return "" }
        
        if path.hasPrefix("$") {
            let result = JsonPathService.shared.query(jsonValue: data, path: path)
            if let s = result as? String { return s }
            if let n = result as? Double { return n.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", n) : String(n) }
            if let n = result as? Int { return String(n) }
            // 过滤掉 NSNull 或空描述，避免 URL 变成 "<null>"
            if result == nil || result is NSNull { return "" }
            return String(describing: result!)
        } else {
            return detail?.findString(path) ?? ""
        }
    }

    private var title: String { mappedValue(for: "title") }
    private var content: String { mappedValue(for: "content") }
    private var mediaUrl: String { mappedValue(for: "mediaUrl") }

    /// 将动态详情中除了核心字段外的其他字段视为扩展信息
    private var dynamicExtendInfo: [String: String] {
        // 核心字段：既包括代码硬编码的，也包括 mapping 中定义的后端原始 key
        let coreUIKeys: Set<String> = ["id", "title", "content", "mediaUrl", "imageUrl", "subtitle", "badge", "chartData", "chartType"]
        let mappedBackendKeys = Set(detailMapping.values.filter { !$0.hasPrefix("$") })
        
        var info: [String: String] = [:]
        for (key, value) in detailDict {
            if !coreUIKeys.contains(key) && !mappedBackendKeys.contains(key) {
                info[key] = value.stringValue
            }
        }
        return info
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor(colorScheme)
                .ignoresSafeArea()
            if loading && detail == nil {
                VStack {
                    ProgressView()
                    Text("加载中…")
                        .foregroundStyle(.secondary)
                }
            } else if let msg = errorMessage {
                ContentUnavailableView("加载失败", systemImage: "exclamationmark.triangle", description: Text(msg))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if !mediaUrl.isEmpty {
                            MediaBannerView(mediaUrl: mediaUrl, componentType: componentType)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                            
                            if !dynamicExtendInfo.isEmpty {
                                ExtendInfoView(extendInfo: dynamicExtendInfo)
                            }
                            
                            if componentType == "chart" {
                                chartDetailView
                            }
                            
                            if !content.isEmpty {
                                MarkdownContentView(text: content)
                            }
                        }
                        .padding(AppTheme.cardPadding)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchDetail() }
    }

    private func fetchDetail() {
        loading = true
        errorMessage = nil
        Task {
            do {
                let result = try await apiService.fetchDetail(urlString: detailURL, id: itemId)
                await MainActor.run {
                    detail = result
                    loading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    loading = false
                }
            }
        }
    }

    @ViewBuilder
    private var chartDetailView: some View {
        if let payload = chartPayload, !payload.chartData.isEmpty {
            ChartDetailRenderView(payload: payload)
            ChartListTableView(rows: chartTableRows)
        } else {
            ChartListTableView(rows: chartTableRows)
        }
    }

    private var chartPayload: ChartListPayload? {
        // 先尝试从 detail 实时动态解析，因为后端结构变了
        if let data = try? JSONEncoder().encode(detail),
           let payload = try? JSONDecoder().decode(ChartListPayload.self, from: data),
           !payload.chartData.isEmpty {
            return payload
        }
        
        // 兜底：从列表传递过来的 JSON 解析
        guard let chartListDataJSON,
              let data = chartListDataJSON.data(using: .utf8),
              let payload = try? JSONDecoder().decode(ChartListPayload.self, from: data) else {
            return nil
        }
        return payload
    }

    private var chartTableRows: [(label: String, value: String)] {
        if let payload = chartPayload, !payload.chartData.isEmpty {
            let unit = payload.unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let rows = payload.chartData.map { point in
                (point.x, formatChartValue(point.y, unit: unit))
            }
            return rows
        }
        return []
    }

    private func formatChartValue(_ value: Double, unit: String) -> String {
        let formatted: String
        if value.rounded() == value {
            formatted = String(Int(value))
        } else {
            formatted = String(format: "%.2f", value)
        }
        guard !unit.isEmpty else { return formatted }
        return "\(formatted) \(unit)"
    }
}

/// 简单 Markdown 正文展示
struct MarkdownContentView: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(attributedContent)
            .font(.system(size: 15))
            .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributedContent: AttributedString {
        var out = AttributedString()
        let paragraphs = text.components(separatedBy: "\n\n")
        for (i, para) in paragraphs.enumerated() {
            if i > 0 { out += AttributedString("\n\n") }
            out += parseInline(para)
        }
        return out
    }

    private func parseInline(_ segment: String) -> AttributedString {
        var result = AttributedString()
        var remaining = segment
        while !remaining.isEmpty {
            if let b = remaining.range(of: "**"), let e = remaining.range(of: "**", range: b.upperBound..<remaining.endIndex) {
                result += AttributedString(remaining[..<b.lowerBound])
                var bold = AttributedString(remaining[b.upperBound..<e.lowerBound])
                bold.inlinePresentationIntent = .stronglyEmphasized
                bold.foregroundColor = AppTheme.primaryTextColor(colorScheme)
                result += bold
                remaining = String(remaining[e.upperBound...])
            } else {
                result += AttributedString(remaining)
                break
            }
        }
        return result
    }
}

struct ChartListTableView: View {
    let rows: [(label: String, value: String)]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细数据")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("维度")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    
                    Divider().background(AppTheme.borderColor(colorScheme))
                    
                    Text("数值")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                        .frame(width: 120, alignment: .trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                .background(AppTheme.secondaryBackgroundColor(colorScheme))

                Divider().background(AppTheme.borderColor(colorScheme))

                if rows.isEmpty {
                    HStack {
                        Text("暂无列表数据")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                            .padding(12)
                        Spacer()
                    }
                } else {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            Text(row.label)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            
                            Divider().background(AppTheme.borderColor(colorScheme))
                            
                            Text(row.value)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.accentColor(colorScheme))
                                .frame(width: 120, alignment: .trailing)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        .background(index.isMultiple(of: 2) ? AppTheme.backgroundColor(colorScheme) : AppTheme.secondaryBackgroundColor(colorScheme).opacity(0.3))

                        if index < rows.count - 1 {
                            Divider().background(AppTheme.borderColor(colorScheme))
                        }
                    }
                }
            }
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor(colorScheme), lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
}

private struct ChartListPayload: Decodable {
    let id: String
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let badge: String?
    let chartType: String
    let period: String?
    let unit: String?
    let chartData: [ChartPoint]

    private enum CodingKeys: String, CodingKey {
        case id, title, subtitle, imageUrl, badge, chartType, period, unit, chartData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        subtitle = try? container.decode(String.self, forKey: .subtitle)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        badge = try? container.decode(String.self, forKey: .badge)
        chartType = (try? container.decode(String.self, forKey: .chartType)) ?? "bar"
        period = try? container.decode(String.self, forKey: .period)
        unit = try? container.decode(String.self, forKey: .unit)
        chartData = (try? container.decode([ChartPoint].self, forKey: .chartData)) ?? []
    }
}

private struct ChartPoint: Decodable, Identifiable {
    let x: String
    let y: Double
    var id: String { "\(x)-\(y)" }

    private enum CodingKeys: String, CodingKey {
        case x, y
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(String.self, forKey: .x)
        if let val = try? container.decode(Double.self, forKey: .y) {
            y = val
        } else if let val = try? container.decode(Int.self, forKey: .y) {
            y = Double(val)
        } else if let val = try? container.decode(String.self, forKey: .y), let number = Double(val) {
            y = number
        } else {
            y = 0
        }
    }
}

private struct ChartDetailRenderView: View {
    let payload: ChartListPayload

    private var normalizedType: String {
        payload.chartType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("图表数据")
                    .font(.headline)
                Spacer()
                if let period = payload.period, !period.isEmpty {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            chartBody.frame(height: 220)
            if let unit = payload.unit, !unit.isEmpty {
                Text("单位：\(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var chartBody: some View {
        switch normalizedType {
        case "line":
            Chart(payload.chartData) { point in
                LineMark(x: .value("维度", point.x), y: .value("值", point.y))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("维度", point.x), y: .value("值", point.y))
            }
        case "pie":
            Chart(payload.chartData) { point in
                SectorMark(angle: .value("值", point.y), innerRadius: .ratio(0.5), angularInset: 1)
                    .foregroundStyle(by: .value("维度", point.x))
            }
        default:
            Chart(payload.chartData) { point in
                BarMark(x: .value("维度", point.x), y: .value("值", point.y))
            }
        }
    }
}
