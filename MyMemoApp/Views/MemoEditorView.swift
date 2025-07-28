//
//  MemoEditorView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import SwiftData
import UIKit

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
    @State private var cursorPosition: Int = 0
    @State private var isCancelled = false
    
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
                        MarkdownToolbar(content: $content, cursorPosition: $cursorPosition)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // 本文入力
                        CursorAwareTextEditor(text: $content, cursorPosition: $cursorPosition)
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
                        isCancelled = true
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
        if isCancelled {
            print("❌ [DEBUG] Auto-save skipped due to cancel")
            return
        }
        
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

struct CursorAwareTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let previousCursorPosition = uiView.selectedRange.location
            print("🔴 [DEBUG] Text changed. Previous cursor: \(previousCursorPosition), New cursorPosition: \(cursorPosition)")
            uiView.text = text
            
            // カーソル位置を復元（非同期で実行して確実に反映）
            let newPosition = min(cursorPosition, text.count)
            print("🔴 [DEBUG] Setting cursor to: \(newPosition)")
            
            DispatchQueue.main.async {
                uiView.selectedRange = NSRange(location: newPosition, length: 0)
                print("🔴 [DEBUG] Cursor actually set to: \(uiView.selectedRange.location)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CursorAwareTextEditor
        
        init(_ parent: CursorAwareTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.cursorPosition = textView.selectedRange.location
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let newPosition = textView.selectedRange.location
            print("🟢 [DEBUG] textViewDidChangeSelection: \(parent.cursorPosition) -> \(newPosition)")
            parent.cursorPosition = newPosition
        }
    }
}

struct MarkdownToolbar: View {
    @Binding var content: String
    @Binding var cursorPosition: Int
    
    private let markdownButtons = [
        MarkdownButton(symbol: "bold", title: "太字", prefix: "**", suffix: "**"),
        MarkdownButton(symbol: "italic", title: "斜体", prefix: "*", suffix: "*"),
        MarkdownButton(symbol: "number", title: "見出し", prefix: "# ", suffix: ""),
        MarkdownButton(symbol: "list.bullet", title: "リスト", prefix: "- ", suffix: ""),
        MarkdownButton(symbol: "list.number", title: "番号", prefix: "1. ", suffix: ""),
        MarkdownButton(symbol: "arrow.right.square", title: "右indent", prefix: "indent_right", suffix: ""),
        MarkdownButton(symbol: "arrow.left.square", title: "左indent", prefix: "indent_left", suffix: ""),
        MarkdownButton(symbol: "link", title: "リンク", prefix: "[", suffix: "](url)"),
        MarkdownButton(symbol: "doc.text", title: "コード", prefix: "`", suffix: "`"),
        MarkdownButton(symbol: "curlybraces", title: "ブロック", prefix: "code_block", suffix: ""),
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
        print("🔵 [DEBUG] insertMarkdown called for: \(button.title) (prefix: \(button.prefix))")
        print("🔵 [DEBUG] Current cursor position: \(cursorPosition)")
        
        if button.prefix == "indent_right" {
            increaseIndent()
        } else if button.prefix == "indent_left" {
            decreaseIndent()
        } else if button.prefix == "code_block" {
            insertCodeBlock()
        } else if button.prefix == "# " || button.prefix == "- " || button.prefix == "1. " || button.prefix == "> " {
            // 行の先頭に挿入するタイプ
            insertAtLineStart(button.prefix)
        } else {
            // 選択テキストを囲むタイプ
            wrapSelectedText(prefix: button.prefix, suffix: button.suffix)
        }
        
        print("🔵 [DEBUG] After insertMarkdown, cursor position: \(cursorPosition)")
    }
    
