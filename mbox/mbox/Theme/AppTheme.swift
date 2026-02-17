//
//  AppTheme.swift
//  mbox
//
//  GitHub (Primer) 主题风格
//

import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 6
    static let cardPadding: CGFloat = 16
    static let borderWidth: CGFloat = 1
    
    // MARK: - Colors
    
    /// 背景色
    static func backgroundColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.07, blue: 0.09) : Color(red: 1.0, green: 1.0, blue: 1.0) // #0d1117 : #ffffff
    }
    
    /// 次级背景色 (侧边栏、搜索框等)
    static func secondaryBackgroundColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.09, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.97, blue: 0.98) // #161b22 : #f6f8fa
    }
    
    /// 边框颜色
    static func borderColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.19, green: 0.21, blue: 0.24) : Color(red: 0.82, green: 0.84, blue: 0.87) // #30363d : #d0d7de
    }
    
    /// 主文字颜色
    static func primaryTextColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.79, green: 0.82, blue: 0.85) : Color(red: 0.14, green: 0.16, blue: 0.18) // #c9d1d9 : #24292f
    }
    
    /// 次要文字颜色
    static func secondaryTextColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.55, green: 0.58, blue: 0.62) : Color(red: 0.34, green: 0.38, blue: 0.42) // #8b949e : #57606a
    }
    
    /// 链接/强调色 (Blue)
    static func accentColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.35, green: 0.65, blue: 1.0) : Color(red: 0.04, green: 0.41, blue: 0.85) // #58a6ff : #0969da
    }
    
    /// 成功色 (Green)
    static func successColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.25, green: 0.73, blue: 0.31) : Color(red: 0.1, green: 0.5, blue: 0.22) // #3fb950 : #1a7f37
    }
    
    /// 警告色 (Orange)
    static func warningColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.84, green: 0.44, blue: 0.16) : Color(red: 0.6, green: 0.3, blue: 0.0) // #d29922(ish)
    }

    /// 错误色 (Red)
    static func errorColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.96, green: 0.36, blue: 0.34) : Color(red: 0.82, green: 0.2, blue: 0.16) // #f85149 : #cf222e
    }

    // MARK: - Components Style
    
    /// GitHub 风格卡片修饰符
    struct GitHubCardModifier: ViewModifier {
        var colorScheme: ColorScheme
        func body(content: Content) -> some View {
            content
                .background(AppTheme.secondaryBackgroundColor(colorScheme))
                .cornerRadius(AppTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.borderColor(colorScheme), lineWidth: AppTheme.borderWidth)
                )
        }
    }
}

extension View {
    func githubCardStyle(colorScheme: ColorScheme) -> some View {
        self.modifier(AppTheme.GitHubCardModifier(colorScheme: colorScheme))
    }
}
