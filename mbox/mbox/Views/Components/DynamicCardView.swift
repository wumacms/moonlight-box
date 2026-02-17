//
//  DynamicCardView.swift
//  mbox
//
//  GitHub 风格的列表项卡片
//

import SwiftUI

struct DynamicCardView: View {
    let item: ListItemModel
    var showPlayButton: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片部分
            if let urlString = item.uiImage, !urlString.isEmpty, let url = URL(string: urlString) {
                ZStack {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(AppTheme.secondaryBackgroundColor(colorScheme))
                                .overlay(ProgressView())
                                .frame(height: 140)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(height: 140)
                        case .failure:
                            Rectangle()
                                .fill(AppTheme.secondaryBackgroundColor(colorScheme))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                                )
                                .frame(height: 140)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    if showPlayButton {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .frame(height: 140)
                .clipped()
                
                Divider()
                    .background(AppTheme.borderColor(colorScheme))
            }
            
            // 内容部分
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.uiTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accentColor(colorScheme))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let badge = item.uiBadge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.borderColor(colorScheme), lineWidth: 1)
                            )
                            .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                    }
                }
                
                if !item.uiSubtitle.isEmpty {
                    Text(item.uiSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
        }
        .githubCardStyle(colorScheme: colorScheme)
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
