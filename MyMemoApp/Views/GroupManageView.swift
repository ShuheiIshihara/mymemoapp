//
//  GroupManageView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import SwiftData

struct GroupManageView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Query(filter: #Predicate<Group> { $0.deletedAt == nil },
           sort: \Group.createdAt) var groups: [Group]
    
    @State private var showingAddGroupSheet = false
    @State private var editingGroup: Group?
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: Group?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groups, id: \.id) { group in
                    GroupRowView(group: group)
                        .contextMenu {
                            Button("編集") {
                                editingGroup = group
                            }
                            
                            Button("削除", role: .destructive) {
                                groupToDelete = group
                                showingDeleteAlert = true
                            }
                        }
                }
                .onDelete(perform: deleteGroups)
            }
            .navigationTitle("グループ管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGroupSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                AddGroupSheet(dataManager: dataManager)
            }
            .sheet(item: $editingGroup) { group in
                EditGroupSheet(group: group, dataManager: dataManager)
            }
            .alert("グループを削除", isPresented: $showingDeleteAlert) {
                Button("キャンセル", role: .cancel) {
                    groupToDelete = nil
                }
                Button("削除", role: .destructive) {
                    if let group = groupToDelete {
                        dataManager.deleteGroup(group)
                    }
                    groupToDelete = nil
                }
            } message: {
                Text("このグループを削除しますか？グループ内のメモは未分類になります。")
            }
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        for index in offsets {
            let group = groups[index]
            dataManager.deleteGroup(group)
        }
    }
}

struct GroupRowView: View {
    let group: Group
    
    @Query var allMemos: [Memo]
    
    private var memoCount: Int {
        allMemos.filter { $0.groupId == group.id && $0.deletedAt == nil }.count
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("作成日: \(formatDate(group.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(memoCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("メモ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct AddGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let dataManager: DataManager
    
    @State private var groupName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("グループ名", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                
                Spacer()
            }
            .padding()
            .navigationTitle("新規グループ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func saveGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            _ = dataManager.createGroup(name: trimmedName)
            dismiss()
        }
    }
}

struct EditGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group
    let dataManager: DataManager
    
    @State private var groupName: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(group: Group, dataManager: DataManager) {
        self.group = group
        self.dataManager = dataManager
        _groupName = State(initialValue: group.name)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("グループ名", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                
                Spacer()
            }
            .padding()
            .navigationTitle("グループ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func saveGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && trimmedName != group.name {
            group.updateName(trimmedName)
            dataManager.saveContext()
        }
        dismiss()
    }
}

#Preview {
    GroupManageView()
        .environmentObject(DataManager.shared)
}