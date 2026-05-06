//
//  BookmarkEditSheet.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  书签编辑 Sheet
//

import SwiftUI

/// 书签编辑 Sheet
struct BookmarkEditSheet: View {
    let bookmark: CommandBookmark?
    let groups: [BookmarkGroup]
    let onSave: (CommandBookmark) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var description: String = ""
    @State private var selectedGroupId: UUID?
    @State private var selectedIcon: String = "terminal"
    @State private var selectedColor: String = "#007AFF"
    @State private var requiresAdmin: Bool = false

    @State private var showingIconPicker: Bool = false
    @State private var showingColorPicker: Bool = false
    @State private var showingGroupPicker: Bool = false

    private var isEditing: Bool { bookmark != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let availableIcons = [
        "terminal", "bookmark.fill", "arrow.clockwise", "play.fill", "stop.fill",
        "gearshape.fill", "chart.bar.fill", "cpu.fill", "network", "shippingbox.fill",
        "photo.fill", "doc.text.fill", "person.3.fill", "arrow.down.circle.fill",
        "arrow.up.circle.fill", "arrow.triangle.2.circlepath", "arrow.branch",
        "clock.fill", "archivebox.fill", "cylinder.fill", "antenna.radiowaves.left.and.right",
        "magnifyingglass", "number.circle.fill", "tablecells.fill", "list.bullet.rectangle.fill",
        "folder.fill", "star.fill", "heart.fill", "flag.fill", "tag.fill"
    ]

    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#5856D6",
        "#AF52DE", "#2496ED", "#DC382D", "#336791", "#47A248"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)

                    TextField("Command", text: $command, axis: .vertical)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(3...6)
                } header: {
                    Text("Basic Info")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(2...4)
                } header: {
                    Text("Description")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    Button {
                        showingGroupPicker = true
                    } label: {
                        HStack {
                            Text("Group")
                                .foregroundStyle(AppColors.primaryText)
                            Spacer()
                            if let groupId = selectedGroupId,
                               let group = groups.first(where: { $0.id == groupId }) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: group.icon)
                                        .font(.system(size: 12))
                                    Text(group.name)
                                        .font(AppTypography.bodySmall)
                                }
                                .foregroundStyle(AppColors.secondaryText)
                            } else {
                                Text("None")
                                    .font(AppTypography.bodySmall)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                        }
                    }
                    .accessibilityIdentifier("bookmarkEdit.groupPicker")
                } header: {
                    Text("Group")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button {
                            showingIconPicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColor).opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: selectedColor))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("bookmarkEdit.iconPicker")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("bookmarkEdit.color.\(color)")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Icon & Color")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    Toggle("Requires Admin (sudo)", isOn: $requiresAdmin)
                        .tint(AppColors.accent)
                        .foregroundStyle(AppColors.primaryText)
                        .accessibilityIdentifier("bookmarkEdit.requiresAdmin")
                } header: {
                    Text("Permission")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                } footer: {
                    Text("If enabled, the command will be executed with sudo privileges")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Bookmark" : "New Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("bookmarkEdit.cancel")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveBookmark()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .accessibilityIdentifier("bookmarkEdit.save")
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerSheet(
                    selectedIcon: $selectedIcon,
                    selectedColor: selectedColor,
                    icons: availableIcons
                )
            }
            .sheet(isPresented: $showingGroupPicker) {
                GroupPickerSheet(
                    groups: groups,
                    selectedGroupId: $selectedGroupId
                )
            }
            .onAppear {
                if let bookmark = bookmark {
                    name = bookmark.name
                    command = bookmark.command
                    description = bookmark.description ?? ""
                    selectedGroupId = bookmark.groupId
                    selectedIcon = bookmark.icon
                    selectedColor = bookmark.color
                    requiresAdmin = bookmark.requiresAdmin
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func saveBookmark() {
        let newBookmark = CommandBookmark(
            id: bookmark?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            command: command.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            groupId: selectedGroupId,
            icon: selectedIcon,
            color: selectedColor,
            requiresAdmin: requiresAdmin,
            useCount: bookmark?.useCount ?? 0,
            lastUsedAt: bookmark?.lastUsedAt,
            createdAt: bookmark?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(newBookmark)
        dismiss()
    }
}

// MARK: - Icon Picker Sheet

struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    let selectedColor: String
    let icons: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: DesignSystem.Spacing.md) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : AppColors.cardBackground)
                                    .frame(width: 50, height: 50)

                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : AppColors.secondaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Group Picker Sheet

struct GroupPickerSheet: View {
    let groups: [BookmarkGroup]
    @Binding var selectedGroupId: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedGroupId = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No Group")
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        if selectedGroupId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .listRowBackground(AppColors.cardBackground)
                .accessibilityIdentifier("groupPicker.none")

                ForEach(groups) { group in
                    Button {
                        selectedGroupId = group.id
                        dismiss()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: group.icon)
                                .foregroundStyle(Color(hex: group.color))

                            Text(group.name)
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()

                            if selectedGroupId == group.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }
                    .listRowBackground(AppColors.cardBackground)
                    .accessibilityIdentifier("groupPicker.\(group.name)")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Group Edit Sheet

struct GroupEditSheet: View {
    let group: BookmarkGroup?
    let onSave: (BookmarkGroup) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: String = "#007AFF"

    private var isEditing: Bool { group != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private let availableIcons = [
        "folder.fill", "gearshape.fill", "network", "shippingbox.fill",
        "doc.text.fill", "terminal.fill", "cpu.fill", "chart.bar.fill",
        "star.fill", "heart.fill", "flag.fill", "tag.fill", "bookmark.fill",
        "number.circle.fill", "list.bullet.rectangle.fill"
    ]

    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30", "#5856D6",
        "#AF52DE", "#2496ED", "#DC382D", "#336791", "#47A248"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                } header: {
                    Text("Name")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button {
                            // Icon picker inline
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selectedColor).opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: selectedColor))
                            }
                        }
                        .buttonStyle(.plain)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Color")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : AppColors.cardBackground)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: icon)
                                            .font(.system(size: 18))
                                            .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : AppColors.secondaryText)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Icon")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveGroup()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let group = group {
                    name = group.name
                    selectedIcon = group.icon
                    selectedColor = group.color
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func saveGroup() {
        let newGroup = BookmarkGroup(
            id: group?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor,
            sortOrder: group?.sortOrder ?? (BookmarkStore.shared.groups.count),
            isExpanded: group?.isExpanded ?? true,
            createdAt: group?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(newGroup)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Edit Sheet") {
    BookmarkEditSheet(
        bookmark: nil,
        groups: [
            BookmarkGroup(name: "System", icon: "gearshape.fill", color: "#FF9500"),
            BookmarkGroup(name: "Docker", icon: "shippingbox.fill", color: "#2496ED")
        ],
        onSave: { _ in }
    )
}

#Preview("Group Sheet") {
    GroupEditSheet(
        group: nil,
        onSave: { _ in }
    )
}
