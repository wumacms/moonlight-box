//
//  DynamicCardView.swift
//  mbox
//
//  动态解析后的列表项卡片（圆角 12pt）
//

import SwiftUI

struct DynamicCardView: View {
    let item: ListItemModel
    var showPlayButton: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let urlString = item.uiImage, !urlString.isEmpty, let url = URL(string: urlString) {
                ZStack {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.deepBlue(colorScheme))
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    if showPlayButton {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            VStack(alignment: .leading, spacing: 4) {
                if let badge = item.uiBadge, !badge.isEmpty {
                    Text(badge)
                        .font(.caption)
                        .foregroundStyle(AppTheme.deepBlue(colorScheme))
                }
                Text(item.uiTitle)
                    .font(.headline)
                    .lineLimit(2)
                if !item.uiSubtitle.isEmpty {
                    Text(item.uiSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground())
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

#Preview {
    DynamicCardView(item: ListItemModel(
        id: "1",
        uiTitle: "示例标题",
        uiSubtitle: "副标题摘要",
        uiImage: nil,
        uiBadge: "推荐",
        raw: [:]
    ))
    .padding()
}
