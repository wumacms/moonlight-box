//
//  AppTheme.swift
//  mbox
//
//  月光银 + 深邃蓝，12pt 圆角，支持深色模式
//

import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let largeTitleSize: CGFloat = 34

    /// 月光银（浅色下背景/卡片）
    static func moonSilver(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.96)
    }

    /// 深邃蓝（主色/强调）
    static func deepBlue(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.35, green: 0.5, blue: 0.85)
            : Color(red: 0.15, green: 0.25, blue: 0.45)
    }

    /// 错误/缺失字段高亮
    static var fieldError: Color { .red }

    /// 卡片背景（Material 感）
    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
    }
}
