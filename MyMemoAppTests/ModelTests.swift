//
//  ModelTests.swift
//  MyMemoAppTests
//
//  Created by 石原脩平 on 2025/08/02.
//

import Testing
import SwiftData
@testable import MyMemoApp
import Foundation

struct ModelTests {
    
    @Test func testMemoInitialization() async throws {
        let memo = Memo(title: "テストタイトル", content: "テスト内容")
        
        #expect(memo.title == "テストタイトル")
        #expect(memo.content == "テスト内容")
        #expect(memo.groupId == nil)
        #expect(memo.deletedAt == nil)
        #expect(memo.createdAt <= Date())
        #expect(memo.updatedAt <= Date())
    }
    
    @Test func testMemoWithGroup() async throws {
        let groupId = UUID()
        let memo = Memo(title: "グループメモ", content: "グループ内容", groupId: groupId)
        
        #expect(memo.groupId == groupId)
    }
    
    @Test func testMemoUpdateContent() async throws {
        let memo = Memo(title: "初期タイトル", content: "初期内容")
        let originalUpdatedAt = memo.updatedAt
        
        // 時間差を作るため少し待機
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        memo.updateContent(title: "更新タイトル", content: "更新内容")
        
        #expect(memo.title == "更新タイトル")
        #expect(memo.content == "更新内容")
        #expect(memo.updatedAt > originalUpdatedAt)
    }
    
    @Test func testMemoLogicalDeletion() async throws {
        let memo = Memo(title: "削除テスト", content: "削除内容")
        
        #expect(memo.deletedAt == nil)
        
        memo.markAsDeleted()
        
        #expect(memo.deletedAt != nil)
        #expect(memo.deletedAt! <= Date())
    }
    
    @Test func testMemoRestore() async throws {
        let memo = Memo(title: "復元テスト", content: "復元内容")
        
        memo.markAsDeleted()
        #expect(memo.deletedAt != nil)
        
        memo.restore()
        #expect(memo.deletedAt == nil)
    }
    
    @Test func testGroupInitialization() async throws {
        let group = Group(name: "テストグループ")
        
        #expect(group.name == "テストグループ")
        #expect(group.deletedAt == nil)
        #expect(group.createdAt <= Date())
        #expect(group.updatedAt <= Date())
    }
    
    @Test func testGroupLogicalDeletion() async throws {
        let group = Group(name: "削除グループ")
        
        #expect(group.deletedAt == nil)
        
        group.markAsDeleted()
        
        #expect(group.deletedAt != nil)
        #expect(group.deletedAt! <= Date())
    }
    
    @Test func testGroupRestore() async throws {
        let group = Group(name: "復元グループ")
        
        group.markAsDeleted()
        #expect(group.deletedAt != nil)
        
        group.restore()
        #expect(group.deletedAt == nil)
    }
    
    @Test func testMemoTitleLengthValidation() async throws {
        // 32文字制限のテスト（実装で制限している場合）
        let longTitle = String(repeating: "あ", count: 35)
        let memo = Memo(title: longTitle, content: "内容")
        
        // タイトルが32文字を超えていても作成は不可能
        // （実際の制限はUI層で行われる）
        #expect(memo.title.count != 35)
    }
    
    @Test func testExportableMemoCreation() async throws {
        let originalMemo = Memo(title: "エクスポートテスト", content: "エクスポート内容")
        
        let exportableMemo = ExportableMemo(
            title: originalMemo.title,
            content: originalMemo.content,
            createdAt: originalMemo.createdAt,
            updatedAt: originalMemo.updatedAt
        )
        
        #expect(exportableMemo.title == originalMemo.title)
        #expect(exportableMemo.content == originalMemo.content)
        #expect(exportableMemo.createdAt == originalMemo.createdAt)
        #expect(exportableMemo.updatedAt == originalMemo.updatedAt)
    }
    
    @Test func testExportableMemoWithCurrentDate() async throws {
        let exportableMemo = ExportableMemo(
            title: "新規エクスポート",
            content: "新規内容"
        )
        
        #expect(exportableMemo.title == "新規エクスポート")
        #expect(exportableMemo.content == "新規内容")
        #expect(exportableMemo.createdAt <= Date())
        #expect(exportableMemo.updatedAt <= Date())
    }
}
