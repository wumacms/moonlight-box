//
//  ConfigView.swift
//  mbox
//
//  配置页：API 注册、字段映射、测试解析预览、容错提示
//

import SwiftUI
import SwiftData

struct ConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \APIConfig.createdAt, order: .forward) private var configs: [APIConfig]
    @State private var showAddSheet = false
    @State private var editingConfig: APIConfig?
    @State private var pendingDeleteIDs: [UUID] = []
    @State private var showDeleteConfirm = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor(colorScheme)
                    .ignoresSafeArea()
                List {
                    ForEach(configs, id: \.id) { config in
                        Button {
                            editingConfig = config
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(config.name.isEmpty ? "未命名" : config.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(config.listAPIURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onDelete(perform: requestDeleteConfigs)
                    .onMove(perform: moveConfigs)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("API 配置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let new = APIConfig()
                        modelContext.insert(new)
                        editingConfig = new
                        try? modelContext.save()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $editingConfig) { config in
                APIConfigFormView(config: config, onDismiss: { editingConfig = nil })
            }
            .alert("确认删除配置？", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {
                    pendingDeleteIDs = []
                }
                Button("删除", role: .destructive) {
                    confirmDeleteConfigs()
                }
            } message: {
                Text("删除后将无法恢复。")
            }
        }
    }

    private func requestDeleteConfigs(at offsets: IndexSet) {
        pendingDeleteIDs = offsets.map { configs[$0].id }
        showDeleteConfirm = !pendingDeleteIDs.isEmpty
    }

    private func confirmDeleteConfigs() {
        let ids = Set(pendingDeleteIDs)
        for config in configs where ids.contains(config.id) {
            modelContext.delete(config)
        }
        pendingDeleteIDs = []
        try? modelContext.save()
    }

    private func moveConfigs(from source: IndexSet, to destination: Int) {
        var reordered = configs
        reordered.move(fromOffsets: source, toOffset: destination)
        let base = Date()
        for (index, config) in reordered.enumerated() {
            // 通过更新创建时间编码顺序，配合 .forward 排序实现稳定位置。
            config.createdAt = base.addingTimeInterval(TimeInterval(index))
        }
        try? modelContext.save()
    }
}

/// 表单项：API 名称、列表 URL、详情 URL、组件类型、字段映射；容错红色提示 + 测试解析
struct APIConfigFormView: View {
    @Bindable var config: APIConfig
    var onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var testItems: [ListItemModel] = []
    @State private var testLoading = false
    @State private var testError: String?
    @State private var listAvailablePaths: [String] = []
    @State private var detailAvailablePaths: [String] = []
    @State private var listSuggestionsLoading = false
    @State private var detailSuggestionsLoading = false
    @Environment(\.colorScheme) private var colorScheme

    private let apiService = APIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: Binding(
                        get: { config.name },
                        set: { config.name = $0 }
                    ))
                    TextField("列表 API URL *", text: Binding(
                        get: { config.listAPIURL },
                        set: { config.listAPIURL = $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    TextField("详情 API URL *", text: Binding(
                        get: { config.detailAPIURL ?? "" },
                        set: { config.detailAPIURL = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Picker("组件类型", selection: Binding(
                        get: { config.componentType },
                        set: { newType in
                            config.componentType = newType
                            config.listMapping = APIConfig.defaultListMapping(for: newType)
                            config.detailMapping = APIConfig.defaultDetailMapping()
                        }
                    )) {
                        Text("图文列表").tag("card")
                        Text("视频列表").tag("video")
                        Text("图表列表").tag("chart")
                    }
                }

                Section {
                    ForEach(APIConfig.standardListKeys, id: \.self) { uiKey in
                        FieldMappingRow(
                            uiKey: uiKey,
                            backendKey: config.listMapping[uiKey] ?? "",
                            availablePaths: listAvailablePaths,
                            error: missingListKey(uiKey)
                        ) { newValue in
                            var map = config.listMapping
                            map[uiKey] = newValue
                            config.listMapping = map
                        }
                    }
                } header: {
                    HStack {
                        Text("列表字段映射")
                        Spacer()
                        if listSuggestionsLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("获取建议") {
                                fetchSuggestions(isList: true)
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.accentColor(colorScheme))
                            .disabled(config.listAPIURL.isEmpty)
                        }
                    }
                }

                if config.componentType != "chart" {
                    Section {
                        ForEach(APIConfig.standardDetailKeys, id: \.self) { uiKey in
                            FieldMappingRow(
                                uiKey: uiKey,
                                backendKey: config.detailMapping[uiKey] ?? "",
                                availablePaths: detailAvailablePaths,
                                error: false
                            ) { newValue in
                                var map = config.detailMapping
                                map[uiKey] = newValue
                                config.detailMapping = map
                            }
                        }
                    } header: {
                        HStack {
                            Text("详情字段映射")
                            Spacer()
                            if detailSuggestionsLoading {
                                ProgressView().controlSize(.small)
                            } else {
                                Button("获取建议") {
                                    fetchSuggestions(isList: false)
                                }
                                .font(.caption)
                                .foregroundStyle(AppTheme.accentColor(colorScheme))
                                .disabled((config.detailAPIURL ?? "").isEmpty)
                            }
                        }
                    }
                }

                if config.componentType == "chart" {
                    Section {
                        ForEach(APIConfig.standardChartKeys, id: \.self) { uiKey in
                            FieldMappingRow(
                                uiKey: uiKey,
                                backendKey: config.detailMapping[uiKey] ?? "",
                                availablePaths: detailAvailablePaths,
                                error: false
                            ) { newValue in
                                var map = config.detailMapping
                                map[uiKey] = newValue
                                config.detailMapping = map
                            }
                        }
                    } header: {
                        HStack {
                            Text("图表数据映射（详情）")
                            Spacer()
                            if detailSuggestionsLoading {
                                ProgressView().controlSize(.small)
                            } else {
                                Button("获取建议") {
                                    fetchSuggestions(isList: false)
                                }
                                .font(.caption)
                                .foregroundStyle(AppTheme.accentColor(colorScheme))
                                .disabled((config.detailAPIURL ?? "").isEmpty)
                            }
                        }
                    } footer: {
                        Text("支持配置 chart_data/chart_x/chart_y 等。")
                    }
                }

                Section("即时预览") {
                    Button {
                        testParse()
                    } label: {
                        HStack {
                            Label("测试解析", systemImage: "play.circle")
                            if testLoading { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(config.listAPIURL.isEmpty || testLoading)
                    if let err = testError {
                        Text(err)
                            .foregroundStyle(AppTheme.errorColor(colorScheme))
                            .font(.caption)
                    }
                    if !testItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(testItems.prefix(5)) { item in
                                    if config.componentType == "chart" {
                                        ChartCardView(item: item, fieldMapping: config.listMapping)
                                            .frame(width: 168)
                                    } else {
                                        DynamicCardView(item: item, showPlayButton: config.componentType == "video")
                                            .frame(width: 168)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("编辑配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        try? modelContext.save()
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }

    private func missingListKey(_ uiKey: String) -> Bool {
        let key = config.listMapping[uiKey] ?? ""
        return key.trimmingCharacters(in: .whitespaces).isEmpty && uiKey == "ui_id"
    }

    private func testParse() {
        testError = nil
        testItems = []
        testLoading = true
        Task {
            do {
                let (raw, _) = try await apiService.fetchList(urlString: config.listAPIURL)
                let list = MappingEngine.parseList(rawItems: raw, fieldMapping: config.listMapping)
                await MainActor.run {
                    testItems = list
                    testLoading = false
                }
            } catch {
                await MainActor.run {
                    testError = error.localizedDescription
                    testLoading = false
                }
            }
        }
    }

    private func fetchSuggestions(isList: Bool) {
        if isList {
            listSuggestionsLoading = true
        } else {
            detailSuggestionsLoading = true
        }
        
        Task {
            do {
                let url = isList ? config.listAPIURL : (config.detailAPIURL ?? "")
                if isList {
                    let (raw, _) = try await apiService.fetchList(urlString: url)
                    if let first = raw.first {
                        let paths = JsonPathService.shared.generatePaths(from: first)
                        await MainActor.run {
                            self.listAvailablePaths = paths
                            self.listSuggestionsLoading = false
                        }
                    } else {
                        await MainActor.run { self.listSuggestionsLoading = false }
                    }
                } else {
                    // 对于详情 API，我们需要一个示例 ID 来获取结构。
                    // 假设我们可以先从列表 API 获取第一个 ID，或者要求用户先配置列表映射。
                    // 为了简化，这里尝试请求列表 API 获取一个 ID 来请求详情 API。
                    let (listRaw, _) = try await apiService.fetchList(urlString: config.listAPIURL)
                    if let firstItemDict = listRaw.first {
                        // 使用 ListItemModel.from 自动处理 JsonPath 等复杂的 ID 提取逻辑
                        let listItem = ListItemModel.from(json: firstItemDict, mapping: config.listMapping)
                        let sampleId = listItem.id
                        
                        if !sampleId.isEmpty {
                            let detailRaw = try await apiService.fetchDetail(urlString: url, id: sampleId)
                            // 关键修复：使用 anyValue 将 JSONValue 转换为原生的 [String: Any] 结构
                            // 这样 generatePaths 才能递归提取所有嵌套路径（如 $.chartData[*].x）
                            if let detailDict = detailRaw.anyValue as? [String: Any] {
                                let paths = JsonPathService.shared.generatePaths(from: detailDict)
                                await MainActor.run {
                                    self.detailAvailablePaths = paths
                                    self.detailSuggestionsLoading = false
                                }
                            } else {
                                throw APIError.decode("详情接口返回的数据格式不满足解析要求")
                            }
                        } else {
                            throw APIError.decode("无法从列表项中提取 ID，请检查 'ui_id' 映射是否正确。")
                        }
                    } else {
                        throw APIError.decode("列表数据为空，无法获取示例 ID。")
                    }
                }
            } catch {
                await MainActor.run {
                    self.testError = "获取建议失败: \(error.localizedDescription)"
                    self.listSuggestionsLoading = false
                    self.detailSuggestionsLoading = false
                }
            }
        }
    }
}

struct FieldMappingRow: View {
    let uiKey: String
    let backendKey: String
    let availablePaths: [String]
    let error: Bool
    let onCommit: (String) -> Void
    @State private var text: String = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(uiKey)
                .font(.subheadline)
                .foregroundStyle(error ? AppTheme.errorColor(colorScheme) : AppTheme.primaryTextColor(colorScheme))
                .frame(width: 80, alignment: .leading)
            
            TextField("后端 Key / JsonPath", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .onChange(of: text) { _, new in onCommit(new) }
                .onChange(of: backendKey) { _, new in text = new }
                .onAppear { text = backendKey }
            
            if !availablePaths.isEmpty {
                Menu {
                    ForEach(availablePaths, id: \.self) { path in
                        Button(path) {
                            text = path
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet.indent")
                        .foregroundStyle(AppTheme.accentColor(colorScheme))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }
}

#Preview {
    ConfigView()
        .modelContainer(for: APIConfig.self, inMemory: true)
}
