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
                        // 不再立即 modelContext.insert(new)，而是先进入编辑
                        editingConfig = new
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $editingConfig) { config in
                APIConfigFormView(config: config, onDismiss: { configToSave in
                    if let configToSave {
                        // 检查必填项：如果名称和 URL 都为空，视为无效，不保留
                        if configToSave.name.isEmpty && configToSave.listAPIURL.isEmpty {
                            // 如果是新创建但未保存的（不在数据库中），则无需操作
                            // 如果已在数据库中，则删除
                            if configs.contains(where: { $0.id == configToSave.id }) {
                                modelContext.delete(configToSave)
                            }
                        } else {
                            // 有效配置：若是新配置则插入
                            if !configs.contains(where: { $0.id == configToSave.id }) {
                                modelContext.insert(configToSave)
                            }
                            try? modelContext.save()
                        }
                    }
                    editingConfig = nil
                })
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
    var config: APIConfig
    var onDismiss: (APIConfig?) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // --- 临时状态变量 ---
    @State private var name: String = ""
    @State private var listAPIURL: String = ""
    @State private var detailAPIURL: String = ""
    @State private var componentType: String = "card"
    @State private var httpMethod: String = "GET"
    @State private var listMapping: [String: String] = [:]
    @State private var detailMapping: [String: String] = [:]
    
    @State private var testItems: [ListItemModel] = []
    @State private var testLoading = false
    @State private var testError: String?
    @State private var listAvailablePaths: [String] = []
    @State private var detailAvailablePaths: [String] = []
    @State private var listSuggestionsLoading = false
    @State private var detailSuggestionsLoading = false
    @State private var headersText: String = "" // 用于编辑 Header 的 JSON 字符串
    @State private var headersError: String?
    @Environment(\.colorScheme) private var colorScheme

    private let apiService = APIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                    TextField("列表 API URL *", text: $listAPIURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    TextField("详情 API URL *", text: $detailAPIURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Picker("组件类型", selection: $componentType) {
                        Text("图文列表").tag("card")
                        Text("视频列表").tag("video")
                        Text("图表列表").tag("chart")
                    }
                }
                
                Section("请求设置") {
                    Picker("HTTP 方法", selection: $httpMethod) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("自定义 Header (JSON)")
                                .font(.subheadline)
                            Spacer()
                            if let error = headersError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.errorColor(colorScheme))
                            }
                        }
                        
                        TextEditor(text: $headersText)
                            .frame(height: 100)
                            .font(.system(.body, design: .monospaced))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .onAppear {
                                if let data = try? JSONEncoder().encode(headers),
                                   let json = String(data: data, encoding: .utf8) {
                                    headersText = json
                                }
                            }
                            .onChange(of: headersText) { _, newValue in
                                validateAndSaveHeaders(newValue)
                            }
                    }
                    .padding(.vertical, 4)
                }
                .onAppear {
                    // 初始化临时状态
                    name = config.name
                    listAPIURL = config.listAPIURL
                    detailAPIURL = config.detailAPIURL ?? ""
                    componentType = config.componentType
                    httpMethod = config.httpMethod
                    listMapping = config.listMapping
                    detailMapping = config.detailMapping
                    
                    if let data = try? JSONEncoder().encode(config.headers),
                       let json = String(data: data, encoding: .utf8) {
                        headersText = json
                    }
                }
                .onChange(of: componentType) { _, newType in
                    // 类型切换时重置映射建议
                    if newType != config.componentType {
                        listMapping = APIConfig.defaultListMapping(for: newType)
                        detailMapping = APIConfig.defaultDetailMapping()
                    } else {
                        listMapping = config.listMapping
                        detailMapping = config.detailMapping
                    }
                }

                Section {
                    ForEach(APIConfig.standardListKeys.filter { key in
                        if componentType == "chart" && (key == "ui_image" || key == "ui_badge") { return false }
                        return true
                    }, id: \.self) { uiKey in
                        FieldMappingRow(
                            uiKey: uiKey,
                            backendKey: listMapping[uiKey] ?? "",
                            availablePaths: listAvailablePaths,
                            error: missingListKey(uiKey)
                        ) { newValue in
                            listMapping[uiKey] = newValue
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
                            .disabled(listAPIURL.isEmpty)
                        }
                    }
                }

                if componentType != "chart" {
                    Section {
                        ForEach(APIConfig.standardDetailKeys, id: \.self) { uiKey in
                            FieldMappingRow(
                                uiKey: uiKey,
                                backendKey: detailMapping[uiKey] ?? "",
                                availablePaths: detailAvailablePaths,
                                error: false
                            ) { newValue in
                                detailMapping[uiKey] = newValue
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
                                .disabled(detailAPIURL.isEmpty)
                            }
                        }
                    }
                }

                if componentType == "chart" {
                    Section {
                        ForEach(APIConfig.standardChartKeys, id: \.self) { uiKey in
                            FieldMappingRow(
                                uiKey: uiKey,
                                backendKey: detailMapping[uiKey] ?? "",
                                availablePaths: detailAvailablePaths,
                                error: false
                            ) { newValue in
                                detailMapping[uiKey] = newValue
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
                                .disabled(detailAPIURL.isEmpty)
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
                    .disabled(listAPIURL.isEmpty || testLoading)
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
                    Button("取消") {
                        dismiss()
                        onDismiss(nil)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        validateAndSaveHeaders(headersText)
                        // 将状态写回模型
                        config.name = name
                        config.listAPIURL = listAPIURL
                        config.detailAPIURL = detailAPIURL.isEmpty ? nil : detailAPIURL
                        config.componentType = componentType
                        config.httpMethod = httpMethod
                        config.listMapping = listMapping
                        config.detailMapping = detailMapping
                        
                        dismiss()
                        onDismiss(config)
                    }
                }
            }
        }
    }

    private func validateAndSaveHeaders(_ json: String) {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // 注意：这里更新临时状态变量（如果有需要的话），或者在此处直接处理 config.headers
            // 为了保持一致性，我们在保存时统一写回
            headersError = nil
            return
        }
        
        guard let data = trimmed.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            headersError = "JSON 格式非法或非 [String: String]"
            return
        }
        
        // 验证通过，等待点击“保存”时应用
        headersError = nil
    }

    private var headers: [String: String] {
        guard let data = headersText.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return dict
    }

    private func missingListKey(_ uiKey: String) -> Bool {
        let key = listMapping[uiKey] ?? ""
        return key.trimmingCharacters(in: .whitespaces).isEmpty && uiKey == "ui_id"
    }

    private func testParse() {
        testError = nil
        testItems = []
        testLoading = true
        Task {
            do {
                let (raw, _) = try await apiService.fetchList(
                    urlString: listAPIURL,
                    method: httpMethod,
                    headers: headers
                )
                let list = MappingEngine.parseList(rawItems: raw, fieldMapping: listMapping)
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
                let url = isList ? listAPIURL : detailAPIURL
                if isList {
                    let (raw, _) = try await apiService.fetchList(
                        urlString: url,
                        method: httpMethod,
                        headers: headers
                    )
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
                    let (listRaw, _) = try await apiService.fetchList(
                        urlString: listAPIURL,
                        method: httpMethod,
                        headers: headers
                    )
                    if let firstItemDict = listRaw.first {
                        let listItem = ListItemModel.from(json: firstItemDict, mapping: listMapping)
                        var sampleId = listItem.id
                        
                        // 兜底逻辑：如果映射后的 ID 为空，尝试直接从原始 JSON 中找 'id'
                        if sampleId.isEmpty {
                            sampleId = (firstItemDict["id"] as? String) ?? (firstItemDict["id"] as? Int).map { String($0) } ?? ""
                        }
                        
                        if !sampleId.isEmpty {
                            let detailRaw = try await apiService.fetchDetail(
                                urlString: url,
                                id: sampleId,
                                method: httpMethod,
                                headers: headers
                            )
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
