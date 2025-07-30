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
            } else if trimmedLine.hasPrefix("- ") {
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
            } else if !trimmedLine.isEmpty {
                elements.append(contentsOf: parseInlineMarkdown(trimmedLine, indentLevel: 0))
                numberedListCounters.removeAll()
            }
            
            i += 1
        }
        
        return elements
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
            case .inlineCode:
                return "<code>\(escapeHTML(element.content))</code>"
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

