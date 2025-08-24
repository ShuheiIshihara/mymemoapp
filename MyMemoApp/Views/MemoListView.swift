//
//  MemoListView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import SwiftData

struct MemoListView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Query(filter: #Predicate<Memo> { $0.deletedAt == nil },
           sort: \Memo.updatedAt, order: .reverse) var memos: [Memo]
    @Query(filter: #Predicate<Group> { $0.deletedAt == nil },
           sort: \Group.createdAt) var groups: [Group]
    
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var selectedMemo: Memo?
    @State private var expandedGroups: Set<UUID> = []
    @State private var isCreatingNewMemo = false
    
    var filteredMemos: [Memo] {
        if searchText.isEmpty {
            return memos
        } else {
            return memos.filter { memo in
                memo.title.localizedCaseInsensitiveContains(searchText) ||
                memo.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var ungroupedMemos: [Memo] {
        filteredMemos.filter { $0.groupId == nil }
    }
    
    private func handleMemoTap(_ memo: Memo) {
        print("🟢 [DEBUG] Tapped memo: '\(memo.title)' (ID: \(memo.id))")
        selectedMemo = memo
        isCreatingNewMemo = false
        print("🟢 [DEBUG] Opening existing memo: '\(memo.title)'")
    }
    
    private func handleGroupMemoTap(_ memo: Memo) {
        print("🔵 [DEBUG] Group memo tapped: '\(memo.title)' (ID: \(memo.id))")
        selectedMemo = memo
        isCreatingNewMemo = false
        print("🔵 [DEBUG] Opening existing memo: '\(memo.title)'")
    }
    
    var body: some View {
        NavigationView {
            contentView
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            memoListView
        }
        .navigationTitle("メモ")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(content: toolbarContent)
        .sheet(item: $selectedMemo, onDismiss: onSheetDismissed) { memo in
//            print("🔴 [DEBUG] Sheet presenting with memo: '\(memo.title)'")
            MemoEditorView(memo: memo)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $isCreatingNewMemo, onDismiss: onSheetDismissed) {
//            print("🔴 [DEBUG] Sheet presenting for new memo")
            MemoEditorView(memo: nil)
                .environmentObject(dataManager)
        }
        // .onChange(of: searchText) { _, newValue in
        //     debounceSearch(newValue)
        // }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: createNewMemo) {
                Image(systemName: "plus")
            }
        }
    }
    
    private var memoListView: some View {
        List {
            // 検索結果件数表示
            if !searchText.isEmpty {
                searchResultHeader
            }
            
            // 検索結果が空の場合
            if !searchText.isEmpty && filteredMemos.isEmpty {
                emptySearchResultView
            } else {
                ungroupedSection
                groupedSections
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var searchResultHeader: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                Text("検索結果: \(filteredMemos.count)件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var emptySearchResultView: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("「\(searchText)」に一致するメモが見つかりません")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("別のキーワードで検索してみてください")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    @ViewBuilder
    private var ungroupedSection: some View {
        if !ungroupedMemos.isEmpty {
            Section("未分類") {
                ForEach(ungroupedMemos, id: \.id) { memo in
                    MemoRowView(memo: memo, searchText: searchText)
                        .onTapGesture {
                            handleMemoTap(memo)
                        }
                        .contextMenu {
                            contextMenuItems(for: memo)
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var groupedSections: some View {
        ForEach(groups, id: \.id) { group in
            let groupMemos = filteredMemos.filter { $0.groupId == group.id }
            if !groupMemos.isEmpty {
                Section {
                    if expandedGroups.contains(group.id) {
                        ForEach(groupMemos, id: \.id) { memo in
                            MemoRowView(memo: memo, searchText: searchText)
                                .onTapGesture {
                                    handleGroupMemoTap(memo)
                                }
                                .contextMenu {
                                    contextMenuItems(for: memo)
                                }
                        }
                    }
                } header: {
                    GroupHeaderView(
                        group: group,
                        memoCount: groupMemos.count,
                        isExpanded: expandedGroups.contains(group.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleGroupExpansion(group.id)
                    }
                }
            }
        }
    }
    
    
    private func createNewMemo() {
        selectedMemo = nil
        isCreatingNewMemo = true
        print("🟢 [DEBUG] Creating new memo")
    }
    
    private func onSheetDismissed() {
        print("🟡 [DEBUG] Sheet dismissed")
        selectedMemo = nil
        isCreatingNewMemo = false
    }
    
    private func toggleGroupExpansion(_ groupId: UUID) {
        withAnimation {
            if expandedGroups.contains(groupId) {
                expandedGroups.remove(groupId)
            } else {
                expandedGroups.insert(groupId)
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for memo: Memo) -> some View {
        Button("編集") {
            selectedMemo = memo
            isCreatingNewMemo = false
        }
        
        Button("削除", role: .destructive) {
            dataManager.deleteMemo(memo)
        }
    }
}

struct MemoRowView: View {
    let memo: Memo
    let searchText: String
    
    init(memo: Memo, searchText: String = "") {
        self.memo = memo
        self.searchText = searchText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            highlightedText(
                text: memo.title.isEmpty ? "無題のメモ" : memo.title,
                searchText: searchText,
                font: .headline
            )
            .lineLimit(1)
            
            if !memo.content.isEmpty {
                highlightedText(
                    text: memo.content,
                    searchText: searchText,
                    font: .caption
                )
                .foregroundColor(.secondary)
                .lineLimit(2)
            }
            
            Text(formatDate(memo.updatedAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func highlightedText(text: String, searchText: String, font: Font) -> some View {
        if searchText.isEmpty || !text.lowercased().contains(searchText.lowercased()) {
            Text(text)
                .font(font)
        } else {
            // 安全なハイライト実装
            createHighlightedView(text: text, searchText: searchText, font: font)
        }
    }
    
    @ViewBuilder
    private func createHighlightedView(text: String, searchText: String, font: Font) -> some View {
        let parts = splitTextForHighlight(text: text, searchText: searchText)
        
        if parts.isEmpty {
            Text(text).font(font)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Text(part.text)
                        .background(part.isHighlight ? Color.yellow.opacity(0.7) : Color.clear)
                }
            }
            .font(font)
        }
    }
    
    private func splitTextForHighlight(text: String, searchText: String) -> [(text: String, isHighlight: Bool)] {
        guard !searchText.isEmpty else { return [(text, false)] }
        
        let lowercased = text.lowercased()
        let searchLower = searchText.lowercased()
        var result: [(String, Bool)] = []
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            if let range = lowercased.range(of: searchLower, range: currentIndex..<text.endIndex) {
                // 検索語の前の部分
                if currentIndex < range.lowerBound {
                    let beforeText = String(text[currentIndex..<range.lowerBound])
                    result.append((beforeText, false))
                }
                
                // 検索語の部分
                let matchText = String(text[range])
                result.append((matchText, true))
                
                currentIndex = range.upperBound
            } else {
                // 残りの部分
                let remainingText = String(text[currentIndex..<text.endIndex])
                result.append((remainingText, false))
                break
            }
        }
        
        return result
    }
    
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct GroupHeaderView: View {
    let group: Group
    let memoCount: Int
    let isExpanded: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
            
            Text(group.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("(\(memoCount))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
}

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("メモを検索", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isSearchFocused)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isSearchFocused = false
                }
            }
        }
    }
}


#Preview {
    MemoListView()
        .environmentObject(DataManager.shared)
}
