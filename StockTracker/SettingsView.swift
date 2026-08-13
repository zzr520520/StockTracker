import SwiftUI
import UniformTypeIdentifiers

// JSON 文档类型，用于 fileExporter
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            self.data = Data()
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// 使用 UIDocumentPickerViewController 替代 SwiftUI fileImporter
// 解决在 sheet 内部 fileImporter 点击文件无反应的问题
struct DocumentPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.item])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // 用户取消，无需处理
        }
    }
}

struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDoc: JSONDocument? = nil
    @State private var alertMsg = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("数据备份与恢复")) {
                    // 导出备份
                    Button(action: exportBackup) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出备份 (JSON)")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // 导入恢复
                    Button(action: { showingImporter = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("导入恢复 (JSON)")
                        }
                        .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("数据管理")) {
                    Text("当前共有 \(storage.records.count) 条月度记录")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            // 导出用 fileExporter（正常工作）
            .fileExporter(isPresented: $showingExporter, document: exportDoc, contentType: .json, defaultFilename: "晴雨板备份_\(Int(Date().timeIntervalSince1970)).json") { result in
                switch result {
                case .success:
                    alertMsg = "导出备份成功！"
                case .failure(let err):
                    alertMsg = "导出失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            // 导入用 UIDocumentPickerViewController（修复在 sheet 内无响应的问题）
            .sheet(isPresented: $showingImporter) {
                DocumentPickerView { url in
                    if storage.importFromURL(url) {
                        alertMsg = "导入恢复成功！"
                    } else {
                        alertMsg = "导入失败：文件格式不匹配或读取失败。"
                    }
                    showAlert = true
                }
            }
            .alert(alertMsg, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
        }
    }
    
    private func exportBackup() {
        if let data = storage.generateBackupData() {
            self.exportDoc = JSONDocument(data: data)
            self.showingExporter = true
        } else {
            alertMsg = "生成备份数据失败"
            showAlert = true
        }
    }
}
