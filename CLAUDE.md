# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要
Swift + SwiftUI + Swift Dataで構築されたiOS Markdownメモアプリ。完全版として開発済み。

## 開発コマンド
```bash
# プロジェクトをビルド
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp build

# テストを実行
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp test

# Xcodeで開く
open MyMemoApp.xcodeproj
```

## アーキテクチャ

### データ層アーキテクチャ
- **Swift Data**: Core Data後継の永続化フレームワーク使用
- **DataManager**: シングルトンパターンでSwift Dataコンテナと操作を管理
- **Model**: `Memo`と`Group`の@Modelクラス、論理削除対応
- **依存性注入**: `@environmentObject`でDataManagerをView階層に注入

### UI層アーキテクチャ  
- **TabView**: 4つのメインタブ（メモ・グループ・ゴミ箱・設定）
- **NavigationStack**: iOS16+の新しいナビゲーション方式採用
- **MVVM**: @StateObject/@ObservedObjectでリアクティブなUI更新

### エクスポートアーキテクチャ
- **ExportManager**: エクスポート機能の統合管理
- **MarkdownToHTMLConverter**: Markdown → HTML変換、包括的記法サポート
- **PDFGenerator**: UIKit PrintPageRendererを使用したPDF生成
- **ExportableMemo**: Swift Dataメモリ管理問題を回避する安全なデータ構造

### Markdownレンダリングアーキテクチャ
- **二段階パース**: parseMarkdown → parseTextFormatting
- **MarkdownElement**: 型安全なMarkdown要素表現
- **renderInlineMarkdown**: SwiftUIでのMarkdown表示ロジック
- **processListElements**: 階層リスト用の専用処理

## 現在の実装状況
- ✅ 完全なタブベースUI
- ✅ Swift Dataによるデータ永続化
- ✅ グループ機能（CRUD操作）
- ✅ ゴミ箱機能（論理削除・復元）
- ✅ 包括的Markdownサポート（見出し・太字・斜体・取り消し線・リンク・画像・テーブル・リスト・引用・コード）
- ✅ エクスポート機能（Markdown・テキスト・PDF）
- ✅ 検索機能
- ✅ リアルタイムプレビュー機能

## データモデル

### Swift Data Models
```swift
@Model
class Memo {
    var id: UUID
    var title: String          // 32文字制限
    var content: String        // Markdownコンテンツ
    var groupId: UUID?         // オプショナル、グループ未分類可能 
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?       // 論理削除用
}

@Model  
class Group {
    var id: UUID
    var name: String           // グループ名
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?       // 論理削除用
}
```

### DataManager Pattern
- シングルトン設計（`DataManager.shared`）
- `@MainActor`でメインスレッド保証
- CRUD操作の集約化
- 論理削除・復元ロジック
- 検索機能（title・content両方対象）

## Markdown機能

### サポート記法
```markdown
# 見出し1-3
**太字** *斜体* ~~取り消し線~~
`インラインコード`
```複数行コード```
- 箇条書き（階層対応）
1. 番号付きリスト（階層対応）
> 引用
[リンクテキスト](URL)  
![画像説明](画像URL)
| 列1 | 列2 |（テーブル）
```

### レンダリング詳細
- **階層リスト**: 1.→a.→i.→1. の番号付け
- **画像**: AsyncImage、最大高さ300px
- **テーブル**: HTML生成→SwiftUIでパース表示
- **リンク**: タップ可能なLink View

## エクスポート機能

### サポート形式
- **Markdown形式**: 元記法保持、メタデータ付き
- **テキスト形式**: 記法除去済みプレーンテキスト  
- **PDF形式**: A4、ヘッダー・フッター・スタイル付き

### PDF生成フロー
1. Markdown → HTML変換（MarkdownToHTMLConverter）
2. HTML → PDF変換（UIKit PrintPageRenderer）
3. 一時ファイル作成 → iOS標準シェア機能

### エクスポート後のUX
- シェアシート表示
- シェア完了/キャンセル後に編集画面へ自動復帰