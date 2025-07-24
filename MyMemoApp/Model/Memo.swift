//
//  Memo.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/16.
//

import Foundation
import SwiftData

@Model
class Memo: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var groupId: UUID?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    @Relationship(inverse: \Group.memos) var group: Group?
    
    init(title: String, content: String = "", groupId: UUID? = nil) {
        self.id = UUID()
        self.title = String(title.prefix(32)) // 32文字制限
        self.content = content
        self.groupId = groupId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    func markAsDeleted() {
        deletedAt = Date()
        updatedAt = Date()
    }
    
    func restore() {
        deletedAt = nil
        updatedAt = Date()
    }
    
    func updateContent(title: String, content: String) {
        self.title = String(title.prefix(32))
        self.content = content
        self.updatedAt = Date()
    }
}
