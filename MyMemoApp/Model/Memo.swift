//
//  Memo.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/16.
//

import Foundation

struct Memo {
    let id: UUID
    var title: String
    var content: String  // Markdown本文
    let createdAt: Date
    var updatedAt: Date
}
