//
//  MarkdownToHTMLConverter.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/30.
//

import Foundation

class MarkdownToHTMLConverter {
    
    func convert(_ memo: ExportableMemo) -> String {
        let htmlContent = convertMarkdownToHTML(memo.content)
        
        return generateFullHTML(
            title: memo.title,
            content: htmlContent,
            createdAt: memo.createdAt,
            updatedAt: memo.updatedAt
        )
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        let elements = parseMarkdown(markdown)
        return processListElements(elements)
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        var numberedListCounters: [Int: Int] = [:]
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let indentLevel = calculateIndentLevel(line)
            
            // コードブロック処理
            if trimmedLine == "```" || trimmedLine.hasPrefix("```") {
                var codeContent = ""
                var language = ""
                
                if trimmedLine.count > 3 {
                    language = String(trimmedLine.dropFirst(3))
                }
                
                i += 1
                
                while i < lines.count {
                    if lines[i].trimmingCharacters(in: .whitespaces) == "```" {
                        break
                    }
                    if !codeContent.isEmpty {
                        codeContent += "\n"
                    }
                    codeContent += lines[i]
                    i += 1
                }
                
                elements.append(MarkdownElement(type: .codeBlock, content: codeContent, indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .heading3, content: String(trimmedLine.dropFirst(4)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .heading2, content: String(trimmedLine.dropFirst(3)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .heading1, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("> ") {
                elements.append(MarkdownElement(type: .quote, content: String(trimmedLine.dropFirst(2)), indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                elements.append(MarkdownElement(type: .bulletList, content: String(trimmedLine.dropFirst(2)), indentLevel: indentLevel))
                numberedListCounters.removeAll()
            } else if trimmedLine.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
                let content = trimmedLine.replacingOccurrences(of: #"^\d+\. "#, with: "", options: .regularExpression)
                let currentNumber = (numberedListCounters[indentLevel] ?? 0) + 1
                numberedListCounters[indentLevel] = currentNumber
                
                let keysToRemove = numberedListCounters.keys.filter { $0 > indentLevel }
                for key in keysToRemove {
                    numberedListCounters.removeValue(forKey: key)
                }
                
                elements.append(MarkdownElement(type: .numberedList, content: content, indentLevel: indentLevel, number: currentNumber))
            } else if trimmedLine.hasPrefix("```") && trimmedLine.hasSuffix("```") && trimmedLine.count > 6 {
                let content = String(trimmedLine.dropFirst(3).dropLast(3))
                elements.append(MarkdownElement(type: .code, content: content, indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.range(of: #"^-{3,}$"#, options: .regularExpression) != nil {
                // 水平線（3つ以上のハイフン）
                elements.append(MarkdownElement(type: .horizontalRule, content: "", indentLevel: 0))
                numberedListCounters.removeAll()
            } else if trimmedLine.contains("|") {
                // テーブル行の処理
                let (tableHTML, nextIndex) = parseTableBlock(lines, startIndex: i)
                if !tableHTML.isEmpty {
                    elements.append(MarkdownElement(type: .table, content: tableHTML, indentLevel: 0))
                    i = nextIndex - 1 // ループで i += 1 されるので -1
                    numberedListCounters.removeAll()
                } else {
                    // テーブルとして解析できない場合は通常の段落として処理
                    elements.append(contentsOf: parseInlineMarkdown(trimmedLine, indentLevel: 0))
                    numberedListCounters.removeAll()
                }
            } else if !trimmedLine.isEmpty {
                elements.append(contentsOf: parseInlineMarkdown(trimmedLine, indentLevel: 0))
                numberedListCounters.removeAll()
            }
            
            i += 1
        }
        
        return elements
    }
    
    private func parseTableBlock(_ lines: [String], startIndex: Int) -> (String, Int) {
        var tableRows: [String] = []
        var currentIndex = startIndex
        
        // テーブル行を連続して収集
        while currentIndex < lines.count {
            let line = lines[currentIndex].trimmingCharacters(in: .whitespaces)
            
            // パイプを含む行かつ、最低2つのパイプがある（列区切り）
            if line.contains("|") && line.components(separatedBy: "|").count >= 3 {
                tableRows.append(line)
                currentIndex += 1
            } else if !line.isEmpty {
                break // 空行でない非テーブル行に到達したら終了
            } else {
                currentIndex += 1 // 空行はスキップして続行
            }
        }
        
        // 最低2行必要（ヘッダー行 + データ行）
        if tableRows.count < 2 {
            return ("", startIndex + 1)
        }
        
        // テーブルHTMLを生成
        var html = "<table>"
        
        for (index, row) in tableRows.enumerated() {
            let cells = row.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if index == 0 {
                // ヘッダー行
                html += "<thead><tr>"
                for cell in cells {
                    html += "<th>\(escapeHTML(cell))</th>"
                }
                html += "</tr></thead><tbody>"
            } else if index == 1 && cells.allSatisfy({ $0.allSatisfy { $0 == "-" || $0 == ":" || $0.isWhitespace } }) {
                // アライメント行（:---: や ---など）は無視
                continue
            } else {
                // データ行
                html += "<tr>"
                for cell in cells {
                    html += "<td>\(escapeHTML(cell))</td>"
                }
                html += "</tr>"
            }
        }
        
        html += "</tbody></table>"
        
        return (html, currentIndex)
    }
    
    private func calculateIndentLevel(_ line: String) -> Int {
        let leadingSpaces = line.prefix(while: { $0 == " " }).count
        return leadingSpaces / 2
    }
    
    private func parseInlineMarkdown(_ line: String, indentLevel: Int) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentLine = line
        
        // インラインコードの処理
        if currentLine.contains("`") && !currentLine.hasPrefix("```") {
            let components = currentLine.components(separatedBy: "`")
            for (index, component) in components.enumerated() {
                if index % 2 == 0 {
                    if !component.isEmpty {
                        elements.append(contentsOf: parseTextFormatting(component, indentLevel: indentLevel))
                    }
                } else {
                    elements.append(MarkdownElement(type: .inlineCode, content: component, indentLevel: indentLevel))
                }
            }
        } else {
            elements.append(contentsOf: parseTextFormatting(currentLine, indentLevel: indentLevel))
        }
        
        return elements
    }
    
    private func parseTextFormatting(_ text: String, indentLevel: Int) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentText = text
        
        // 太字処理
        while currentText.contains("**") {
            let components = currentText.components(separatedBy: "**")
            if components.count >= 3 {
                if !components[0].isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: components[0], indentLevel: indentLevel))
                }
                
                if !components[1].isEmpty {
                    elements.append(MarkdownElement(type: .bold, content: components[1], indentLevel: indentLevel))
                }
                
                currentText = components.dropFirst(2).joined(separator: "**")
            } else {
                break
            }
        }
        
        // 取り消し線処理
        while currentText.contains("~~") {
            let components = currentText.components(separatedBy: "~~")
            if components.count >= 3 {
                if !components[0].isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: components[0], indentLevel: indentLevel))
                }
                
                if !components[1].isEmpty {
                    elements.append(MarkdownElement(type: .strikethrough, content: components[1], indentLevel: indentLevel))
                }
                
                currentText = components.dropFirst(2).joined(separator: "~~")
            } else {
                break
            }
        }
        
        // 画像処理
        let imagePattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: imagePattern, options: []) {
            let matches = regex.matches(in: currentText, options: [], range: NSRange(currentText.startIndex..., in: currentText))
            
            if !matches.isEmpty {
                var processedText = ""
                var lastEnd = currentText.startIndex
                
                for match in matches {
                    let matchRange = Range(match.range, in: currentText)!
                    let altRange = Range(match.range(at: 1), in: currentText)!
                    let urlRange = Range(match.range(at: 2), in: currentText)!
                    
                    // マッチより前のテキスト
                    let beforeText = String(currentText[lastEnd..<matchRange.lowerBound])
                    if !beforeText.isEmpty {
                        processedText += beforeText
                    }
                    
                    // 画像のaltテキストとURL
                    let altText = String(currentText[altRange])
                    let imageURL = String(currentText[urlRange])
                    
                    // 画像要素として追加
                    if !processedText.isEmpty {
                        elements.append(MarkdownElement(type: .paragraph, content: processedText, indentLevel: indentLevel))
                        processedText = ""
                    }
                    elements.append(MarkdownElement(type: .image, content: "\(altText)|\(imageURL)", indentLevel: indentLevel))
                    
                    lastEnd = matchRange.upperBound
                }
                
                // 残りのテキスト
                let remainingText = String(currentText[lastEnd...])
                currentText = remainingText
            }
        }
        
        // リンク処理
        let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern, options: []) {
            let matches = regex.matches(in: currentText, options: [], range: NSRange(currentText.startIndex..., in: currentText))
            
            if !matches.isEmpty {
                var processedText = ""
                var lastEnd = currentText.startIndex
                
                for match in matches {
                    let matchRange = Range(match.range, in: currentText)!
                    let textRange = Range(match.range(at: 1), in: currentText)!
                    let urlRange = Range(match.range(at: 2), in: currentText)!
                    
                    // マッチより前のテキスト
                    let beforeText = String(currentText[lastEnd..<matchRange.lowerBound])
                    if !beforeText.isEmpty {
                        processedText += beforeText
                    }
                    
                    // リンクテキストとURL
                    let linkText = String(currentText[textRange])
                    let linkURL = String(currentText[urlRange])
                    
                    // リンク要素として追加
                    if !processedText.isEmpty {
                        elements.append(MarkdownElement(type: .paragraph, content: processedText, indentLevel: indentLevel))
                        processedText = ""
                    }
                    elements.append(MarkdownElement(type: .link, content: "\(linkText)|\(linkURL)", indentLevel: indentLevel))
                    
                    lastEnd = matchRange.upperBound
                }
                
                // 残りのテキスト
                let remainingText = String(currentText[lastEnd...])
                currentText = remainingText
            }
        }
        
