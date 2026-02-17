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
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(AppTheme.borderColor(colorScheme).opacity(0.3))
                .frame(height: 140)
            
            Divider()
                .background(AppTheme.borderColor(colorScheme))
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.borderColor(colorScheme).opacity(0.4))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.borderColor(colorScheme).opacity(0.2))
                    .frame(height: 13)
                    .padding(.trailing, 40)
            }
            .padding(12)
        }
        .githubCardStyle(colorScheme: colorScheme)
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
