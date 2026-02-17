//
//  SkeletonCardView.swift
//  mbox
//
//  骨架屏占位卡片，减少加载跳变感
//

import SwiftUI

struct SkeletonCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.moonSilver(colorScheme).opacity(0.6))
                .frame(height: 120)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.moonSilver(colorScheme).opacity(0.5))
                .frame(height: 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.moonSilver(colorScheme).opacity(0.4))
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground())
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

private extension View {
    @ViewBuilder
    func shimmer() -> some View {
        if #available(iOS 17.0, *) {
            self
                .overlay {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.overlay)
                    .mask(self)
                }
        } else {
            self
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        SkeletonCardView()
            .padding()
    }
}
