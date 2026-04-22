//
//  AddFolderView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 添加文件夹视图
struct AddFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var folderStore = FolderStore.shared
    
    @State private var name: String = ""
    @State private var selectedColor: FolderColor = .blue
    @State private var selectedIcon: FolderIcon = .folder
    @State private var description: String = ""
    
    @FocusState private var nameFieldFocused: Bool
    
    private var settings: AppSettings {
        AppSettings.shared
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section {
                    // 名称
                    TextField("Folder Name", text: $name)
                        .font(AppTypography.body)
                        .focused($nameFieldFocused)
                    
                    // 描述
                    TextField("Description (optional)", text: $description)
                        .font(AppTypography.body)
                } header: {
                    Text("Basic Info")
                }
                
                // 颜色选择
                Section {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(FolderColor.allCases, id: \.self) { color in
                            ColorSelectionButton(
                                color: color,
                                isSelected: selectedColor == color,
                                onTap: {
                                    selectedColor = color
                                    if settings.hapticFeedbackEnabled {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                } header: {
                    Text("Color")
                }
                
                // 图标选择
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.md) {
                        ForEach(FolderIcon.allCases, id: \.self) { icon in
                            IconSelectionButton(
                                icon: icon,
                                color: selectedColor,
                                isSelected: selectedIcon == icon,
                                onTap: {
                                    selectedIcon = icon
                                    if settings.hapticFeedbackEnabled {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                } header: {
                    Text("Icon")
                }
                
                // 预览
                Section {
                    FolderPreviewCard(
                        name: name.isEmpty ? "Folder Name" : name,
                        color: selectedColor,
                        icon: selectedIcon,
                        description: description
                    )
                } header: {
                    Text("Preview")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(String(localized: "New Folder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "Create")) {
                        createFolder()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                nameFieldFocused = true
            }
        }
    }
    
    private func createFolder() {
        let folder = ServerFolder(
            name: name,
            color: selectedColor,
            icon: selectedIcon,
            description: description.isEmpty ? nil : description,
            sortOrder: folderStore.folders.count
        )
        
        folderStore.addFolder(folder)
        
        if settings.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        dismiss()
    }
}

// MARK: - Color Selection Button

struct ColorSelectionButton: View {
    let color: FolderColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                Circle()
                    .fill(color.swiftUIColor)
                    .frame(width: 32, height: 32)
                
                if isSelected {
                    Circle()
                        .stroke(AppColors.primaryText, lineWidth: 3)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Selection Button

struct IconSelectionButton: View {
    let icon: FolderIcon
    let color: FolderColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                    .fill(isSelected ? color.swiftUIColor.opacity(0.3) : AppColors.cardBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon.systemName)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? color.swiftUIColor : AppColors.secondaryText)
            }
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                    .stroke(isSelected ? color.swiftUIColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Preview Card

struct FolderPreviewCard: View {
    let name: String
    let color: FolderColor
    let icon: FolderIcon
    let description: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(color.lightColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon.systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(color.swiftUIColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(name)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                
                if !description.isEmpty {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                Text("0 servers")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.7))
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }
}

#Preview {
    AddFolderView()
}