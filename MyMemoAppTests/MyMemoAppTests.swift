//
//  MyMemoAppTests.swift
//  MyMemoAppTests
//
//  Created by 石原脩平 on 2025/07/16.
//

import Testing
import SwiftData
@testable import MyMemoApp

struct MyMemoAppTests {
    
    // テスト用のDataManagerを作成
    @MainActor
    private func createTestDataManager() throws -> DataManager {
        let schema = Schema([Memo.self, Group.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        return DataManager(container: container)
    }

    @Test @MainActor func testCreateMemo() async throws {
        let dataManager = try createTestDataManager()
        
        let memo = dataManager.createMemo(title: "テストメモ", content: "テスト内容")
        
        #expect(memo.title == "テストメモ")
        #expect(memo.content == "テスト内容")
        #expect(memo.groupId == nil)
        #expect(memo.deletedAt == nil)
    }
    
    @Test @MainActor func testFetchAllMemos() async throws {
        let dataManager = try createTestDataManager()
        
        // テストデータを作成
        let memo1 = dataManager.createMemo(title: "メモ1", content: "内容1")
        let memo2 = dataManager.createMemo(title: "メモ2", content: "内容2")
        
        let fetchedMemos = dataManager.fetchAllMemos()
        
        #expect(fetchedMemos.count == 2)
        #expect(fetchedMemos.contains { $0.id == memo1.id })
        #expect(fetchedMemos.contains { $0.id == memo2.id })
    }
    
    @Test @MainActor func testDeleteMemoLogically() async throws {
        let dataManager = try createTestDataManager()
        
        let memo = dataManager.createMemo(title: "削除テスト", content: "削除される内容")
        
        // 論理削除
        dataManager.deleteMemo(memo, permanently: false)
        
        #expect(memo.deletedAt != nil)
        
        // 通常のフェッチでは取得されない
        let activeMemos = dataManager.fetchAllMemos()
        #expect(activeMemos.isEmpty)
        
        // 削除済みメモとして取得される
        let deletedMemos = dataManager.fetchDeletedMemos()
        #expect(deletedMemos.count == 1)
        #expect(deletedMemos.first?.id == memo.id)
    }
    
    @Test @MainActor func testRestoreMemo() async throws {
        let dataManager = try createTestDataManager()
        
        let memo = dataManager.createMemo(title: "復元テスト", content: "復元される内容")
        
        // 論理削除してから復元
        dataManager.deleteMemo(memo, permanently: false)
        dataManager.restoreMemo(memo)
        
        #expect(memo.deletedAt == nil)
        
        // 通常のフェッチで取得される
        let activeMemos = dataManager.fetchAllMemos()
        #expect(activeMemos.count == 1)
        #expect(activeMemos.first?.id == memo.id)
    }
    
    @Test @MainActor func testCreateGroup() async throws {
        let dataManager = try createTestDataManager()
        
        let group = dataManager.createGroup(name: "テストグループ")
        
        #expect(group.name == "テストグループ")
        #expect(group.deletedAt == nil)
    }
    
    @Test @MainActor func testFetchAllGroups() async throws {
        let dataManager = try createTestDataManager()
        
        let group1 = dataManager.createGroup(name: "グループ1")
        let group2 = dataManager.createGroup(name: "グループ2")
        
        let fetchedGroups = dataManager.fetchAllGroups()
        
        #expect(fetchedGroups.count == 2)
        #expect(fetchedGroups.contains { $0.id == group1.id })
        #expect(fetchedGroups.contains { $0.id == group2.id })
    }
    
    @Test @MainActor func testSearchMemos() async throws {
        let dataManager = try createTestDataManager()
        
        _ = dataManager.createMemo(title: "Swift開発", content: "iOSアプリ開発について")
        _ = dataManager.createMemo(title: "料理レシピ", content: "美味しいカレーの作り方")
        _ = dataManager.createMemo(title: "旅行計画", content: "Swift言語の学習メモ")
        
        // タイトルで検索
        let swiftMemos = dataManager.searchMemos(query: "Swift")
        #expect(swiftMemos.count == 2)
        
        // 内容で検索
        let recipeMemos = dataManager.searchMemos(query: "カレー")
        #expect(recipeMemos.count == 1)
        #expect(recipeMemos.first?.title == "料理レシピ")
    }
    
    @Test @MainActor func testFetchMemosForGroup() async throws {
        let dataManager = try createTestDataManager()
        
        let group = dataManager.createGroup(name: "仕事")
        
        let memo1 = dataManager.createMemo(title: "会議メモ", content: "重要な議題", groupId: group.id)
        let memo2 = dataManager.createMemo(title: "個人メモ", content: "プライベート")
        
        let groupMemos = dataManager.fetchMemos(for: group.id)
        
        #expect(groupMemos.count == 1)
        #expect(groupMemos.first?.id == memo1.id)
        #expect(!groupMemos.contains { $0.id == memo2.id })
    }

}
