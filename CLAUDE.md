# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要
Swift + SwiftUI + Swift Dataで構築されたiOS Markdownメモアプリ。グループ機能、ゴミ箱、エクスポート、同期機能を含む完全版として開発。

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
- **次のステップ**: 完全版データモデル実装（グループ、ゴミ箱対応）

## フルバージョン機能
### 主要機能
- **基本メモ機能**: CRUD操作、タイトル + Markdownコンテンツ編集
- **グループ機能**: 手動カテゴリ設定、アコーディオン式表示
- **ゴミ箱機能**: 論理削除、復元・完全削除機能
- **エクスポート機能**: PDF・Markdown形式、単一メモ対象
- **表形式変換**: タブ区切りテキスト、専用モーダル入力
- **オフライン対応**: ローカルキャッシュ、同期機能
- **設定画面**: 表示設定、テーマ設定、エクスポート設定

## データモデル
完全版データスキーマ:

### メモテーブル (Memo)
```swift
- id: UUID（プライマリキー）
- title: String（32文字制限）
- content: String（Markdownコンテンツ）
- groupId: UUID?（グループID、NULL許可）
- createdAt: Date
- updatedAt: Date
- deletedAt: Date?（ゴミ箱用論理削除）
```

### グループテーブル (Group)
```swift
- id: UUID（プライマリキー）
- name: String（手動設定）
- createdAt: Date
- updatedAt: Date
- deletedAt: Date?（論理削除）
```

## UI設計仕様
### 画面構成（タブバー型）
1. **メモ一覧**: アコーディオン式グループ表示
2. **グループ管理**: グループCRUD操作
3. **ゴミ箱**: 削除メモ管理
4. **設定**: アプリ設定

### 編集画面仕様
- **表示**: タブ切り替え（編集/プレビュー）
- **クイックプレビュー**: 長押しで一時プレビュー
- **遷移**: プッシュ遷移
- **保存**: 手動保存
- **操作**: 長押しでコンテキストメニュー

### 詳細仕様
- **日時表示**: 「2025/07/16 15:30」形式
- **アコーディオン**: 起動時は閉じた状態
- **タイトル制限**: 32文字まで
- **文字数制限**: 本文は制限なし

## 開発ステップ
1. ✅ プロジェクト設定と基本Memoモデル
2. 🔄 完全版データモデル実装（Memo + Group）
3. 📱 タブバー式UI実装
4. 📝 Markdownレンダリング
5. 🗂️ グループ・ゴミ箱機能実装
6. 📤 エクスポート・表形式変換実装
7. ⚙️ 設定画面実装
8. 🔄 Supabase同期実装