    private func insertAtLineStart(_ prefix: String) {
        if content.isEmpty {
            content = prefix
            cursorPosition = prefix.count
        } else {
            // カーソル位置から現在の行の開始位置を探す
            let lines = content.components(separatedBy: .newlines)
            let currentLineIndex = getCurrentLineIndex()
            
            if currentLineIndex < lines.count {
                // 現在の行の開始位置を計算
                var lineStartPosition = 0
                for i in 0..<currentLineIndex {
                    lineStartPosition += lines[i].count + 1 // +1 for newline
                }
                
                // 現在の行に既に該当するprefixがある場合は何もしない
                let currentLine = lines[currentLineIndex]
                if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix(prefix.trimmingCharacters(in: .whitespaces)) {
                    return
                }
                
                // 行の開始位置にprefixを挿入
                let beforeCursor = String(content.prefix(lineStartPosition))
                let afterCursor = String(content.suffix(from: content.index(content.startIndex, offsetBy: lineStartPosition)))
                
                content = beforeCursor + prefix + afterCursor
                cursorPosition = lineStartPosition + prefix.count
            } else {
                // 新しい行として追加
                if !content.hasSuffix("\n") {
                    content += "\n"
                }
                let insertPosition = content.count
                content += prefix
                cursorPosition = insertPosition + prefix.count
            }
        }
    }
    
    private func wrapSelectedText(prefix: String, suffix: String) {
        print("🟡 [DEBUG] wrapSelectedText called. Current cursor: \(cursorPosition)")
        if content.isEmpty {
            content = prefix + suffix
            cursorPosition = prefix.count
            print("🟡 [DEBUG] Empty content. New cursor: \(cursorPosition)")
        } else {
            // カーソル位置にMarkdown記法を挿入
            let insertPosition = min(cursorPosition, content.count)
            let beforeCursor = String(content.prefix(insertPosition))
            let afterCursor = String(content.suffix(from: content.index(content.startIndex, offsetBy: insertPosition)))
            
            var insertText: String
            var newCursorOffset: Int
            
            if prefix == "[" && suffix == "](url)" {
                insertText = prefix + "リンクテキスト" + suffix
                newCursorOffset = prefix.count // "["の後にカーソルを配置
            } else if prefix == "`" && suffix == "`" {
                insertText = prefix + "コード" + suffix
                newCursorOffset = prefix.count // "`"の後にカーソルを配置
            } else {
                insertText = prefix + "テキスト" + suffix
                newCursorOffset = prefix.count // prefixの後にカーソルを配置
            }
            
            content = beforeCursor + insertText + afterCursor
            let newCursorPosition = insertPosition + newCursorOffset
            print("🟡 [DEBUG] Inserting '\(insertText)' at position \(insertPosition). New cursor: \(newCursorPosition)")
            cursorPosition = newCursorPosition
        }
    }
    
    private func increaseIndent() {
        let lines = content.components(separatedBy: .newlines)
        guard !lines.isEmpty else {
            content = "  "
            cursorPosition = 2
            return
        }
        
        // カーソル位置から現在の行番号を計算
        let currentLineIndex = getCurrentLineIndex()
        guard currentLineIndex < lines.count else { return }
        
        var modifiedLines = lines
        let currentLine = lines[currentLineIndex]
        
        // 現在の行がリスト項目またはインデント可能な行の場合のみインデント
        let trimmed = currentLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.range(of: #"^\d+\. "#, options: .regularExpression) != nil || trimmed.isEmpty {
            // 2スペースを先頭に追加
            modifiedLines[currentLineIndex] = "  " + currentLine
            content = modifiedLines.joined(separator: "\n")
            
            // カーソル位置を調整（2文字分右に移動）
            cursorPosition += 2
        }
    }
    
    private func decreaseIndent() {
        let lines = content.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }
        
        // カーソル位置から現在の行番号を計算
        let currentLineIndex = getCurrentLineIndex()
        guard currentLineIndex < lines.count else { return }
        
        var modifiedLines = lines
        let currentLine = lines[currentLineIndex]
        var removedSpaces = 0
        
