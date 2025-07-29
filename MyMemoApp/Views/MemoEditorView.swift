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
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
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
        } else {
            // 新規メモの場合
            originalTitle = ""
            originalContent = ""
            originalGroupId = nil
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
                        MarkdownToolbar(content: $content, cursorPosition: $cursorPosition, selectedRange: $selectedRange)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // 本文入力
                        CursorAwareTextEditor(text: $content, cursorPosition: $cursorPosition, selectedRange: $selectedRange)
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
                                .font(.system(.body).italic())
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
            return
        }
        
        if shouldAutoSave() {
            saveChanges()
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
    @Binding var selectedRange: NSRange
    
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
            uiView.text = text
            
            // 選択範囲を復元（非同期で実行して確実に反映）
            let newRange = NSRange(
                location: min(selectedRange.location, text.count),
                length: min(selectedRange.length, max(0, text.count - selectedRange.location))
            )
            
            DispatchQueue.main.async {
                uiView.selectedRange = newRange
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
            parent.selectedRange = textView.selectedRange
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.cursorPosition = textView.selectedRange.location
            parent.selectedRange = textView.selectedRange
        }
    }
}

struct MarkdownToolbar: View {
    @Binding var content: String
    @Binding var cursorPosition: Int
    @Binding var selectedRange: NSRange
    
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
    }
    
    private func insertAtLineStart(_ prefix: String) {
        if content.isEmpty {
            content = prefix
            cursorPosition = prefix.count
            selectedRange = NSRange(location: prefix.count, length: 0)
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
                selectedRange = NSRange(location: cursorPosition, length: 0)
            } else {
                // 新しい行として追加
                if !content.hasSuffix("\n") {
                    content += "\n"
                }
                let insertPosition = content.count
                content += prefix
                cursorPosition = insertPosition + prefix.count
                selectedRange = NSRange(location: cursorPosition, length: 0)
            }
        }
    }
    
    private func wrapSelectedText(prefix: String, suffix: String) {
        if content.isEmpty {
            content = prefix + suffix
            cursorPosition = prefix.count
            selectedRange = NSRange(location: prefix.count, length: 0)
        } else {
            // 選択範囲がある場合は選択テキストを囲む
            if selectedRange.length > 0 {
                let startIndex = content.index(content.startIndex, offsetBy: selectedRange.location)
                let endIndex = content.index(content.startIndex, offsetBy: selectedRange.location + selectedRange.length)
                let selectedText = String(content[startIndex..<endIndex])
                
                let beforeSelection = String(content.prefix(selectedRange.location))
                let afterSelection = String(content.suffix(content.count - selectedRange.location - selectedRange.length))
                
                let wrappedText = prefix + selectedText + suffix
                content = beforeSelection + wrappedText + afterSelection
                
                // 選択範囲を更新（記法で囲まれた内側のテキストを選択状態に）
                let newLocation = selectedRange.location + prefix.count
                selectedRange = NSRange(location: newLocation, length: selectedText.count)
                cursorPosition = newLocation + selectedText.count
            } else {
                // 選択範囲がない場合は従来の動作
                let insertPosition = min(cursorPosition, content.count)
                let beforeCursor = String(content.prefix(insertPosition))
                let afterCursor = String(content.suffix(from: content.index(content.startIndex, offsetBy: insertPosition)))
                
                var insertText: String
                var defaultText: String
                var newCursorOffset: Int
                
                if prefix == "[" && suffix == "](url)" {
                    defaultText = "リンクテキスト"
                    insertText = prefix + defaultText + suffix
                    newCursorOffset = prefix.count
                } else if prefix == "`" && suffix == "`" {
                    defaultText = "コード"
                    insertText = prefix + defaultText + suffix
                    newCursorOffset = prefix.count
                } else if prefix == "**" {
                    defaultText = "太字テキスト"
                    insertText = prefix + defaultText + suffix
                    newCursorOffset = prefix.count
                } else if prefix == "*" {
                    defaultText = "斜体テキスト"
                    insertText = prefix + defaultText + suffix
                    newCursorOffset = prefix.count
                } else {
                    defaultText = "テキスト"
                    insertText = prefix + defaultText + suffix
                    newCursorOffset = prefix.count
                }
                
                content = beforeCursor + insertText + afterCursor
                
                // デフォルトテキストを選択状態にする
                let newLocation = insertPosition + prefix.count
                selectedRange = NSRange(location: newLocation, length: defaultText.count)
                cursorPosition = newLocation + defaultText.count
            }
        }
    }
    
    private func increaseIndent() {
        let lines = content.components(separatedBy: .newlines)
        guard !lines.isEmpty else {
            content = "  "
            cursorPosition = 2
            selectedRange = NSRange(location: 2, length: 0)
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
            selectedRange = NSRange(location: cursorPosition, length: 0)
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
            selectedRange = NSRange(location: cursorPosition, length: 0)
        }
    }
    
    private func insertCodeBlock() {
        if content.isEmpty {
            content = "```\nコード\n```"
            cursorPosition = 4 // "```\n"の後にカーソルを配置
            selectedRange = NSRange(location: 4, length: 2) // "コード"を選択状態に
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
            // "```\n"の後（"コード"の位置）にカーソルを配置し、"コード"を選択状態に
            let newlineOffset = beforeCursor.hasSuffix("\n") ? 0 : 1
            let newCursorPosition = insertPosition + newlineOffset + 4 // "```\n"の長さ
            cursorPosition = newCursorPosition
            selectedRange = NSRange(location: newCursorPosition, length: 2) // "コード"を選択状態に
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
                            .font(.system(.body).italic())
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
                            // リストアイテム内のインライン記法を解析して表示
                            renderInlineMarkdown(element.content)
                        }
                    case .numberedList:
                        HStack(alignment: .top, spacing: 8) {
                            // インデントレベルに応じて左側のスペースを追加
                            HStack(spacing: 0) {
                                ForEach(0..<element.indentLevel, id: \.self) { _ in
                                    Spacer().frame(width: 20)
                                }
                                Text(formatNumber(element.number ?? 1, for: element.indentLevel))
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 24, alignment: .trailing)
                            }
                            // リストアイテム内のインライン記法を解析して表示
                            renderInlineMarkdown(element.content)
                        }
                    case .quote:
                        HStack(alignment: .top, spacing: 8) {
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 3)
                            Text(element.content)
                                .font(.system(.body).italic())
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
    
    private func formatNumber(_ number: Int, for indentLevel: Int) -> String {
        switch indentLevel {
        case 0:
            // 1層目: 算用数字
            return "\(number)."
        case 1:
            // 2層目: アルファベット小文字
            return "\(numberToAlphabet(number))."
        case 2:
            // 3層目: ローマ数字小文字
            return "\(numberToRoman(number))."
        default:
            // 4層目以降: 算用数字
            return "\(number)."
        }
    }
    
    private func numberToAlphabet(_ number: Int) -> String {
        guard number > 0 && number <= 26 else { return "a" }
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        let index = alphabet.index(alphabet.startIndex, offsetBy: number - 1)
        return String(alphabet[index])
    }
    
    private func numberToRoman(_ number: Int) -> String {
        let romanNumerals = ["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x",
                           "xi", "xii", "xiii", "xiv", "xv", "xvi", "xvii", "xviii", "xix", "xx"]
        guard number > 0 && number < romanNumerals.count else { return "i" }
        return romanNumerals[number]
    }
    
    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        let inlineElements = parseInlineMarkdown(text, indentLevel: 0)
        
        if inlineElements.count == 1 && inlineElements.first?.type == .paragraph {
            // 単純なテキストの場合
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // インライン記法が含まれる場合
            HStack(spacing: 0) {
                ForEach(inlineElements, id: \.id) { element in
                    switch element.type {
                    case .bold:
                        Text(element.content)
                            .fontWeight(.bold)
                    case .italic:
                        Text(element.content)
                            .font(.system(.body).italic())
                    case .inlineCode:
                        Text(element.content)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(2)
                    case .paragraph:
                        Text(element.content)
                    default:
                        Text(element.content)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var numberedListCounters: [Int: Int] = [:] // インデントレベルごとの番号管理
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
                // リストの番号をリセット
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(trimmedLine.dropFirst(4)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(trimmedLine.dropFirst(3)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("> ") {
                elements.append(MarkdownElement(type: .quote, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("- ") {
                elements.append(MarkdownElement(type: .bulletList, content: String(trimmedLine.dropFirst(2)), indentLevel: indentLevel))
                numberedListCounters.removeAll()
            } else if trimmedLine.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
                // 番号付きリストの処理
                let content = trimmedLine.replacingOccurrences(of: #"^\d+\. "#, with: "", options: .regularExpression)
                
                // 現在のインデントレベルの番号を取得・更新
                let currentNumber = (numberedListCounters[indentLevel] ?? 0) + 1
                numberedListCounters[indentLevel] = currentNumber
                
                // より深いレベルの番号をリセット
                let keysToRemove = numberedListCounters.keys.filter { $0 > indentLevel }
                for key in keysToRemove {
                    numberedListCounters.removeValue(forKey: key)
                }
                
                elements.append(MarkdownElement(type: .numberedList, content: content, indentLevel: indentLevel, number: currentNumber))
            } else if trimmedLine.hasPrefix("```") && trimmedLine.hasSuffix("```") && trimmedLine.count > 6 {
                let content = String(trimmedLine.dropFirst(3).dropLast(3))
                elements.append(MarkdownElement(type: .code, content: content, indentLevel: 0))
                numberedListCounters.removeAll()
            } else if !trimmedLine.isEmpty {
                // インライン記法の処理
                elements.append(contentsOf: parseInlineMarkdown(trimmedLine, indentLevel: 0))
                numberedListCounters.removeAll()
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
        var elements: [MarkdownElement] = []
        var currentText = text
        
        // 太字の処理（**text**）
        while currentText.contains("**") {
            let components = currentText.components(separatedBy: "**")
            if components.count >= 3 {
                // **より前の通常テキスト
                if !components[0].isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: components[0], indentLevel: indentLevel))
                }
                
                // **で囲まれた太字テキスト
                if !components[1].isEmpty {
                    elements.append(MarkdownElement(type: .bold, content: components[1], indentLevel: indentLevel))
                }
                
                // 残りのテキストを再度処理
                currentText = components.dropFirst(2).joined(separator: "**")
            } else {
                break
            }
        }
        
        // 斜体の処理（*text*）- 太字処理後の残りテキストで実行
        if currentText.contains("*") && !currentText.contains("**") {
            let components = currentText.components(separatedBy: "*")
            if components.count >= 3 {
                var tempText = ""
                for (index, component) in components.enumerated() {
                    if index % 2 == 0 {
                        // 通常のテキスト
                        tempText += component
                    } else {
                        // *で囲まれた斜体テキスト
                        if !tempText.isEmpty {
                            elements.append(MarkdownElement(type: .paragraph, content: tempText, indentLevel: indentLevel))
                            tempText = ""
                        }
                        if !component.isEmpty {
                            elements.append(MarkdownElement(type: .italic, content: component, indentLevel: indentLevel))
                        }
                    }
                }
                if !tempText.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: tempText, indentLevel: indentLevel))
                }
                currentText = ""
            }
        }
        
        // 残りの通常テキスト
        if !currentText.isEmpty {
            elements.append(MarkdownElement(type: .paragraph, content: currentText, indentLevel: indentLevel))
        }
        
        // 空の要素があった場合は単純な段落として返す
        if elements.isEmpty {
            return [MarkdownElement(type: .paragraph, content: text, indentLevel: indentLevel)]
        }
        
        return elements
    }
}

struct MarkdownElement {
    let id = UUID()
    let type: MarkdownType
    let content: String
    let indentLevel: Int
    let number: Int? // 番号付きリスト用の番号
    
    init(type: MarkdownType, content: String, indentLevel: Int, number: Int? = nil) {
        self.type = type
        self.content = content
        self.indentLevel = indentLevel
        self.number = number
    }
    
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
