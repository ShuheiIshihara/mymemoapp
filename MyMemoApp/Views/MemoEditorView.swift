//
//  MemoEditorView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import SwiftData

struct MemoEditorView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    let memo: Memo?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedGroupId: UUID?
    @State private var showingGroupPicker = false
    @State private var currentTab: EditorTab = .edit
    @State private var isShowingPreview = false
    
    // 変更検知用の初期値
    private let originalTitle: String
    private let originalContent: String
    private let originalGroupId: UUID?
    
    @Query(filter: #Predicate<Group> { $0.deletedAt == nil },
           sort: \Group.createdAt) var groups: [Group]
    
    enum EditorTab: String, CaseIterable {
        case edit = "編集"
        case preview = "プレビュー"
    }
    
    init(memo: Memo? = nil) {
        print("🟠 [DEBUG] MemoEditorView init with memo: '\(memo?.title ?? "nil")'")
        self.memo = memo
        
        if let memo = memo {
            // 既存メモの場合
            let memoTitle = memo.title
            let memoContent = memo.content
            let memoGroupId = memo.groupId
            
            _title = State(initialValue: memoTitle)
            _content = State(initialValue: memoContent)
            _selectedGroupId = State(initialValue: memoGroupId)
            
            // 初期値を保存（変更検知用）
            originalTitle = memoTitle
            originalContent = memoContent
            originalGroupId = memoGroupId
            
            print("🟠 [DEBUG] Editing existing memo: '\(memo.title)'")
        } else {
            // 新規メモの場合
            originalTitle = ""
            originalContent = ""
            originalGroupId = nil
            
            print("🟠 [DEBUG] Creating new memo")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タブ切り替え
                Picker("表示モード", selection: $currentTab) {
                    ForEach(EditorTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // コンテンツ表示
                TabView(selection: $currentTab) {
                    // 編集モード
                    VStack(spacing: 0) {
                        // タイトル入力
                        TextField("タイトル（最大32文字）", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .onChange(of: title) { _, newValue in
                                if newValue.count > 32 {
                                    title = String(newValue.prefix(32))
                                }
                            }
                        
                        // グループ選択
                        HStack {
                            Text("グループ:")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingGroupPicker = true
                            }) {
                                Text(selectedGroup?.name ?? "未分類")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Markdownツールバー
                        MarkdownToolbar(content: $content)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // 本文入力
                        TextEditor(text: $content)
                            .font(.system(.body, design: .default))
                            .padding(.horizontal)
                    }
                    .tag(EditorTab.edit)
                    
                    // プレビューモード
                    VStack(alignment: .leading, spacing: 16) {
                        if !title.isEmpty {
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        if !content.isEmpty {
                            MarkdownPreviewView(content: content)
                        } else {
                            Text("プレビューするコンテンツがありません")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .tag(EditorTab.preview)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(memo == nil ? "新規メモ" : "メモ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        autoSaveIfNeeded()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMemo()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingGroupPicker) {
                GroupPickerView(selectedGroupId: $selectedGroupId)
            }
            .onDisappear {
                autoSaveIfNeeded()
            }
        }
    }
    
    private var selectedGroup: Group? {
        guard let selectedGroupId = selectedGroupId else { return nil }
        return groups.first { $0.id == selectedGroupId }
    }
    
    private func saveMemo() {
        saveChanges()
        dismiss()
    }
    
    private func saveChanges() {
        if let existingMemo = memo {
            existingMemo.updateContent(title: title, content: content)
            existingMemo.groupId = selectedGroupId
        } else {
            _ = dataManager.createMemo(title: title.isEmpty ? "無題のメモ" : title, 
                                     content: content, 
                                     groupId: selectedGroupId)
        }
        dataManager.saveContext()
        print("💾 [DEBUG] Changes saved")
    }
    
    private func hasChanges() -> Bool {
        return title != originalTitle || 
               content != originalContent || 
               selectedGroupId != originalGroupId
    }
    
    private func shouldAutoSave() -> Bool {
        // 変更があり、かつ空のメモではない場合に自動保存
        return hasChanges() && !(title.isEmpty && content.isEmpty)
    }
    
    private func autoSaveIfNeeded() {
        if shouldAutoSave() {
            print("🔄 [DEBUG] Auto-saving changes on dismiss")
            saveChanges()
        } else {
            print("🚫 [DEBUG] No auto-save needed")
        }
    }
}

struct GroupPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedGroupId: UUID?
    
    @Query(filter: #Predicate<Group> { $0.deletedAt == nil },
           sort: \Group.createdAt) var groups: [Group]
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedGroupId = nil
                    dismiss()
                }) {
                    HStack {
                        Text("未分類")
                        Spacer()
                        if selectedGroupId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                ForEach(groups, id: \.id) { group in
                    Button(action: {
                        selectedGroupId = group.id
                        dismiss()
                    }) {
                        HStack {
                            Text(group.name)
                            Spacer()
                            if selectedGroupId == group.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("グループ選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MarkdownToolbar: View {
    @Binding var content: String
    
    private let markdownButtons = [
        MarkdownButton(symbol: "bold", title: "太字", prefix: "**", suffix: "**"),
        MarkdownButton(symbol: "italic", title: "斜体", prefix: "*", suffix: "*"),
        MarkdownButton(symbol: "number", title: "見出し", prefix: "# ", suffix: ""),
        MarkdownButton(symbol: "list.bullet", title: "リスト", prefix: "- ", suffix: ""),
        MarkdownButton(symbol: "list.number", title: "番号", prefix: "1. ", suffix: ""),
        MarkdownButton(symbol: "link", title: "リンク", prefix: "[", suffix: "](url)"),
        MarkdownButton(symbol: "doc.text", title: "コード", prefix: "`", suffix: "`"),
        MarkdownButton(symbol: "quote.bubble", title: "引用", prefix: "> ", suffix: "")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(markdownButtons, id: \.symbol) { button in
                    Button(action: {
                        insertMarkdown(button)
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: button.symbol)
                                .font(.system(size: 16, weight: .medium))
                            Text(button.title)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 36)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
        .background(Color(.systemGray6))
    }
    
    private func insertMarkdown(_ button: MarkdownButton) {
        if button.prefix == "# " || button.prefix == "- " || button.prefix == "1. " || button.prefix == "> " {
            // 行の先頭に挿入するタイプ
            insertAtLineStart(button.prefix)
        } else {
            // 選択テキストを囲むタイプ
            wrapSelectedText(prefix: button.prefix, suffix: button.suffix)
        }
    }
    
    private func insertAtLineStart(_ prefix: String) {
        if content.isEmpty {
            content = prefix
        } else {
            // 最後の行が空でない場合は新しい行を追加
            if !content.hasSuffix("\n") {
                content += "\n"
            }
            content += prefix
        }
    }
    
    private func wrapSelectedText(prefix: String, suffix: String) {
        if content.isEmpty {
            content = prefix + suffix
        } else {
            // カーソル位置にMarkdown記法を挿入（末尾に追加）
            if prefix == "[" && suffix == "](url)" {
                content += prefix + "リンクテキスト" + suffix
            } else if prefix == "`" && suffix == "`" {
                content += prefix + "コード" + suffix
            } else {
                content += prefix + "テキスト" + suffix
            }
        }
    }
}

struct MarkdownButton {
    let symbol: String
    let title: String
    let prefix: String
    let suffix: String
}

struct MarkdownPreviewView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // 簡易Markdownレンダリング（基本的な機能のみ）
                ForEach(parseMarkdown(content), id: \.id) { element in
                    switch element.type {
                    case .heading1:
                        Text(element.content)
                            .font(.title)
                            .fontWeight(.bold)
                    case .heading2:
                        Text(element.content)
                            .font(.title2)
                            .fontWeight(.semibold)
                    case .heading3:
                        Text(element.content)
                            .font(.title3)
                            .fontWeight(.medium)
                    case .bold:
                        Text(element.content)
                            .fontWeight(.bold)
                    case .italic:
                        Text(element.content)
                            .italic()
                    case .code:
                        Text(element.content)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    case .paragraph:
                        Text(element.content)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        
        for line in lines {
            if line.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("```") && line.hasSuffix("```") {
                let content = String(line.dropFirst(3).dropLast(3))
                elements.append(MarkdownElement(type: .code, content: content))
            } else if line.contains("**") {
                let content = line.replacingOccurrences(of: "**", with: "")
                elements.append(MarkdownElement(type: .bold, content: content))
            } else if line.contains("*") {
                let content = line.replacingOccurrences(of: "*", with: "")
                elements.append(MarkdownElement(type: .italic, content: content))
            } else if !line.isEmpty {
                elements.append(MarkdownElement(type: .paragraph, content: line))
            }
        }
        
        return elements
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownType
    let content: String
    
    enum MarkdownType {
        case heading1, heading2, heading3
        case bold, italic
        case code
        case paragraph
    }
}

#Preview {
    MemoEditorView()
        .environmentObject(DataManager.shared)
}