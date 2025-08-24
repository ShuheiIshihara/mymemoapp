//
//  MarkdownTests.swift
//  MyMemoAppTests
//
//  Created by 石原脩平 on 2025/08/02.
//

import Testing
@testable import MyMemoApp

struct MarkdownTests {
    
    @Test func testBasicMarkdownToHTML() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        # 見出し1
        ## 見出し2
        ### 見出し3
        
        **太字**テキスト
        *斜体*テキスト
        ~~取り消し線~~テキスト
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<h1>"))
        #expect(html.contains("<h2>"))
        #expect(html.contains("<h3>"))
        #expect(html.contains("<strong>"))
        #expect(html.contains("<em>"))
        #expect(html.contains("<del>"))
    }
    
    @Test func testHeadingNumbering() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        # 第一章
        ## 第一節
        ### 第一項
        # 第二章
        ## 第二節
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("1. 第一章"))
        #expect(html.contains("1.1. 第一節"))
        #expect(html.contains("1.1.1. 第一項"))
        #expect(html.contains("2. 第二章"))
        #expect(html.contains("2.1. 第二節"))
    }
    
    @Test func testCodeBlocks() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        インライン`コード`です。
        
        ```swift
        func hello() {
            print("Hello, World!")
        }
        ```
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<code>"))
        #expect(html.contains("<pre>"))
        #expect(html.contains("func hello()"))
    }
    
    @Test func testLists() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        - 項目1
        - 項目2
          - サブ項目1
          - サブ項目2
        
        1. 番号付き1
        2. 番号付き2
           a. サブ番号1
           b. サブ番号2
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<ul>"))
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>"))
    }
    
    @Test func testLinks() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = "[Google](https://www.google.com)"
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<a href=\"https://www.google.com\""))
        #expect(html.contains("Google"))
    }
    
    @Test func testImages() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = "![画像説明](https://example.com/image.jpg)"
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<img"))
        #expect(html.contains("src=\"https://example.com/image.jpg\""))
        #expect(html.contains("alt=\"画像説明\""))
    }
    
    @Test func testTables() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        | 列1 | 列2 | 列3 |
        |-----|-----|-----|
        | A   | B   | C   |
        | 1   | 2   | 3   |
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<table"))
        #expect(html.contains("<thead>"))
        #expect(html.contains("<tbody>"))
        #expect(html.contains("<th>"))
        #expect(html.contains("<td>"))
    }
    
    @Test func testQuotes() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = "> これは引用文です。"
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<blockquote>"))
        #expect(html.contains("これは引用文です。"))
    }
    
    @Test func testHorizontalRule() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        上の内容
        
        ---
        
        下の内容
        """
        
        let html = converter.convertToHTML(markdown)
        
        #expect(html.contains("<hr"))
    }
    
    @Test func testEmptyInput() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let html = converter.convertToHTML("")
        
        #expect(html.contains("<!DOCTYPE html>"))
//        #expect(html.contains("<html>"))
        #expect(html.contains("</html>"))
    }
    
    @Test func testSpecialCharactersEscaping() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = "< > & \" '"
        
        let html = converter.convertToHTML(markdown)
        
        // HTMLエスケープが正しく行われているかテスト
        #expect(html.contains("&lt;") || html.contains("&gt;") || html.contains("&amp;"))
    }
    
    @Test func testComplexDocument() async throws {
        let converter = MarkdownToHTMLConverter()
        
        let markdown = """
        # ドキュメントタイトル
        
        これは**重要な**ドキュメントです。
        
        ## 章1: 基本概念
        
        以下のポイントを理解してください：
        
        - ポイント1
        - ポイント2
        - ポイント3
        
        ### 詳細説明
        
        `コード例`を含む説明：
        
        ```
        function example() {
            return "Hello";
        }
        ```
        
        > 重要な注意事項
        
        詳細は[公式サイト](https://example.com)を参照してください。
        """
        
        let html = converter.convertToHTML(markdown)
        
        // 複合的なMarkdownが正しく変換されているかテスト
        #expect(html.contains("<h1>"))
        #expect(html.contains("<h2>"))
        #expect(html.contains("<h3>"))
        #expect(html.contains("<strong>"))
        #expect(html.contains("<ul>"))
        #expect(html.contains("<code>"))
        #expect(html.contains("<pre>"))
        #expect(html.contains("<blockquote>"))
        #expect(html.contains("<a href="))
    }
}
