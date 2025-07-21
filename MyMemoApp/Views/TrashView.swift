//
//  TrashView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import SwiftUI
import SwiftData

struct TrashView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Query(filter: #Predicate<Memo> { $0.deletedAt != nil },
           sort: \Memo.deletedAt, order: .reverse) var deletedMemos: [Memo]
    
    @State private var showingDeleteAllAlert = false
    @State private var memoToDelete: Memo?
    @State private var showingPermanentDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if deletedMemos.isEmpty {
                    EmptyTrashView()
                } else {
                    List {
                        ForEach(deletedMemos, id: \.id) { memo in
                            DeletedMemoRowView(memo: memo)
                                .contextMenu {
                                    Button("復元") {
                                        dataManager.restoreMemo(memo)
                                    }
                                    
                                    Button("完全に削除", role: .destructive) {
                                        memoToDelete = memo
                                        showingPermanentDeleteAlert = true
                                    }
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("ゴミ箱")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !deletedMemos.isEmpty {
                        Menu {
                            Button("すべて復元") {
                                restoreAllMemos()
                            }
                            
                            Button("すべて完全削除", role: .destructive) {
                                showingDeleteAllAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("すべてのメモを完全削除", isPresented: $showingDeleteAllAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("完全削除", role: .destructive) {
                    deleteAllMemos()
                }
            } message: {
                Text("ゴミ箱内のすべてのメモを完全に削除しますか？この操作は取り消せません。")
            }
            .alert("メモを完全削除", isPresented: $showingPermanentDeleteAlert) {
                Button("キャンセル", role: .cancel) {
                    memoToDelete = nil
                }
                Button("完全削除", role: .destructive) {
                    if let memo = memoToDelete {
                        dataManager.deleteMemo(memo, permanently: true)
                    }
                    memoToDelete = nil
                }
            } message: {
                Text("このメモを完全に削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    private func restoreAllMemos() {
        for memo in deletedMemos {
            dataManager.restoreMemo(memo)
        }
    }
    
    private func deleteAllMemos() {
        for memo in deletedMemos {
            dataManager.deleteMemo(memo, permanently: true)
        }
    }
}

struct EmptyTrashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("ゴミ箱は空です")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("削除したメモがここに表示されます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DeletedMemoRowView: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memo.title.isEmpty ? "無題のメモ" : memo.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    if !memo.content.isEmpty {
                        Text(memo.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: {
                        DataManager.shared.restoreMemo(memo)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        // 完全削除の確認は親ビューで処理
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            if let deletedAt = memo.deletedAt {
                Text("削除日時: \(formatDate(deletedAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(0.7)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    TrashView()
        .environmentObject(DataManager.shared)
}