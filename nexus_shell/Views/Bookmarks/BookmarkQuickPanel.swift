//
//  BookmarkQuickPanel.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  终端书签快速访问面板
//

import SwiftUI

/// 书签快速访问面板
struct BookmarkQuickPanel: View {
    @StateObject private var store = BookmarkStore.shared
    @State private var searchText: String = ""
    let onExecute: (CommandBookmark) -> Void
    let onDismiss: () -> Void

    private var filteredBookmarks: [CommandBookmark] {
        if searchText.isEmpty {
            return store.bookmarks
        }
        return store.search(searchText)
    }

    private var groupedBookmarks: [(BookmarkGroup?, [CommandBookmark])] {
        var result: [(BookmarkGroup?, [CommandBookmark])] = []
        var groupedDict: [UUID?: [CommandBookmark]] = [:]

        for bookmark in filteredBookmarks {
            groupedDict[bookmark.groupId, default: []].append(bookmark)
        }

        // 无分组的书签
        if let ungrouped = groupedDict[nil], !ungrouped.isEmpty {
            result.append((nil, ungrouped))
        }

        // 有分组的书签
        for group in store.groups.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if let bookmarks = groupedDict[group.id], !bookmarks.isEmpty {
                result.append((group, bookmarks))
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("Bookmarks")
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.accent)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                }
                .accessibilityIdentifier("bookmarkQuickPanel.close")
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(AppColors.accent.opacity(0.1))

            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                TextField("Search bookmarks...", text: $searchText)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.primaryText)
                    .accessibilityIdentifier("bookmarkQuickPanel.search")
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(AppColors.cardBackground)
            .cornerRadius(DesignSystem.Radius.sm)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)

            // 书签列表
            if filteredBookmarks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groupedBookmarks, id: \.0?.id) { group, bookmarks in
                            // 分组标题
                            if let group = group {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: group.icon)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color(hex: group.color))

                                    Text(group.name)
                                        .font(AppTypography.labelSmall)
                                        .foregroundStyle(AppColors.accent)

                                    Spacer()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(AppColors.accent.opacity(0.05))
                            }

                            // 书签列表
                            ForEach(bookmarks) { bookmark in
                                QuickBookmarkRow(bookmark: bookmark) {
                                    store.useBookmark(bookmark)
                                    onExecute(bookmark)
                                    onDismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 300)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "bookmark")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))

            Text("No bookmarks found")
                .font(AppTypography.label)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 快速书签行
struct QuickBookmarkRow: View {
    let bookmark: CommandBookmark
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: bookmark.color).opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: bookmark.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: bookmark.color))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(bookmark.name)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.primaryText)
                            .lineLimit(1)

                        if bookmark.requiresAdmin {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(AppColors.warning)
                        }
                    }

                    Text(bookmark.command)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.secondaryText.opacity(0.3))
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bookmarkQuickPanel.item.\(bookmark.name)")
    }
}

/// 书签工具栏按钮
struct BookmarkToolbarButton: View {
    @StateObject private var store = BookmarkStore.shared
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12))

                Text("Bookmarks")
                    .font(AppTypography.labelSmall)

                if store.bookmarks.count > 0 {
                    Text("\(store.bookmarks.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(AppColors.accent)
                        .cornerRadius(8)
                }
            }
            .foregroundStyle(isActive ? AppColors.accent : AppColors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isActive ? AppColors.accent.opacity(0.2) : AppColors.cardBackground)
            .cornerRadius(DesignSystem.Radius.sm)
        }
        .accessibilityIdentifier("terminal.bookmarkButton")
    }
}

// MARK: - Preview

#Preview("Quick Panel") {
    BookmarkQuickPanel(
        onExecute: { bookmark in
            print("Execute: \(bookmark.command)")
        },
        onDismiss: {}
    )
    .frame(width: 350)
    .padding()
    .background(Color.gray.opacity(0.3))
}

#Preview("Toolbar Button") {
    HStack {
        BookmarkToolbarButton(isActive: false) {}
        BookmarkToolbarButton(isActive: true) {}
    }
    .padding()
    .background(AppColors.background)
}
