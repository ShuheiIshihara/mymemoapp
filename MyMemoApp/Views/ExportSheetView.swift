//
//  ExportSheetView.swift
//  MyMemoApp
//
//  Created by 石原脩平 on 2025/07/30.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let memo: ExportableMemo
    let exportManager: ExportManager
    
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var isExporting = false
    @State private var exportError: ExportManager.ExportError?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // メモ情報表示
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memo.title.isEmpty ? "無題のメモ" : memo.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text("\(memo.content.count) 文字")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text("作成日: \(formatDate(memo.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // エクスポート形式選択
                VStack(spacing: 16) {
                    Text("エクスポート形式を選択")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        ExportFormatButton(
                            icon: "doc.plaintext",
                            title: "Markdown形式",
                            description: "元のMarkdown記法を保持",
                            format: .markdown,
                            isExporting: isExporting
                        ) {
                            exportMemo(format: .markdown)
                        }
                        
                        ExportFormatButton(
                            icon: "doc.text",
                            title: "テキスト形式",
                            description: "Markdown記法を除去したプレーンテキスト",
                            format: .text,
                            isExporting: isExporting
                        ) {
                            exportMemo(format: .text)
                        }
                        
                        ExportFormatButton(
                            icon: "doc.richtext",
                            title: "PDF形式",
                            description: "印刷可能なPDFファイル（近日対応予定）",
                            format: .pdf,
                            isExporting: isExporting,
                            isDisabled: true
                        ) {
                            // PDFは後で実装
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("エクスポートエラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(exportError?.localizedDescription ?? "エクスポートに失敗しました")
        }
    }
    
    private func exportMemo(format: ExportManager.ExportFormat) {
        isExporting = true
        
        Task {
            do {
                let url = try exportManager.exportExportableMemo(memo, format: format)
                
                await MainActor.run {
                    shareURL = url
                    showingShareSheet = true
                    isExporting = false
                }
            } catch let error as ExportManager.ExportError {
                await MainActor.run {
                    exportError = error
                    showingError = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = .fileCreationFailed
                    showingError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct ExportFormatButton: View {
    let icon: String
    let title: String
    let description: String
    let format: ExportManager.ExportFormat
    let isExporting: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isDisabled ? .gray : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDisabled ? .gray : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(isDisabled ? .gray : .blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDisabled ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled || isExporting)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 更新処理は不要
    }
}

#Preview {
    let sampleMemo = ExportableMemo(title: "サンプルメモ", content: "# 見出し\n\nこれは**太字**のテストです。")
    ExportSheetView(memo: sampleMemo, exportManager: ExportManager())
}