//
//  ContentView.swift
//  mbox
//
//  根视图：Tab 首页 + 配置
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "square.grid.2x2") }
                .tag(0)
            ConfigView()
                .tabItem { Label("配置", systemImage: "gearshape.2") }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: APIConfig.self, inMemory: true)
}
