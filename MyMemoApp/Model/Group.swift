//
//  Group.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/21.
//

import Foundation
import SwiftData

@Model
class Group {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    @Relationship(deleteRule: .nullify) var memos: [Memo] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    var activeMemos: [Memo] {
        memos.filter { !$0.isDeleted }
    }
    
    var deletedMemos: [Memo] {
        memos.filter { $0.isDeleted }
    }
    
    func markAsDeleted() {
        deletedAt = Date()
        updatedAt = Date()
        
        // グループが削除されたときは、関連するメモのgroupIdをnilに設定
        for memo in memos {
            memo.groupId = nil
            memo.updatedAt = Date()
        }
    }
    
    func restore() {
        deletedAt = nil
        updatedAt = Date()
    }
    
    func updateName(_ newName: String) {
        self.name = newName
        self.updatedAt = Date()
    }
}