//
//  MediaBannerView.swift
//  mbox
//
//  根据 componentType 或 URL 扩展名区分：图片用 AsyncImage，视频用 VideoPlayer
//

import SwiftUI
import AVKit

struct MediaBannerView: View {
    let mediaUrl: String
    let componentType: String
    @Environment(\.colorScheme) private var colorScheme

    private var isVideo: Bool {
        if componentType == "video" { return true }
        let lower = mediaUrl.lowercased()
        return lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".m4v") ||
               lower.hasSuffix(".m3u8") || lower.contains("video")
    }

    var body: some View {
        Group {
            if isVideo, let url = URL(string: mediaUrl) {
                VideoBannerView(url: url)
            } else if let url = URL(string: mediaUrl) {
                ImageBannerView(url: url)
            }
        }
        .frame(height: 220)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.borderColor(colorScheme), lineWidth: 1)
        )
        .clipped()
    }
}

private struct ImageBannerView: View {
    let url: URL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(AppTheme.secondaryBackgroundColor(colorScheme))
                    .overlay { ProgressView() }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle()
                    .fill(AppTheme.secondaryBackgroundColor(colorScheme))
                    .overlay { 
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.secondaryTextColor(colorScheme))
                    }
            @unknown default:
                EmptyView()
            }
        }
    }
}

private struct VideoBannerView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
            }
            .onDisappear {
                player?.pause()
            }
    }
}
