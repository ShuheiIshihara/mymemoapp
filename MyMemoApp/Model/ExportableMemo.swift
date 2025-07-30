//
//  ExportableMemo.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/30.
//

import Foundation

// エクスポート用のデータ構造体
struct ExportableMemo {
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    
    init(from memo: Memo) {
        self.title = memo.title
        self.content = memo.content
        self.createdAt = memo.createdAt
        self.updatedAt = memo.updatedAt
    }
    
    init(title: String, content: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.title = title
        self.content = content
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
}