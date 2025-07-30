//
//  ExportManager.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/30.
//

import Foundation
import UniformTypeIdentifiers

class ExportManager: ObservableObject {
    
    enum ExportFormat {
        case markdown
        case pdf
        case text
        
        var fileExtension: String {
            switch self {
            case .markdown: return "md"
            case .pdf: return "pdf"
            case .text: return "txt"
            }
        }
        
        var utType: UTType {
            switch self {
            case .markdown: return UTType.plainText
            case .pdf: return UTType.pdf
            case .text: return UTType.plainText
            }
        }
    }
    
    enum ExportError: LocalizedError {
        case fileCreationFailed
        case invalidContent
        case storageError
        
        var errorDescription: String? {
            switch self {
            case .fileCreationFailed:
                return "ファイルの作成に失敗しました"
            case .invalidContent:
                return "エクスポートするコンテンツが無効です"
            case .storageError:
                return "ストレージの容量が不足しています"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 単一メモをエクスポート
    func exportMemo(_ memo: Memo, format: ExportFormat) throws -> URL {
        let content = generateContent(for: memo, format: format)
        let filename = generateFilename(for: memo, format: format)
        return try createTemporaryFile(content: content, filename: filename)
    }
    
    /// エクスポート可能メモをエクスポート
    func exportExportableMemo(_ memo: ExportableMemo, format: ExportFormat) throws -> URL {
        let content = generateContent(for: memo, format: format)
        let filename = generateFilename(for: memo, format: format)
        return try createTemporaryFile(content: content, filename: filename)
    }
    
    /// 複数メモをエクスポート
    func exportMemos(_ memos: [Memo], format: ExportFormat, groupName: String? = nil) throws -> URL {
        let content = generateContent(for: memos, format: format)
        let filename = generateFilename(for: memos, groupName: groupName, format: format)
        return try createTemporaryFile(content: content, filename: filename)
    }
    
    // MARK: - Private Methods
    
    private func generateContent(for memo: Memo, format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return generateMarkdownContent(for: memo)
        case .text:
            return generateTextContent(for: memo)
        case .pdf:
            // PDFは後で実装
            return generateMarkdownContent(for: memo)
        }
    }
    
    private func generateContent(for memo: ExportableMemo, format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return generateMarkdownContent(for: memo)
        case .text:
            return generateTextContent(for: memo)
        case .pdf:
            // PDFは後で実装
            return generateMarkdownContent(for: memo)
        }
    }
    
    private func generateContent(for memos: [Memo], format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return memos.map { generateMarkdownContent(for: $0) }.joined(separator: "\n\n---\n\n")
        case .text:
            return memos.map { generateTextContent(for: $0) }.joined(separator: "\n\n---\n\n")
        case .pdf:
            // PDFは後で実装
            return memos.map { generateMarkdownContent(for: $0) }.joined(separator: "\n\n---\n\n")
        }
    }
    
    private func generateMarkdownContent(for memo: Memo) -> String {
        var content = ""
        
        // タイトルを見出し1として追加
        if !memo.title.isEmpty {
            content += "# \(memo.title)\n\n"
        }
        
        // メモの内容を追加
        content += memo.content
        
        // メタデータを追加
        content += "\n\n---\n"
        content += "*作成日: \(formatDate(memo.createdAt))*\n"
        content += "*更新日: \(formatDate(memo.updatedAt))*"
        
        return content
    }
    
    private func generateTextContent(for memo: Memo) -> String {
        var content = ""
        
        // タイトルを追加
        if !memo.title.isEmpty {
            content += "\(memo.title)\n"
            content += String(repeating: "=", count: memo.title.count) + "\n\n"
        }
        
        // Markdown記法を除去したコンテンツを追加
        content += removeMarkdownSyntax(memo.content)
        
        // メタデータを追加
        content += "\n\n---\n"
        content += "作成日: \(formatDate(memo.createdAt))\n"
        content += "更新日: \(formatDate(memo.updatedAt))"
        
        return content
    }
    
    private func removeMarkdownSyntax(_ text: String) -> String {
        var cleanText = text
        
        // 見出し記号を削除
        cleanText = cleanText.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        
        // 太字記号を削除
        cleanText = cleanText.replacingOccurrences(of: "**", with: "")
        
        // 斜体記号を削除
        cleanText = cleanText.replacingOccurrences(of: "*", with: "")
        
        // インラインコード記号を削除
        cleanText = cleanText.replacingOccurrences(of: "`", with: "")
        
        // リスト記号を削除
        cleanText = cleanText.replacingOccurrences(of: #"^[\s]*[-\*\+]\s+"#, with: "", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: #"^[\s]*\d+\.\s+"#, with: "", options: .regularExpression)
        
        // 引用記号を削除
        cleanText = cleanText.replacingOccurrences(of: #"^>\s+"#, with: "", options: .regularExpression)
        
        // コードブロック記号を削除
        cleanText = cleanText.replacingOccurrences(of: "```", with: "")
        
        return cleanText
    }
    
    private func generateFilename(for memo: Memo, format: ExportFormat) -> String {
        let title = memo.title.isEmpty ? "無題のメモ" : memo.title
        let sanitizedTitle = sanitizeFilename(title)
        let dateString = formatDateForFilename(Date())
        return "\(sanitizedTitle)_\(dateString).\(format.fileExtension)"
    }
    
    private func generateFilename(for memo: ExportableMemo, format: ExportFormat) -> String {
        let title = memo.title.isEmpty ? "無題のメモ" : memo.title
        let sanitizedTitle = sanitizeFilename(title)
        let dateString = formatDateForFilename(Date())
        return "\(sanitizedTitle)_\(dateString).\(format.fileExtension)"
    }
    
    private func generateMarkdownContent(for memo: ExportableMemo) -> String {
        var content = ""
        
        // タイトルを見出し1として追加
        if !memo.title.isEmpty {
            content += "# \(memo.title)\n\n"
        }
        
        // メモの内容を追加
        content += memo.content
        
        // メタデータを追加
        content += "\n\n---\n"
        content += "*作成日: \(formatDate(memo.createdAt))*\n"
        content += "*更新日: \(formatDate(memo.updatedAt))*"
        
        return content
    }
    
    private func generateTextContent(for memo: ExportableMemo) -> String {
        var content = ""
        
        // タイトルを追加
        if !memo.title.isEmpty {
            content += "\(memo.title)\n"
            content += String(repeating: "=", count: memo.title.count) + "\n\n"
        }
        
        // Markdown記法を除去したコンテンツを追加
        content += removeMarkdownSyntax(memo.content)
        
        // メタデータを追加
        content += "\n\n---\n"
        content += "作成日: \(formatDate(memo.createdAt))\n"
        content += "更新日: \(formatDate(memo.updatedAt))"
        
        return content
    }
    
    private func generateFilename(for memos: [Memo], groupName: String?, format: ExportFormat) -> String {
        let baseName = groupName ?? "メモ集"
        let sanitizedName = sanitizeFilename(baseName)
        let dateString = formatDateForFilename(Date())
        let count = memos.count
        return "\(sanitizedName)_\(count)件_\(dateString).\(format.fileExtension)"
    }
    
    private func sanitizeFilename(_ filename: String) -> String {
        // ファイル名に使用できない文字を除去
        let invalidCharacters = CharacterSet(charactersIn: "/:*?\"<>|\\")
        return filename.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
    
    private func createTemporaryFile(content: String, filename: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ExportError.fileCreationFailed
        }
    }
}