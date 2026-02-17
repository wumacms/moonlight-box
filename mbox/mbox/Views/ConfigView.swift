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
    @Query(sort: \APIConfig.updatedAt, order: .reverse) private var configs: [APIConfig]
    @State private var showAddSheet = false
    @State private var editingConfig: APIConfig?
    @State private var pendingDeleteIDs: [UUID] = []
    @State private var showDeleteConfirm = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.moonSilver(colorScheme)
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
            // 通过更新时间编码顺序，避免引入 SwiftData 模型迁移字段。
            config.updatedAt = base.addingTimeInterval(-TimeInterval(index))
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
    @Environment(\.colorScheme) private var colorScheme

    private let apiService = APIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: Binding(
                        get: { config.name },
                        set: { config.name = $0; config.updatedAt = Date() }
                    ))
                    TextField("列表 API URL", text: Binding(
                        get: { config.listAPIURL },
                        set: { config.listAPIURL = $0; config.updatedAt = Date() }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    TextField("详情 API URL（不含 id 参数，可选）", text: Binding(
                        get: { config.detailAPIURL ?? "" },
                        set: { config.detailAPIURL = $0.isEmpty ? nil : $0; config.updatedAt = Date() }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Picker("组件类型", selection: Binding(
                        get: { config.componentType },
                        set: { newType in
                            config.componentType = newType
                            config.fieldMapping = APIConfig.defaultListMapping(for: newType)
                            config.updatedAt = Date()
                        }
                    )) {
                        Text("卡片").tag("card")
                        Text("视频").tag("video")
                        Text("图表").tag("chart")
                    }
                }

                Section("字段映射（后端 Key → 标准属性）") {
                    ForEach(APIConfig.standardListKeys, id: \.self) { uiKey in
                        FieldMappingRow(
                            uiKey: uiKey,
                            backendKey: config.fieldMapping[uiKey] ?? "",
                            error: missingBackendKey(uiKey)
                        ) { newValue in
                            var map = config.fieldMapping
                            map[uiKey] = newValue
                            config.fieldMapping = map
                            config.updatedAt = Date()
                        }
                    }
                }

                if config.componentType == "chart" {
                    Section("图表数据映射（可选）") {
                        ForEach(APIConfig.standardChartKeys, id: \.self) { uiKey in
                            FieldMappingRow(
                                uiKey: uiKey,
                                backendKey: config.fieldMapping[uiKey] ?? "",
                                error: false
                            ) { newValue in
                                var map = config.fieldMapping
                                map[uiKey] = newValue
                                config.fieldMapping = map
                                config.updatedAt = Date()
                            }
                        }
                        Text("支持配置 data_key/x_key/y_key：例如 chart_data=series, chart_x=month, chart_y=uv。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(AppTheme.fieldError)
                            .font(.caption)
                    }
                    if !testItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(testItems.prefix(5)) { item in
                                    if config.componentType == "chart" {
                                        ChartCardView(item: item, fieldMapping: config.fieldMapping)
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

    private func missingBackendKey(_ uiKey: String) -> Bool {
        let key = config.fieldMapping[uiKey] ?? ""
        return key.trimmingCharacters(in: .whitespaces).isEmpty && uiKey == "ui_id"
    }

    private func testParse() {
        testError = nil
        testItems = []
        testLoading = true
        Task {
            do {
                let (raw, _) = try await apiService.fetchList(urlString: config.listAPIURL)
                let list = MappingEngine.parseList(rawItems: raw, fieldMapping: config.fieldMapping)
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
}

struct FieldMappingRow: View {
    let uiKey: String
    let backendKey: String
    let error: Bool
    let onCommit: (String) -> Void
    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(uiKey)
                .foregroundStyle(error ? AppTheme.fieldError : .primary)
            TextField("后端 Key", text: $text)
                .textInputAutocapitalization(.never)
                .onChange(of: text) { _, new in onCommit(new) }
                .onChange(of: backendKey) { _, new in text = new }
                .onAppear { text = backendKey }
        }
    }
}

#Preview {
    ConfigView()
        .modelContainer(for: APIConfig.self, inMemory: true)
}
