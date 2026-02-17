//
//  ChartCardView.swift
//  mbox
//
//  图表组件卡片：根据 chartType 渲染折线图/柱状图/饼图
//

import SwiftUI
import Charts

struct ChartCardView: View {
    let item: ListItemModel
    var fieldMapping: [String: String] = APIConfig.defaultListMapping(for: "chart")
    @Environment(\.colorScheme) private var colorScheme

    private var chartType: String {
        let resolved = resolveChartTypeCandidate()
        return normalizeChartType(resolved)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartView
                .frame(height: 120)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.uiTitle)
                    .font(.headline)
                    .lineLimit(2)
                if !item.uiSubtitle.isEmpty {
                    Text(item.uiSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground())
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    @ViewBuilder
    private var chartView: some View {
        let accent = AppTheme.deepBlue(colorScheme)
        if chartData.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("暂无图表数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch chartType {
            case "line":
                Chart(chartData) { datum in
                    LineMark(
                        x: .value("维度", datum.label),
                        y: .value("值", datum.value)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.catmullRom)
                }
            case "pie":
                Chart(chartData) { datum in
                    SectorMark(
                        angle: .value("值", datum.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("维度", datum.label))
                }
            default:
                Chart(chartData) { datum in
                    BarMark(
                        x: .value("维度", datum.label),
                        y: .value("值", datum.value)
                    )
                    .foregroundStyle(accent)
                }
            }
        }
    }

    private var chartData: [ChartDatum] {
        if let configured = chartDataFromConfiguredKeys(), !configured.isEmpty {
            return configured
        }
        if let direct = parseAnyToChartData(item.raw), !direct.isEmpty {
            return direct
        }
        if let extendInfoRaw = item.raw["extendInfo"] {
            if let fromExtend = parseAnyToChartData(extendInfoRaw), !fromExtend.isEmpty {
                return fromExtend
            }
        }
        return fallbackFromNumericFields()
    }

    private var configuredDataKey: String? {
        normalizedMappingValue(for: "chart_data")
    }

    private var configuredXKey: String? {
        normalizedMappingValue(for: "chart_x")
    }

    private var configuredYKey: String? {
        normalizedMappingValue(for: "chart_y")
    }

    private func normalizedMappingValue(for key: String) -> String? {
        guard let value = fieldMapping[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private func chartDataFromConfiguredKeys() -> [ChartDatum]? {
        let xKey = configuredXKey
        let yKey = configuredYKey
        if let dataKey = configuredDataKey {
            if let dataRaw = item.raw[dataKey],
               let rows = parseAnyToChartData(dataRaw, preferredX: xKey, preferredY: yKey),
               !rows.isEmpty {
                return rows
            }
            if let extendInfoRaw = item.raw["extendInfo"] as? [String: Any],
               let dataRaw = extendInfoRaw[dataKey],
               let rows = parseAnyToChartData(dataRaw, preferredX: xKey, preferredY: yKey),
               !rows.isEmpty {
                return rows
            }
        }
        if let rows = parseAnyToChartData(item.raw, preferredX: xKey, preferredY: yKey), !rows.isEmpty {
            return rows
        }
        return nil
    }

    private func resolveChartTypeCandidate() -> String {
        if let badge = item.uiBadge, !badge.isEmpty {
            return badge
        }
        if let value = item.raw["chartType"] as? String, !value.isEmpty {
            return value
        }
        if let value = item.raw["type"] as? String, !value.isEmpty {
            return value
        }
        if let extendInfo = item.raw["extendInfo"] as? [String: Any],
           let value = extendInfo["chartType"] as? String,
           !value.isEmpty {
            return value
        }
        if let extendInfoText = item.raw["extendInfo"] as? String,
           let data = extendInfoText.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let value = object["chartType"] as? String,
           !value.isEmpty {
            return value
        }
        return ""
    }

    private func normalizeChartType(_ rawType: String) -> String {
        let value = rawType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.isEmpty { return "bar" }
        if ["line", "折线", "折线图", "linechart", "trend"].contains(value) {
            return "line"
        }
        if ["pie", "饼图", "环形图", "donut", "doughnut"].contains(value) {
            return "pie"
        }
        if ["bar", "柱状", "柱状图", "histogram", "column"].contains(value) {
            return "bar"
        }
        return "bar"
    }

    private func fallbackFromNumericFields() -> [ChartDatum] {
        let mappedUIKeys = Set(fieldMapping.values)
        let excludedKeys: Set<String> = [
            "id", "title", "subtitle", "name", "summary", "imageUrl", "badge", "chartType", "extendInfo"
        ]
        var rows: [ChartDatum] = []
        for (key, value) in item.raw {
            guard !mappedUIKeys.contains(key), !excludedKeys.contains(key) else { continue }
            if let number = asDouble(value) {
                rows.append(ChartDatum(label: key, value: number))
            }
        }
        return rows.sorted { $0.label < $1.label }
    }

    private func parseAnyToChartData(
        _ raw: Any,
        preferredX: String? = nil,
        preferredY: String? = nil
    ) -> [ChartDatum]? {
        if let data = raw as? [ChartDatum], !data.isEmpty { return data }

        if let value = raw as? String {
            return parseJSONStringToChartData(value, preferredX: preferredX, preferredY: preferredY)
        }
        if let array = raw as? [[String: Any]] {
            let rows = array.compactMap { parseObjectItem($0, preferredX: preferredX, preferredY: preferredY) }
            return rows.isEmpty ? nil : rows
        }
        if let array = raw as? [Any] {
            let rows = parseArrayItems(array, preferredX: preferredX, preferredY: preferredY)
            return rows.isEmpty ? nil : rows
        }
        if let dict = raw as? [String: Any] {
            if let nestedRows = findRows(in: dict, preferredX: preferredX, preferredY: preferredY), !nestedRows.isEmpty {
                return nestedRows
            }
            let keyValueRows = dict.compactMap { key, value -> ChartDatum? in
                guard let number = asDouble(value) else { return nil }
                return ChartDatum(label: key, value: number)
            }
            return keyValueRows.isEmpty ? nil : keyValueRows.sorted { $0.label < $1.label }
        }
        return nil
    }

    private func parseJSONStringToChartData(
        _ text: String,
        preferredX: String? = nil,
        preferredY: String? = nil
    ) -> [ChartDatum]? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        return parseAnyToChartData(object, preferredX: preferredX, preferredY: preferredY)
    }

    private func findRows(
        in dict: [String: Any],
        preferredX: String? = nil,
        preferredY: String? = nil
    ) -> [ChartDatum]? {
        var candidates: [String] = []
        if let dataKey = configuredDataKey {
            candidates.append(dataKey)
        }
        candidates.append(contentsOf: ["chartData", "data", "series", "points", "values", "items", "rows", "dataset"])
        for key in candidates {
            if let value = dict[key],
               let rows = parseAnyToChartData(value, preferredX: preferredX, preferredY: preferredY),
               !rows.isEmpty {
                return rows
            }
        }
        return nil
    }

    private func parseArrayItems(
        _ array: [Any],
        preferredX: String? = nil,
        preferredY: String? = nil
    ) -> [ChartDatum] {
        var rows: [ChartDatum] = []
        for item in array {
            if let row = parseObjectItem(item, preferredX: preferredX, preferredY: preferredY) {
                rows.append(row)
                continue
            }
            if let pair = item as? [Any], pair.count >= 2 {
                let label = String(describing: pair[0])
                if let number = asDouble(pair[1]) {
                    rows.append(ChartDatum(label: label, value: number))
                }
            }
        }
        return rows
    }

    private func parseObjectItem(
        _ raw: Any,
        preferredX: String? = nil,
        preferredY: String? = nil
    ) -> ChartDatum? {
        guard let obj = raw as? [String: Any] else { return nil }
        var labelKeys: [String] = []
        var valueKeys: [String] = []
        if let preferredX, !preferredX.isEmpty { labelKeys.append(preferredX) }
        if let preferredY, !preferredY.isEmpty { valueKeys.append(preferredY) }
        labelKeys.append(contentsOf: ["label", "name", "x", "key", "date", "month", "time", "category", "dimension"])
        valueKeys.append(contentsOf: ["value", "y", "count", "amount", "num", "total", "score"])

        let label = firstString(in: obj, keys: labelKeys)
            ?? obj.first(where: { $0.value is String })?.value as? String
            ?? "item"
        if let v = firstDouble(in: obj, keys: valueKeys) {
            return ChartDatum(label: label, value: v)
        }
        if let numeric = obj.first(where: { asDouble($0.value) != nil }),
           let value = asDouble(numeric.value) {
            return ChartDatum(label: label, value: value)
        }
        return nil
    }

    private func firstString(in obj: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = obj[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func firstDouble(in obj: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let value = obj[key], let number = asDouble(value) {
                return number
            }
        }
        return nil
    }

    private func asDouble(_ value: Any) -> Double? {
        if let v = value as? Double { return v }
        if let v = value as? Int { return Double(v) }
        if let v = value as? Float { return Double(v) }
        if let v = value as? NSNumber { return v.doubleValue }
        if let v = value as? String {
            let trimmed = v.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return Double(trimmed)
        }
        return nil
    }
}

private struct ChartDatum: Identifiable {
    let label: String
    let value: Double

    var id: String { "\(label)-\(value)" }
}
