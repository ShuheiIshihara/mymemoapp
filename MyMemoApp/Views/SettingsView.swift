//
//  SettingsView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import _SwiftData_SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @AppStorage("fontSize") private var fontSize: FontSize = .medium
    @AppStorage("lineSpacing") private var lineSpacing: LineSpacing = .standard
    @AppStorage("editingFont") private var editingFont: EditingFont = .system
    @AppStorage("appearance") private var appearance: AppearanceMode = .system
    @AppStorage("accentColor") private var accentColor: AccentColorChoice = .blue
    
    var body: some View {
        NavigationView {
            List {
                Section("表示設定") {
                    HStack {
                        Text("フォントサイズ")
                        Spacer()
                        Picker("フォントサイズ", selection: $fontSize) {
                            ForEach(FontSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("行間")
                        Spacer()
                        Picker("行間", selection: $lineSpacing) {
                            ForEach(LineSpacing.allCases, id: \.self) { spacing in
                                Text(spacing.displayName).tag(spacing)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("編集フォント")
                        Spacer()
                        Picker("編集フォント", selection: $editingFont) {
                            ForEach(EditingFont.allCases, id: \.self) { font in
                                Text(font.displayName).tag(font)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("テーマ設定") {
                    HStack {
                        Text("外観")
                        Spacer()
                        Picker("外観", selection: $appearance) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("アクセントカラー")
                        Spacer()
                        Picker("アクセントカラー", selection: $accentColor) {
                            ForEach(AccentColorChoice.allCases, id: \.self) { color in
                                HStack {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 16, height: 16)
                                    Text(color.displayName)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("データ管理") {
                    NavigationLink("データ統計") {
                        DataStatisticsView()
                    }
                    
                    Button("ローカルキャッシュクリア") {
                        // TODO: キャッシュクリア機能の実装
                    }
                    .foregroundColor(.blue)
                }
                
                Section("アプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
                        .foregroundColor(.blue)
                    
                    Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("設定")
        }
        .preferredColorScheme(appearance.colorScheme)
        .accentColor(accentColor.color)
    }
}

struct DataStatisticsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Query var allMemos: [Memo]
    @Query var allGroups: [Group]
    
    private var activeMemos: [Memo] {
        allMemos.filter { $0.deletedAt == nil }
    }
    
    private var deletedMemos: [Memo] {
        allMemos.filter { $0.deletedAt != nil }
    }
    
    private var activeGroups: [Group] {
        allGroups.filter { $0.deletedAt == nil }
    }
    
    private var totalCharacters: Int {
        activeMemos.reduce(0) { $0 + $1.content.count }
    }
    
    var body: some View {
        List {
            Section("メモ統計") {
                StatisticRow(title: "アクティブメモ数", value: "\(activeMemos.count)")
                StatisticRow(title: "削除済みメモ数", value: "\(deletedMemos.count)")
                StatisticRow(title: "総文字数", value: "\(totalCharacters.formatted())")
                StatisticRow(title: "平均文字数", value: activeMemos.isEmpty ? "0" : "\((totalCharacters / activeMemos.count).formatted())")
            }
            
            Section("グループ統計") {
                StatisticRow(title: "グループ数", value: "\(activeGroups.count)")
                StatisticRow(title: "未分類メモ数", value: "\(activeMemos.filter { $0.groupId == nil }.count)")
            }
            
            Section("最近の活動") {
                if let latestMemo = activeMemos.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
                    StatisticRow(title: "最終更新", value: formatDate(latestMemo.updatedAt))
                }
                
                if let oldestMemo = activeMemos.sorted(by: { $0.createdAt < $1.createdAt }).first {
                    StatisticRow(title: "最古のメモ", value: formatDate(oldestMemo.createdAt))
                }
            }
        }
        .navigationTitle("データ統計")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings Enums

enum FontSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        case .extraLarge: return "特大"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
}

enum LineSpacing: String, CaseIterable {
    case narrow = "narrow"
    case standard = "standard"
    case wide = "wide"
    
    var displayName: String {
        switch self {
        case .narrow: return "狭い"
        case .standard: return "標準"
        case .wide: return "広い"
        }
    }
    
    var value: CGFloat {
        switch self {
        case .narrow: return 2
        case .standard: return 4
        case .wide: return 6
        }
    }
}

enum EditingFont: String, CaseIterable {
    case system = "system"
    case monospaced = "monospaced"
    
    var displayName: String {
        switch self {
        case .system: return "システム"
        case .monospaced: return "等幅"
        }
    }
    
    var font: Font {
        switch self {
        case .system: return .body
        case .monospaced: return .system(.body, design: .monospaced)
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "ライト"
        case .dark: return "ダーク"
        case .system: return "システム連動"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum AccentColorChoice: String, CaseIterable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case red = "red"
    
    var displayName: String {
        switch self {
        case .blue: return "ブルー"
        case .green: return "グリーン"
        case .orange: return "オレンジ"
        case .purple: return "パープル"
        case .red: return "レッド"
        }
    }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
