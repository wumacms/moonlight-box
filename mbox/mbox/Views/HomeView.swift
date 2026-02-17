//
//  HomeView.swift
//  mbox
//
//  首页：瀑布流/滚动卡片、骨架屏、动态解析渲染
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \APIConfig.updatedAt, order: .reverse) private var configs: [APIConfig]
    @State private var sections: [HomeSection] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var warningMessage: String?
    @State private var selectedDetail: DetailDestination?
    @AppStorage("homeDisplayMode") private var displayModeRaw: String = HomeDisplayMode.grid.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private let apiService = APIService()
    private let gridSpacing: CGFloat = 20
    private let itemMinWidth: CGFloat = 165

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor(colorScheme)
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 20) {
                        contentView
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("月光宝盒")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("显示模式", selection: $displayModeRaw) {
                        Text("网格").tag(HomeDisplayMode.grid.rawValue)
                        Text("列表").tag(HomeDisplayMode.list.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            .onAppear {
                loadAllLists()
            }
            .onChange(of: configsSignature) { _, _ in
                loadAllLists()
            }
            .navigationDestination(item: $selectedDetail) { detail in
                DetailView(
                    detailURL: detail.detailURL,
                    itemId: detail.itemId,
                    componentType: detail.componentType,
                    chartListDataJSON: detail.chartListDataJSON
                )
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if configs.isEmpty {
            emptyConfigsView
        } else if loading && sections.isEmpty {
            loadingView
        } else if let msg = errorMessage {
            errorView(msg)
        } else {
            sectionsView
        }
    }

    private var emptyConfigsView: some View {
        Text("请先在配置页添加 API")
            .foregroundStyle(.secondary)
            .padding()
    }

    private var loadingView: some View {
        ForEach(0..<6, id: \.self) { _ in
            SkeletonCardView()
        }
    }

    private func errorView(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(AppTheme.errorColor(colorScheme))
            .padding()
    }

    @ViewBuilder
    private var sectionsView: some View {
        ForEach(sections) { section in
            sectionView(section)
        }
        if let warningMessage {
            Text(warningMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.errorColor(colorScheme))
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(section.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryTextColor(colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.secondaryBackgroundColor(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.borderColor(colorScheme), lineWidth: 1)
                    )
                
                Rectangle()
                    .fill(AppTheme.borderColor(colorScheme))
                    .frame(height: 1)
            }
            .padding(.horizontal, 4)

            if section.items.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            } else {
                if displayMode == .grid {
                    cardsGrid(section.items)
                } else {
                    cardsList(section.items)
                }
            }
        }
    }

    private func cardsGrid(_ items: [HomeListEntry]) -> some View {
        let adaptiveColumns = [GridItem(.adaptive(minimum: itemMinWidth), spacing: 16)]
        return LazyVGrid(columns: adaptiveColumns, spacing: 16) {
            ForEach(items) { item in
                itemButton(item)
            }
        }
    }

    private func cardsList(_ items: [HomeListEntry]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                itemButton(item, isListMode: true)
            }
        }
    }

    private func itemButton(_ item: HomeListEntry, isListMode: Bool = false) -> some View {
        Button {
            if let detailURL = item.detailAPIURL {
                selectedDetail = DetailDestination(
                    detailURL: detailURL,
                    itemId: item.item.id,
                    componentType: item.componentType,
                    chartListDataJSON: item.componentType == "chart" ? chartListDataJSON(from: item.item) : nil
                )
            }
        } label: {
            itemCard(item)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: isListMode ? .infinity : nil, alignment: .leading)
    }

    @ViewBuilder
    private func itemCard(_ item: HomeListEntry) -> some View {
        if item.componentType == "chart" {
            ChartCardView(item: item.item, fieldMapping: item.fieldMapping)
        } else {
            DynamicCardView(item: item.item, showPlayButton: item.componentType == "video")
        }
    }

    private var configsSignature: String {
        configs
            .map { "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSince1970)" }
            .joined(separator: ",")
    }

    private var displayMode: HomeDisplayMode {
        HomeDisplayMode(rawValue: displayModeRaw) ?? .grid
    }

    private func loadAllLists() {
        guard !configs.isEmpty else {
            sections = []
            errorMessage = nil
            warningMessage = nil
            return
        }

        loading = true
        errorMessage = nil
        warningMessage = nil
        Task {
            var grouped: [HomeSection] = []
            var failures: [String] = []
            for config in configs {
                let sourceName = config.name.isEmpty ? config.listAPIURL : config.name
                do {
                    let (raw, _) = try await apiService.fetchList(urlString: config.listAPIURL)
                    let list = MappingEngine.parseList(rawItems: raw, fieldMapping: config.fieldMapping)
                    let mapped = list.enumerated().map { offset, item in
                        let resolvedDetailURL = config.detailAPIURL ?? inferDetailURL(from: config.listAPIURL)
                        return HomeListEntry(
                            id: "\(config.id.uuidString)-\(offset)-\(item.id)",
                            item: item,
                            componentType: config.componentType,
                            fieldMapping: config.fieldMapping,
                            detailAPIURL: resolvedDetailURL
                        )
                    }
                    grouped.append(HomeSection(id: config.id.uuidString, title: sourceName, items: mapped))
                } catch {
                    failures.append("\(sourceName): \(error.localizedDescription)")
                    grouped.append(HomeSection(id: config.id.uuidString, title: sourceName, items: []))
                }
            }
            let hasAnyItem = grouped.contains { !$0.items.isEmpty }
            await MainActor.run {
                sections = grouped
                if failures.isEmpty {
                    errorMessage = nil
                    warningMessage = nil
                } else if hasAnyItem {
                    errorMessage = nil
                    warningMessage = failures.joined(separator: "\n")
                } else {
                    errorMessage = failures.joined(separator: "\n")
                    warningMessage = nil
                }
                loading = false
            }
        }
    }

    /// 当未显式配置详情 URL 时，从常见 list 路径推导 detail 路径
    private func inferDetailURL(from listURL: String) -> String? {
        guard var components = URLComponents(string: listURL) else { return nil }
        if components.path.hasSuffix("/list") {
            components.path = String(components.path.dropLast("/list".count)) + "/detail"
            components.query = nil
            return components.url?.absoluteString
        }
        return nil
    }

    /// 将图表列表项转成可传递的 JSON 字符串，详情页据此做表格展示
    private func chartListDataJSON(from item: ListItemModel) -> String? {
        var payload: [String: Any] = item.raw
        payload["id"] = item.id
        payload["title"] = item.uiTitle
        if !item.uiSubtitle.isEmpty { payload["subtitle"] = item.uiSubtitle }
        if let badge = item.uiBadge, !badge.isEmpty {
            payload["badge"] = badge
            if payload["chartType"] == nil {
                payload["chartType"] = badge
            }
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}

private enum HomeDisplayMode: String {
    case grid
    case list
}

private struct HomeSection: Identifiable {
    let id: String
    let title: String
    let items: [HomeListEntry]
}

private struct HomeListEntry: Identifiable {
    let id: String
    let item: ListItemModel
    let componentType: String
    let fieldMapping: [String: String]
    let detailAPIURL: String?
}

private struct DetailDestination: Identifiable, Hashable {
    let detailURL: String
    let itemId: String
    let componentType: String
    let chartListDataJSON: String?

    var id: String { "\(detailURL)|\(itemId)|\(componentType)" }
}

#Preview {
    HomeView()
        .modelContainer(for: APIConfig.self, inMemory: true)
}
