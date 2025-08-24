//
//  MyMemoAppUITests.swift
//  MyMemoAppUITests
//
//  Created by 石原脩平 on 2025/07/16.
//

import XCTest

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard self.value != nil else {
            XCTFail("Tried to clear and enter text into a non-text element")
            return
        }
        
        self.tap()
        
        if let stringValue = self.value as? String {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            self.typeText(deleteString)
        }
        
        self.typeText(text)
    }
}

final class MyMemoAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCreateNewMemo() throws {
        let app = XCUIApplication()
        app.launch()
        
        // メモタブに移動
        app.tabBars.buttons["メモ"].tap()
        
        // 新規メモ作成ボタンをタップ
        app.navigationBars.buttons["plus"].tap()
        
        // タイトルを入力
        let titleField = app.textFields["タイトル（最大32文字）"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("UIテストメモ")
        
        // 内容を入力
        let contentTextView = app.textViews.firstMatch
        contentTextView.tap()
        contentTextView.typeText("これはUIテストで作成されたメモです。")
        
        // 保存ボタンをタップ
        app.navigationBars.buttons["保存"].tap()
        
        // メモ一覧に戻って、作成されたメモが表示されることを確認
        let createdMemo = app.staticTexts["UIテストメモ"]
        XCTAssertTrue(createdMemo.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testEditExistingMemo() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 前提：メモが存在している必要がある
        // まず新規メモを作成
        app.tabBars.buttons["メモ"].tap()
        app.navigationBars.buttons["plus"].tap()
        
        let titleField = app.textFields["タイトル（最大32文字）"]
        titleField.tap()
        titleField.typeText("編集テストメモ")
        
        let contentTextView = app.textViews.firstMatch
        contentTextView.tap()
        contentTextView.typeText("編集前の内容")
        
        app.navigationBars.buttons["保存"].tap()
        
        // 作成されたメモをタップして編集画面を開く
        let memo = app.staticTexts["編集テストメモ"]
        XCTAssertTrue(memo.waitForExistence(timeout: 5))
        memo.tap()
        
        // タイトルを編集
        let editTitleField = app.textFields["タイトル（最大32文字）"]
        editTitleField.tap()
        editTitleField.clearAndEnterText("編集後のタイトル")
        
        // 内容を編集
        let editContentTextView = app.textViews.firstMatch
        editContentTextView.tap()
        editContentTextView.clearAndEnterText("編集後の内容です。")
        
        // 保存
        app.navigationBars.buttons["保存"].tap()
        
        // 編集されたタイトルが表示されることを確認
        let editedMemo = app.staticTexts["編集後のタイトル"]
        XCTAssertTrue(editedMemo.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        let tabBar = app.tabBars.firstMatch
        
        // メモタブ
        tabBar.buttons["メモ"].tap()
        XCTAssertTrue(app.navigationBars["メモ"].waitForExistence(timeout: 5))
        
        // グループタブ
        tabBar.buttons["グループ"].tap()
        XCTAssertTrue(app.navigationBars["グループ管理"].waitForExistence(timeout: 5))
        
        // ゴミ箱タブ
        tabBar.buttons["ゴミ箱"].tap()
        XCTAssertTrue(app.navigationBars["ゴミ箱"].waitForExistence(timeout: 5))
        
        // 設定タブ
        tabBar.buttons["設定"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testSearchFunctionality() throws {
        let app = XCUIApplication()
        app.launch()
        
        // メモタブに移動
        app.tabBars.buttons["メモ"].tap()
        
        // テスト用メモを2つ作成
        // メモ1
        app.navigationBars.buttons["plus"].tap()
        app.textFields["タイトル（最大32文字）"].tap()
        app.textFields["タイトル（最大32文字）"].typeText("検索テスト1")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("Swift開発について")
        app.navigationBars.buttons["保存"].tap()
        
        // メモ2
        app.navigationBars.buttons["plus"].tap()
        app.textFields["タイトル（最大32文字）"].tap()
        app.textFields["タイトル（最大32文字）"].typeText("検索テスト2")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("料理のレシピ")
        app.navigationBars.buttons["保存"].tap()
        
        // 検索を実行
        let searchField = app.textFields["メモを検索"]
        searchField.tap()
        searchField.typeText("Swift")
        
        // 検索結果を確認
        XCTAssertTrue(app.staticTexts["検索テスト1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["検索テスト2"].exists)
        
        // 検索をクリア
        if app.buttons["xmark.circle.fill"].exists {
            app.buttons["xmark.circle.fill"].tap()
        }
        
        // 両方のメモが表示されることを確認
        XCTAssertTrue(app.staticTexts["検索テスト1"].exists)
        XCTAssertTrue(app.staticTexts["検索テスト2"].exists)
    }
    
    @MainActor
    func testGroupManagement() throws {
        let app = XCUIApplication()
        app.launch()
        
        // グループタブに移動
        app.tabBars.buttons["グループ"].tap()
        
        // 新規グループ作成
        app.navigationBars.buttons["plus"].tap()
        
        let groupNameField = app.textFields.firstMatch
        groupNameField.tap()
        groupNameField.typeText("UIテストグループ")
        
        app.buttons["保存"].tap()
        
        // 作成されたグループが表示されることを確認
        XCTAssertTrue(app.staticTexts["UIテストグループ"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
