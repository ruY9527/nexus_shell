//
//  CompletionPopupView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  命令自动补全弹窗
//

import SwiftUI

/// 命令自动补全弹窗
struct CompletionPopupView: View {
    let completions: [CompletionItem]
    @Binding var selectedIndex: Int
    let onSelect: (CompletionItem) -> Void
    let onDismiss: () -> Void

    var body: some View {
        if completions.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // 标题栏
                HStack {
                    Text("Completions")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)

                    Spacer()

                    Text("\(completions.count) items")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.6))

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                    }
                    .accessibilityIdentifier("completionPopup.close")
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(AppColors.accent.opacity(0.1))

                // 补全列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(completions.enumerated()), id: \.element.id) { index, item in
                                CompletionRowView(
                                    item: item,
                                    isSelected: index == selectedIndex,
                                    index: index
                                )
                                .id(index)
                                .onTapGesture {
                                    onSelect(item)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            .background(AppColors.cardBackground)
            .cornerRadius(DesignSystem.Radius.md)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// 补全行视图
struct CompletionRowView: View {
    let item: CompletionItem
    let isSelected: Bool
    let index: Int

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // 来源图标
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(sourceColor)
                    .frame(width: 16)
            }

            // 补全文本
            Text(item.displayText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)

            Spacer()

            // 来源标签
            Text(item.source.rawValue)
                .font(.system(size: 9))
                .foregroundStyle(AppColors.secondaryText.opacity(0.6))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(AppColors.secondaryText.opacity(0.1))
                .cornerRadius(3)

            // 描述
            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
                    .frame(maxWidth: 80, alignment: .trailing)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(isSelected ? AppColors.accent.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .accessibilityIdentifier("completionPopup.item.\(index)")
    }

    private var sourceColor: Color {
        switch item.source {
        case .builtIn:
            return AppColors.accent
        case .history:
            return AppColors.warning
        case .path:
            return AppColors.online
        case .argument:
            return AppColors.secondaryText
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedIndex = 0

        var body: some View {
            CompletionPopupView(
                completions: [
                    CompletionItem(text: "git pull", description: "Fetch and merge", icon: "terminal", score: 100, source: .builtIn),
                    CompletionItem(text: "git push", description: "Push to remote", icon: "terminal", score: 90, source: .builtIn),
                    CompletionItem(text: "git status", description: "Show status", icon: "terminal", score: 80, source: .history),
                    CompletionItem(text: "/var/log/", description: "Directory", icon: "folder.fill", score: 50, source: .path),
                ],
                selectedIndex: $selectedIndex,
                onSelect: { _ in },
                onDismiss: {}
            )
            .frame(width: 350)
            .padding()
            .background(Color.gray.opacity(0.3))
        }
    }

    return PreviewWrapper()
}
