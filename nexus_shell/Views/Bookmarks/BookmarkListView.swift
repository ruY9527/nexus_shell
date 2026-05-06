//
//  BookmarkListView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  命令书签列表视图
//

import SwiftUI

/// 书签管理视图
struct BookmarkListView: View {
    @StateObject private var store = BookmarkStore.shared
    @State private var searchText: String = ""
    @State private var isEditing: Bool = false
    @State private var showingAddBookmark: Bool = false
    @State private var showingAddGroup: Bool = false
    @State private var selectedBookmark: CommandBookmark?
    @State private var editingBookmark: CommandBookmark?
    @State private var editingGroup: BookmarkGroup?

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
        NavigationStack {
            VStack(spacing: 0) {
                if store.bookmarks.isEmpty && store.groups.isEmpty {
                    emptyStateView
                } else {
                    bookmarkList
                }
            }
            .background(AppColors.background)
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddBookmark = true
                        } label: {
                            Label("New Bookmark", systemImage: "bookmark.fill")
                        }

                        Button {
                            showingAddGroup = true
                        } label: {
                            Label("New Group", systemImage: "folder.fill.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.accent)
                    }
                    .accessibilityIdentifier("bookmark.addMenu")
                }
            }
            .searchable(text: $searchText, prompt: "Search bookmarks...")
            .sheet(isPresented: $showingAddBookmark) {
                BookmarkEditSheet(
                    bookmark: nil,
                    groups: store.groups,
                    onSave: { bookmark in
                        store.addBookmark(bookmark)
                    }
                )
            }
            .sheet(item: $editingBookmark) { bookmark in
                BookmarkEditSheet(
                    bookmark: bookmark,
                    groups: store.groups,
                    onSave: { updated in
                        store.updateBookmark(updated)
                    }
                )
            }
            .sheet(isPresented: $showingAddGroup) {
                GroupEditSheet(
                    group: nil,
                    onSave: { group in
                        store.addGroup(group)
                    }
                )
            }
            .sheet(item: $editingGroup) { group in
                GroupEditSheet(
                    group: group,
                    onSave: { updated in
                        store.updateGroup(updated)
                    }
                )
            }
            .onAppear {
                store.initializePresetsIfNeeded()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))

            Text("No Bookmarks")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)

            Text("Add bookmarks for quick access to your favorite commands")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    showingAddBookmark = true
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Add Bookmark")
                    }
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(AppColors.primaryGradient)
                    .cornerRadius(DesignSystem.Radius.md)
                }
                .accessibilityIdentifier("bookmark.empty.addBookmark")

                Button {
                    store.initializePresetsIfNeeded()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Load Preset Bookmarks")
                    }
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(AppColors.accent.opacity(0.2))
                    .cornerRadius(DesignSystem.Radius.md)
                }
                .accessibilityIdentifier("bookmark.empty.loadPresets")
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bookmarkList: some View {
        List {
            ForEach(groupedBookmarks, id: \.0?.id) { group, bookmarks in
                Section {
                    ForEach(bookmarks) { bookmark in
                        BookmarkRowView(
                            bookmark: bookmark,
                            isEditing: isEditing,
                            onTap: {
                                store.useBookmark(bookmark)
                            },
                            onEdit: {
                                editingBookmark = bookmark
                            },
                            onDelete: {
                                store.deleteBookmark(bookmark)
                            }
                        )
                    }
                } header: {
                    if let group = group {
                        BookmarkGroupHeaderView(
                            group: group,
                            bookmarkCount: bookmarks.count,
                            isEditing: isEditing,
                            onEdit: {
                                editingGroup = group
                            },
                            onDelete: {
                                store.deleteGroup(group)
                            }
                        )
                    } else {
                        Text("Ungrouped")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Bookmark Row View

struct BookmarkRowView: View {
    let bookmark: CommandBookmark
    let isEditing: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: bookmark.color).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: bookmark.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: bookmark.color))
            }

            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(bookmark.name)
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.primaryText)

                    if bookmark.requiresAdmin {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.warning)
                    }
                }

                Text(bookmark.command)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)

                if let description = bookmark.description, !description.isEmpty {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // 使用次数
            if bookmark.useCount > 0 {
                Text("\(bookmark.useCount)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.secondaryText.opacity(0.1))
                    .cornerRadius(4)
            }

            if isEditing {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookmarkRow.edit.\(bookmark.name)")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColors.offline)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookmarkRow.delete.\(bookmark.name)")
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .listRowBackground(AppColors.cardBackground)
        .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.xs, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.xs, trailing: DesignSystem.Spacing.md))
        .accessibilityIdentifier("bookmarkRow.\(bookmark.name)")
    }
}

// MARK: - Bookmark Group Header View

struct BookmarkGroupHeaderView: View {
    let group: BookmarkGroup
    let bookmarkCount: Int
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: group.icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: group.color))

            Text(group.name)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.accent)

            Spacer()

            Text("\(bookmarkCount)")
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)

            if isEditing {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookmarkGroup.edit.\(group.name)")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.offline)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookmarkGroup.delete.\(group.name)")
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    BookmarkListView()
}
