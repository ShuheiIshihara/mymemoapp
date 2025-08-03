# MyMemoApp

Swift + SwiftUI + Swift Dataで構築されたiOS向けMarkdownメモアプリです。リアルタイムプレビュー、グループ管理、エクスポート機能を備えた包括的なメモアプリケーションです。

## 特徴

- 📝 **Markdownエディタ**: リアルタイムプレビュー機能付き
- 📁 **グループ管理**: メモをカテゴリ別に整理
- 🗑️ **ゴミ箱機能**: 論理削除による安全なメモ管理
- 📤 **エクスポート**: Markdown、テキスト、PDF形式での出力
- 🔍 **検索機能**: タイトルと本文の全文検索
- 📱 **ネイティブUI**: SwiftUIによる直感的なユーザーインターフェース

## 技術スタック

- **言語**: Swift 5.9+
- **フレームワーク**: SwiftUI
- **データ永続化**: Swift Data（iOS 17+）
- **アーキテクチャ**: MVVM + 依存性注入
- **対応OS**: iOS 17.0+

## 開発環境

### 必要な環境
- Xcode 15.0+
- iOS 17.0+ SDK
- macOS 14.0+ (開発用)

### プロジェクトのセットアップ

```bash
# リポジトリのクローン
git clone <repository-url>
cd mymemoapp

# Xcodeでプロジェクトを開く
open MyMemoApp.xcodeproj
```

## 開発コマンド

```bash
# プロジェクトをビルド
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp build

# 全テストを実行
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp test

# 特定のテストクラスのみ実行
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp test -only-testing:MyMemoAppTests/MarkdownTests
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp test -only-testing:MyMemoAppTests/ModelTests

# テストプランを使用したテスト実行
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp -testPlan MyMemoApp test
```

## アーキテクチャ

### データ層
- **Swift Data**: Core Data後継の永続化フレームワーク
- **DataManager**: シングルトンパターンでデータ操作を管理
- **Model**: `Memo`と`Group`の@Modelクラス、論理削除対応

### UI層
- **TabView**: 4つのメインタブ（メモ・グループ・ゴミ箱・設定）
- **NavigationStack**: iOS16+の新しいナビゲーション方式
- **MVVM**: @StateObject/@ObservedObjectでリアクティブなUI更新

### エクスポート機能
- **ExportManager**: エクスポート機能の統合管理
- **MarkdownToHTMLConverter**: Markdown → HTML変換
- **PDFGenerator**: UIKit PrintPageRendererを使用したPDF生成

## サポートしているMarkdown記法

| 記法 | 例 | 説明 |
|------|----|----- |
| 見出し | `# 見出し1` | H1-H3まで対応 |
| 太字 | `**太字**` | ボールド表示 |
| 斜体 | `*斜体*` | イタリック表示 |
| 取り消し線 | `~~取り消し~~` | 打ち消し線 |
| インラインコード | `` `コード` `` | モノスペースフォント |
| コードブロック | `` ```コード``` `` | 複数行コード |
| 箇条書き | `- 項目` | 階層リスト対応 |
| 番号付きリスト | `1. 項目` | 階層番号付け |
| 引用 | `> 引用文` | ブロック引用 |
| リンク | `[テキスト](URL)` | タップ可能リンク |
| 画像 | `![説明](URL)` | インライン画像表示 |
| テーブル | `\| 列1 \| 列2 \|` | 表形式表示 |

## プロジェクト構成

```
MyMemoApp/
├── MyMemoApp/
│   ├── Model/           # データモデルとビジネスロジック
│   │   ├── DataManager.swift
│   │   ├── Memo.swift
│   │   ├── Group.swift
│   │   ├── ExportManager.swift
│   │   └── MarkdownToHTMLConverter.swift
│   ├── Views/           # SwiftUI View
│   │   ├── MemoListView.swift
│   │   ├── MemoEditorView.swift
│   │   ├── GroupManageView.swift
│   │   └── TrashView.swift
│   ├── ContentView.swift   # メインタブView
│   └── MyMemoAppApp.swift  # アプリエントリーポイント
├── MyMemoAppTests/      # ユニットテスト
└── MyMemoAppUITests/    # UIテスト
```

## ライセンス

このプロジェクトは [LICENSE](LICENSE) ファイルに記載されたライセンスの下で公開されています。
