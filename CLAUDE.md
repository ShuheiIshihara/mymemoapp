# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要
Swift + SwiftUI + Swift Dataで構築されたiOS Markdownメモアプリ。単一デバイス使用を対象とし、オプションでSupabase同期機能を予定。

## アーキテクチャ
- **MyMemoApp/**: メインアプリモジュール
  - `MyMemoAppApp.swift`: アプリエントリーポイント
  - `ContentView.swift`: メインUI（現在プレースホルダー）
  - `Model/Memo.swift`: コアデータモデル
- **MyMemoAppTests/**: ユニットテスト
- **MyMemoAppUITests/**: UIテスト

## 開発コマンド
```bash
# プロジェクトをビルド
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp build

# テストを実行
xcodebuild -project MyMemoApp.xcodeproj -scheme MyMemoApp test

# Xcodeで開く
open MyMemoApp.xcodeproj
```

## 現在の開発状況
- **完了**: Xcodeプロジェクト設定、基本Memoモデル
- **次のステップ**: MVP用Swift Data統合の実装

## MVP範囲
### コア機能
- 基本メモCRUD操作
- タイトル + Markdownコンテンツ編集
- Swift Dataによるローカルストレージ
- シンプルなリストビューと編集ビュー

### 後回しの機能
- グループ、ゴミ箱、エクスポート、表形式変換、クイックプレビュー、同期、設定

## データモデル
現在のMemo構造体 (MyMemoApp/Model/Memo.swift):
```swift
struct Memo {
    let id: UUID
    var title: String
    var content: String  // Markdownコンテンツ
    let createdAt: Date
    var updatedAt: Date
}
```

フルバージョンの将来のデータベーススキーマには、グループ、論理削除、Supabase同期が含まれます。

## UI設計思想
- コンテンツ作成を優先したシンプルで集中的なインターフェース
- オプションのプレビュー機能付きMarkdown編集
- iOS固有のナビゲーションパターン
- タイトル制限: 32文字
- 手動保存方式

## 開発ステップ
1. ✅ プロジェクト設定と基本Memoモデル
2. 🔄 ローカルストレージ用Swift Data統合
3. 📱 基本UI実装（リスト + 編集ビュー）
4. 📝 Markdownレンダリング
5. 🔄 フル機能実装（グループ、同期など）