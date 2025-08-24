//
//  MyMemoAppApp.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/16.
//

import SwiftUI
import SwiftData

@main
struct MyMemoAppApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
        .modelContainer(dataManager.container)
    }
}
