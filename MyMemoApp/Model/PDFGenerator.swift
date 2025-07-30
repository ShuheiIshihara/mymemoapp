//
//  PDFGenerator.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/30.
//

import Foundation
import UIKit

class PDFGenerator {
    
    enum PDFError: LocalizedError {
        case htmlConversionFailed
        case pdfGenerationFailed
        case invalidContent
        
        var errorDescription: String? {
            switch self {
            case .htmlConversionFailed:
                return "HTMLへの変換に失敗しました"
            case .pdfGenerationFailed:
                return "PDFの生成に失敗しました"
            case .invalidContent:
                return "コンテンツが無効です"
            }
        }
    }
    
    private let htmlConverter = MarkdownToHTMLConverter()
    
    // MARK: - Public Methods
    
    func generatePDF(from memo: ExportableMemo) throws -> Data {
        // 1. MarkdownをHTMLに変換
        let html = htmlConverter.convert(memo)
        
        // 2. HTMLをPDFに変換
        return try renderHTMLToPDF(html, title: memo.title)
    }
    
    // MARK: - Private Methods
    
    private func renderHTMLToPDF(_ html: String, title: String) throws -> Data {
        // HTMLマークアップテキストフォーマッターを作成
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        
        // ページ設定
        let pageSize = CGSize(width: 595, height: 842) // A4サイズ (ポイント単位)
        let pageMargins = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72) // 1インチマージン
        
        // フォーマッターの設定
        formatter.perPageContentInsets = pageMargins
        
        // ページレンダラーを作成
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        
        // ページサイズを設定
        let printableRect = CGRect(
            x: pageMargins.left,
            y: pageMargins.top,
            width: pageSize.width - pageMargins.left - pageMargins.right,
            height: pageSize.height - pageMargins.top - pageMargins.bottom
        )
        
        let paperRect = CGRect(origin: .zero, size: pageSize)
        
        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")
        
        // PDFコンテキストを作成してレンダリング
        let pdfData = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, [
            kCGPDFContextTitle as String: title.isEmpty ? "無題のメモ" : title,
            kCGPDFContextAuthor as String: "MyMemoApp",
            kCGPDFContextCreator as String: "MyMemoApp",
            kCGPDFContextSubject as String: "Markdown Document Export"
        ])
        
        // 各ページをレンダリング
        let numberOfPages = renderer.numberOfPages
        
        guard numberOfPages > 0 else {
            UIGraphicsEndPDFContext()
            throw PDFError.pdfGenerationFailed
        }
        
        for pageIndex in 0..<numberOfPages {
            UIGraphicsBeginPDFPage()
            
            let bounds = UIGraphicsGetPDFContextBounds()
            
            // ヘッダーを描画
            drawHeader(title: title, pageNumber: pageIndex + 1, totalPages: numberOfPages, in: bounds)
            
            // フッターを描画
            drawFooter(pageNumber: pageIndex + 1, totalPages: numberOfPages, in: bounds)
            
            // メインコンテンツを描画
            renderer.drawPage(at: pageIndex, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        guard pdfData.length > 0 else {
            throw PDFError.pdfGenerationFailed
        }
        
        return pdfData as Data
    }
    
    private func drawHeader(title: String, pageNumber: Int, totalPages: Int, in bounds: CGRect) {
        let headerHeight: CGFloat = 50
        let headerRect = CGRect(
            x: bounds.minX + 72,
            y: bounds.minY + 20,
            width: bounds.width - 144,
            height: headerHeight
        )
        
        // タイトルを描画（1ページ目のみ）
        if pageNumber == 1 && !title.isEmpty {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            
            let titleText = title
            titleText.draw(in: headerRect, withAttributes: titleAttributes)
        }
    }
    
    private func drawFooter(pageNumber: Int, totalPages: Int, in bounds: CGRect) {
        let footerHeight: CGFloat = 30
        let footerRect = CGRect(
            x: bounds.minX + 72,
            y: bounds.maxY - 50,
            width: bounds.width - 144,
            height: footerHeight
        )
        
        // ページ番号を描画
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let pageText = "ページ \(pageNumber) / \(totalPages)"
        let pageTextSize = pageText.size(withAttributes: pageAttributes)
        
        let pageTextRect = CGRect(
            x: footerRect.maxX - pageTextSize.width,
            y: footerRect.minY,
            width: pageTextSize.width,
            height: footerRect.height
        )
        
        pageText.draw(in: pageTextRect, withAttributes: pageAttributes)
        
        // 現在日時を描画
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let dateText = dateFormatter.string(from: Date())
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        dateText.draw(in: CGRect(x: footerRect.minX, y: footerRect.minY, width: 200, height: footerRect.height), withAttributes: dateAttributes)
    }
}

// MARK: - UIMarkupTextPrintFormatter Extensions

extension UIMarkupTextPrintFormatter {
    
    convenience init(markdownHTML: String) {
        self.init(markupText: markdownHTML)
        
        // デフォルト設定を適用
        self.perPageContentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
    }
}