        if currentLine.hasPrefix("  ") {
            // 先頭の2スペースを削除
            modifiedLines[currentLineIndex] = String(currentLine.dropFirst(2))
            removedSpaces = 2
        } else if currentLine.hasPrefix(" ") {
            // 1スペースだけの場合も削除
            modifiedLines[currentLineIndex] = String(currentLine.dropFirst(1))
            removedSpaces = 1
        }
        
        if removedSpaces > 0 {
            content = modifiedLines.joined(separator: "\n")
            
            // カーソル位置を調整（削除した文字数分左に移動）
            cursorPosition = max(0, cursorPosition - removedSpaces)
        }
    }
    
    private func insertCodeBlock() {
        print("🟠 [DEBUG] insertCodeBlock called. Current cursor: \(cursorPosition)")
        if content.isEmpty {
            content = "```\nコード\n```"
            cursorPosition = 4 // "```\n"の後にカーソルを配置
            print("🟠 [DEBUG] Empty content. New cursor: \(cursorPosition)")
        } else {
            // カーソル位置にコードブロックを挿入
            let insertPosition = min(cursorPosition, content.count)
            let beforeCursor = String(content.prefix(insertPosition))
            let afterCursor = String(content.suffix(from: content.index(content.startIndex, offsetBy: insertPosition)))
            
            var insertText = "```\nコード\n```"
            
            // カーソル位置が行の途中の場合は前後に改行を追加
            if insertPosition > 0 && !beforeCursor.hasSuffix("\n") {
                insertText = "\n" + insertText
            }
            if !afterCursor.hasPrefix("\n") && !afterCursor.isEmpty {
                insertText = insertText + "\n"
            }
            
            content = beforeCursor + insertText + afterCursor
            // "```\n"の後（"コード"の位置）にカーソルを配置
            let newlineOffset = beforeCursor.hasSuffix("\n") ? 0 : 1
            let newCursorPosition = insertPosition + newlineOffset + 4 // "```\n"の長さ
            print("🟠 [DEBUG] Inserting code block at position \(insertPosition). New cursor: \(newCursorPosition)")
            cursorPosition = newCursorPosition
        }
    }
    
    private func getCurrentLineIndex() -> Int {
        let lines = content.components(separatedBy: .newlines)
        var characterCount = 0
        
        for (index, line) in lines.enumerated() {
            if characterCount + line.count >= cursorPosition {
                return index
            }
            characterCount += line.count + 1 // +1 for newline character
        }
        
        return max(0, lines.count - 1)
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
                    case .codeBlock:
                        VStack(alignment: .leading, spacing: 0) {
                            Text(element.content)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    case .inlineCode:
                        Text(element.content)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(2)
                    case .bulletList:
                        HStack(alignment: .top, spacing: 8) {
                            // インデントレベルに応じて左側のスペースを追加
                            HStack(spacing: 0) {
                                ForEach(0..<element.indentLevel, id: \.self) { _ in
                                    Spacer().frame(width: 20)
                                }
                                Text(bulletMarker(for: element.indentLevel))
                                    .foregroundColor(.secondary)
                            }
                            Text(element.content)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .numberedList:
                        HStack(alignment: .top, spacing: 8) {
                            // インデントレベルに応じて左側のスペースを追加
                            HStack(spacing: 0) {
                                ForEach(0..<element.indentLevel, id: \.self) { _ in
                                    Spacer().frame(width: 20)
                                }
                                Text(element.content.components(separatedBy: " ").first ?? "1.")
                                    .foregroundColor(.secondary)
                            }
                            Text(element.content.components(separatedBy: " ").dropFirst().joined(separator: " "))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .quote:
                        HStack(alignment: .top, spacing: 8) {
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 3)
                            Text(element.content)
                                .italic()
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 8)
                    case .paragraph:
                        Text(element.content)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func bulletMarker(for indentLevel: Int) -> String {
        switch indentLevel {
        case 0: return "•"
        case 1: return "◦"
        case 2: return "▪"
        default: return "▫"
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let indentLevel = calculateIndentLevel(line)
            
            // コードブロック（```で始まる複数行）の処理
            if trimmedLine == "```" || trimmedLine.hasPrefix("```") {
                var codeContent = ""
                var language = ""
                
                // 言語指定がある場合は取得
                if trimmedLine.count > 3 {
                    language = String(trimmedLine.dropFirst(3))
                }
                
                i += 1 // 次の行に進む
                
                // 終了の```まで収集
                while i < lines.count {
                    if lines[i].trimmingCharacters(in: .whitespaces) == "```" {
                        break
                    }
                    if !codeContent.isEmpty {
                        codeContent += "\n"
                    }
                    codeContent += lines[i]
                    i += 1
                }
                
                elements.append(MarkdownElement(type: .codeBlock, content: codeContent, indentLevel: 0))
            } else if trimmedLine.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(trimmedLine.dropFirst(4)), indentLevel: 0))
            } else if trimmedLine.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(trimmedLine.dropFirst(3)), indentLevel: 0))
            } else if trimmedLine.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
            } else if trimmedLine.hasPrefix("> ") {
                elements.append(MarkdownElement(type: .quote, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
            } else if trimmedLine.hasPrefix("- ") {
                elements.append(MarkdownElement(type: .bulletList, content: String(trimmedLine.dropFirst(2)), indentLevel: indentLevel))
            } else if trimmedLine.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
                elements.append(MarkdownElement(type: .numberedList, content: trimmedLine, indentLevel: indentLevel))
            } else if trimmedLine.hasPrefix("```") && trimmedLine.hasSuffix("```") && trimmedLine.count > 6 {
                let content = String(trimmedLine.dropFirst(3).dropLast(3))
                elements.append(MarkdownElement(type: .code, content: content, indentLevel: 0))
            } else if !trimmedLine.isEmpty {
                // インライン記法の処理
                elements.append(contentsOf: parseInlineMarkdown(trimmedLine, indentLevel: 0))
            }
            
            i += 1
        }
        
        return elements
    }
    
    private func calculateIndentLevel(_ line: String) -> Int {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        return leadingSpaces / 2 // 2スペースで1レベルのインデント
    }
    
    private func parseInlineMarkdown(_ line: String, indentLevel: Int) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentLine = line
        
        // インラインコードの処理（`code`）
        if currentLine.contains("`") && !currentLine.hasPrefix("```") {
            let components = currentLine.components(separatedBy: "`")
            for (index, component) in components.enumerated() {
                if index % 2 == 0 {
                    // 通常のテキスト
                    if !component.isEmpty {
                        elements.append(contentsOf: parseTextFormatting(component, indentLevel: indentLevel))
                    }
                } else {
                    // インラインコード
                    elements.append(MarkdownElement(type: .inlineCode, content: component, indentLevel: indentLevel))
                }
            }
        } else {
            elements.append(contentsOf: parseTextFormatting(currentLine, indentLevel: indentLevel))
        }
        
        return elements
    }
    
    private func parseTextFormatting(_ text: String, indentLevel: Int) -> [MarkdownElement] {
        // 太字と斜体の処理を改善
        if text.contains("**") {
            let content = text.replacingOccurrences(of: "**", with: "")
            return [MarkdownElement(type: .bold, content: content, indentLevel: indentLevel)]
        } else if text.contains("*") {
            let content = text.replacingOccurrences(of: "*", with: "")
            return [MarkdownElement(type: .italic, content: content, indentLevel: indentLevel)]
        } else {
            return [MarkdownElement(type: .paragraph, content: text, indentLevel: indentLevel)]
        }
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownType
    let content: String
    let indentLevel: Int
    
    enum MarkdownType {
        case heading1, heading2, heading3
        case bold, italic
        case code, inlineCode, codeBlock
        case bulletList, numberedList
        case quote
        case paragraph
    }
}

#Preview {
    MemoEditorView()
        .environmentObject(DataManager.shared)
}
