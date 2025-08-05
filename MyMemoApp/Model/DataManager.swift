//
//  DataManager.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import Foundation
import SwiftData

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    var container: ModelContainer
    var context: ModelContext
    
    private init() {
        do {
            let schema = Schema([Memo.self, Group.self])
            let configuration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = container.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // テスト用イニシャライザ
    internal init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
    }
    
    // MARK: - Memo Operations
    
    func createMemo(title: String, content: String = "", groupId: UUID? = nil) -> Memo {
        let memo = Memo(title: title, content: content, groupId: groupId)
        context.insert(memo)
        saveContext()
        return memo
    }
    
    func fetchAllMemos() -> [Memo] {
        do {
            let descriptor = FetchDescriptor<Memo>(
                predicate: #Predicate { $0.deletedAt == nil },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch memos: \(error)")
            return []
        }
    }
    
    func fetchDeletedMemos() -> [Memo] {
        do {
            let descriptor = FetchDescriptor<Memo>(
                predicate: #Predicate { $0.deletedAt != nil },
                sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch deleted memos: \(error)")
            return []
        }
    }
    
    func fetchMemos(for groupId: UUID) -> [Memo] {
        do {
            let descriptor = FetchDescriptor<Memo>(
                predicate: #Predicate { memo in
                    memo.groupId == groupId && memo.deletedAt == nil
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch memos for group: \(error)")
            return []
        }
    }
    
    func deleteMemo(_ memo: Memo, permanently: Bool = false) {
        if permanently {
            context.delete(memo)
        } else {
            memo.markAsDeleted()
        }
        saveContext()
    }
    
    func restoreMemo(_ memo: Memo) {
        memo.restore()
        saveContext()
    }
    
    // MARK: - Group Operations
    
    func createGroup(name: String) -> Group {
        let group = Group(name: name)
        context.insert(group)
        saveContext()
        return group
    }
    
    func fetchAllGroups() -> [Group] {
        do {
            let descriptor = FetchDescriptor<Group>(
                predicate: #Predicate { $0.deletedAt == nil },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch groups: \(error)")
            return []
        }
    }
    
    func deleteGroup(_ group: Group, permanently: Bool = false) {
        if permanently {
            context.delete(group)
        } else {
            group.markAsDeleted()
        }
        saveContext()
    }
    
    func restoreGroup(_ group: Group) {
        group.restore()
        saveContext()
    }
    
    // MARK: - Utility
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func searchMemos(query: String) -> [Memo] {
        do {
            let descriptor = FetchDescriptor<Memo>(
                predicate: #Predicate { memo in
                    memo.deletedAt == nil && 
                    (memo.title.localizedStandardContains(query) || 
                     memo.content.localizedStandardContains(query))
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to search memos: \(error)")
            return []
        }
    }
}