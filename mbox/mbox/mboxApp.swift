//
//  mboxApp.swift
//  mbox
//
//  Created by devlink on 2026/2/16.
//

import SwiftUI
import SwiftData

@main
struct mboxApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([APIConfig.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData 初始化失败: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
