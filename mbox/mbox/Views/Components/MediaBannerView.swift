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
    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .onAppear {
                    let playerItem = AVPlayerItem(url: url)
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    player = newPlayer
                    
                    // 监听视频是否准备好播放
                    playerItem.publisher(for: \.status)
                        .receive(on: DispatchQueue.main)
                        .sink { status in
                            if status == .readyToPlay {
                                isLoading = false
                            }
                        }
                        .store(in: &cancellables)
                }
                .onDisappear {
                    player?.pause()
                }

            if isLoading {
                Rectangle()
                    .fill(AppTheme.secondaryBackgroundColor(colorScheme))
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("视频解析中...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    // 使用 State 保持订阅，防止被释放
    @State private var cancellables = Set<AnyCancellable>()
}

import Combine
