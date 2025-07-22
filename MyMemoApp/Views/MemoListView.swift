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
    @State private var showingMemoEditor = false
    @State private var selectedMemo: Memo?
    @State private var expandedGroups: Set<UUID> = []
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                List {
                    if !ungroupedMemos.isEmpty {
                        Section("未分類") {
                            ForEach(ungroupedMemos, id: \.id) { memo in
                                MemoRowView(memo: memo)
                                    .onTapGesture {
                                        selectedMemo = memo
                                        showingMemoEditor = true
                                    }
                                    .contextMenu {
                                        contextMenuItems(for: memo)
                                    }
                            }
                        }
                    }
                    
                    ForEach(groups, id: \.id) { group in
                        let groupMemos = filteredMemos.filter { $0.groupId == group.id }
                        if !groupMemos.isEmpty {
                            Section {
                                if expandedGroups.contains(group.id) {
                                    ForEach(groupMemos, id: \.id) { memo in
                                        MemoRowView(memo: memo)
                                            .onTapGesture {
                                                selectedMemo = memo
                                                showingMemoEditor = true
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
                                    withAnimation {
                                        if expandedGroups.contains(group.id) {
                                            expandedGroups.remove(group.id)
                                        } else {
                                            expandedGroups.insert(group.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("メモ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedMemo = nil
                        showingMemoEditor = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingMemoEditor) {
                MemoEditorView(memo: selectedMemo)
                    .environmentObject(dataManager)
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for memo: Memo) -> some View {
        Button("編集") {
            selectedMemo = memo
            showingMemoEditor = true
        }
        
        Button("削除", role: .destructive) {
            dataManager.deleteMemo(memo)
        }
    }
}

struct MemoRowView: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memo.title.isEmpty ? "無題のメモ" : memo.title)
                .font(.headline)
                .lineLimit(1)
            
            if !memo.content.isEmpty {
                Text(memo.content)
                    .font(.caption)
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
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("メモを検索", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MemoListView()
        .environmentObject(DataManager.shared)
}