        // 斜体処理
        if currentText.contains("*") && !currentText.contains("**") {
            let components = currentText.components(separatedBy: "*")
            if components.count >= 3 {
                var tempText = ""
                for (index, component) in components.enumerated() {
                    if index % 2 == 0 {
                        tempText += component
                    } else {
                        if !tempText.isEmpty {
                            elements.append(MarkdownElement(type: .paragraph, content: tempText, indentLevel: indentLevel))
                            tempText = ""
                        }
                        if !component.isEmpty {
                            elements.append(MarkdownElement(type: .italic, content: component, indentLevel: indentLevel))
                        }
                    }
                }
                if !tempText.isEmpty {
                    elements.append(MarkdownElement(type: .paragraph, content: tempText, indentLevel: indentLevel))
                }
                currentText = ""
            }
        }
        
        if !currentText.isEmpty {
            elements.append(MarkdownElement(type: .paragraph, content: currentText, indentLevel: indentLevel))
        }
        
        if elements.isEmpty {
            return [MarkdownElement(type: .paragraph, content: text, indentLevel: indentLevel)]
        }
        
        return elements
    }
    
    private func processListElements(_ elements: [MarkdownElement]) -> String {
        var result: [String] = []
        var i = 0
        
        while i < elements.count {
            let element = elements[i]
            
            switch element.type {
            case .bulletList, .numberedList:
                let (listHTML, nextIndex) = processListGroup(elements, startIndex: i)
                result.append(listHTML)
                i = nextIndex
            default:
                result.append(convertElementToHTML(element))
                i += 1
            }
        }
        
        return result.joined(separator: "\n")
    }
    
    private func processListGroup(_ elements: [MarkdownElement], startIndex: Int) -> (String, Int) {
        guard startIndex < elements.count else { return ("", startIndex) }
        
        let firstElement = elements[startIndex]
        let listType = firstElement.type
        let startLevel = firstElement.indentLevel
        
        var listItems: [String] = []
        var currentIndex = startIndex
        
        while currentIndex < elements.count {
            let element = elements[currentIndex]
            
            // 同じタイプのリストでない場合は終了
            guard element.type == listType else { break }
            
            // より深いレベルの場合はネストリストとして処理
            if element.indentLevel > startLevel {
                let (nestedHTML, nextIndex) = processListGroup(elements, startIndex: currentIndex)
                if !listItems.isEmpty {
                    // 前のリストアイテムにネストリストを追加
                    listItems[listItems.count - 1] += "\n" + nestedHTML
                }
                currentIndex = nextIndex
                continue
            }
            
            // より浅いレベルの場合は終了
            if element.indentLevel < startLevel {
                break
            }
            
            // 同じレベルのリストアイテム
            listItems.append("<li>\(convertInlineHTML(element.content))</li>")
            currentIndex += 1
        }
        
        let listTag = (listType == .numberedList) ? "ol" : "ul"
        let indent = String(repeating: "  ", count: startLevel)
        let listHTML = "\(indent)<\(listTag)>\n" +
                      listItems.map { "\(indent)  \($0)" }.joined(separator: "\n") + "\n" +
                      "\(indent)</\(listTag)>"
        
        return (listHTML, currentIndex)
    }
    
    private func convertElementToHTML(_ element: MarkdownElement) -> String {
        switch element.type {
        case .heading1:
            return "<h1>\(escapeHTML(element.content))</h1>"
        case .heading2:
            return "<h2>\(escapeHTML(element.content))</h2>"
        case .heading3:
            return "<h3>\(escapeHTML(element.content))</h3>"
        case .bold:
            return "<strong>\(escapeHTML(element.content))</strong>"
        case .italic:
            return "<em>\(escapeHTML(element.content))</em>"
        case .strikethrough:
            return "<del>\(escapeHTML(element.content))</del>"
        case .code:
            return "<code>\(escapeHTML(element.content))</code>"
        case .inlineCode:
            return "<code>\(escapeHTML(element.content))</code>"
        case .codeBlock:
            return "<pre><code>\(escapeHTML(element.content))</code></pre>"
        case .bulletList, .numberedList:
            // この関数では個別のリストアイテムは処理しない（processListGroupで処理される）
            return ""
        case .quote:
            return "<blockquote>\(convertInlineHTML(element.content))</blockquote>"
        case .link:
            let components = element.content.components(separatedBy: "|")
            if components.count == 2 {
                return "<a href=\"\(escapeHTML(components[1]))\">\(escapeHTML(components[0]))</a>"
            } else {
                return escapeHTML(element.content)
            }
        case .image:
            let components = element.content.components(separatedBy: "|")
            if components.count == 2 {
                return "<img src=\"\(escapeHTML(components[1]))\" alt=\"\(escapeHTML(components[0]))\" style=\"max-width: 100%; height: auto;\" />"
            } else {
                return escapeHTML(element.content)
            }
        case .table:
            return element.content // HTMLテーブルはそのまま返す
        case .horizontalRule:
            return "<hr>"
        case .paragraph:
            return "<p>\(escapeHTML(element.content))</p>"
        }
    }
    
    private func convertInlineHTML(_ text: String) -> String {
        let inlineElements = parseInlineMarkdown(text, indentLevel: 0)
        return inlineElements.map { element in
            switch element.type {
            case .bold:
                return "<strong>\(escapeHTML(element.content))</strong>"
            case .italic:
                return "<em>\(escapeHTML(element.content))</em>"
            case .strikethrough:
                return "<del>\(escapeHTML(element.content))</del>"
            case .inlineCode:
                return "<code>\(escapeHTML(element.content))</code>"
            case .link:
                let components = element.content.components(separatedBy: "|")
                if components.count == 2 {
                    return "<a href=\"\(escapeHTML(components[1]))\">\(escapeHTML(components[0]))</a>"
                } else {
                    return escapeHTML(element.content)
                }
            case .image:
                let components = element.content.components(separatedBy: "|")
                if components.count == 2 {
                    return "<img src=\"\(escapeHTML(components[1]))\" alt=\"\(escapeHTML(components[0]))\" style=\"max-width: 100%; height: auto;\" />"
                } else {
                    return escapeHTML(element.content)
                }
            default:
                return escapeHTML(element.content)
            }
        }.joined()
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private func generateFullHTML(title: String, content: String, createdAt: Date, updatedAt: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let createdDateString = formatter.string(from: createdAt)
        let updatedDateString = formatter.string(from: updatedAt)
        
        return """
        <!DOCTYPE html>
        <html lang="ja">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(title.isEmpty ? "無題のメモ" : title))</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Hiragino Sans', 'Hiragino Kaku Gothic ProN', 'Noto Sans CJK JP', sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333333;
                    margin: 0;
                    padding: 40px;
                    background-color: white;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                }
                
                h1 {
                    font-size: 28px;
                    border-bottom: 2px solid #333333;
                    padding-bottom: 8px;
                }
                
                h2 {
                    font-size: 22px;
                    border-bottom: 1px solid #666666;
                    padding-bottom: 4px;
                }
                
                h3 {
                    font-size: 18px;
                    color: #444444;
                }
                
                p {
                    margin-bottom: 16px;
                }
                
                ul, ol {
                    margin: 16px 0;
                    padding-left: 24px;
                }
                
                li {
                    margin-bottom: 4px;
                }
                
                code {
                    background-color: #f5f5f5;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
                    font-size: 13px;
                    border: 1px solid #e5e5e5;
                }
                
                pre {
                    background-color: #f8f8f8;
                    border: 1px solid #e5e5e5;
                    border-radius: 6px;
                    padding: 16px;
                    overflow-x: auto;
                    margin: 16px 0;
                }
                
                pre code {
                    background: none;
                    border: none;
                    padding: 0;
                }
                
                blockquote {
                    border-left: 4px solid #d1d5db;
                    padding-left: 16px;
                    margin: 16px 0;
                    color: #6b7280;
                    font-style: italic;
                }
                
                .document-title {
                    font-size: 32px;
                    font-weight: 700;
                    margin-bottom: 8px;
                    color: #1f2937;
                    border-bottom: 3px solid #3b82f6;
                    padding-bottom: 12px;
                }
                
                .document-metadata {
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid #e5e5e5;
                    font-size: 12px;
                    color: #666666;
                }
                
                .document-content {
                    margin-top: 32px;
                }
                
                strong {
                    font-weight: 600;
                    color: #1f2937;
                }
                
                em {
                    font-style: italic;
                    color: #374151;
                }
                
                del {
                    text-decoration: line-through;
                    color: #6b7280;
                }
                
                a {
                    color: #3b82f6;
                    text-decoration: underline;
                }
                
                a:hover {
                    color: #1d4ed8;
                }
                
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 16px 0;
                    border: 1px solid #e5e5e5;
                }
                
                th, td {
                    border: 1px solid #e5e5e5;
                    padding: 8px 12px;
                    text-align: left;
                }
                
                th {
                    background-color: #f8f9fa;
                    font-weight: 600;
                    color: #1f2937;
                }
                
                tr:nth-child(even) {
                    background-color: #f9fafb;
                }
                
                hr {
                    border: none;
                    border-top: 1px solid #e5e5e5;
                    margin: 16px 0;
                }
            </style>
        </head>
        <body>
            \(title.isEmpty ? "" : "<div class=\"document-title\">\(escapeHTML(title))</div>")
            <div class=\"document-content">
                \(content)
            </div>
            <div class="document-metadata">
                <p><strong>作成日:</strong> \(createdDateString)</p>
                <p><strong>更新日:</strong> \(updatedDateString)</p>
            </div>
        </body>
        </html>
        """
    }
}

