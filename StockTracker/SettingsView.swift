import SwiftUI
import UniformTypeIdentifiers

// JSON 文档类型，用于 fileExporter / fileImporter
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
            .fileExporter(isPresented: $showingExporter, document: exportDoc, contentType: .json, defaultFilename: "晴雨板备份_\(Int(Date().timeIntervalSince1970)).json") { result in
                switch result {
                case .success:
                    alertMsg = "导出备份成功！请选择保存位置。"
                case .failure(let err):
                    alertMsg = "导出失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json, .item]) { result in
                switch result {
                case .success(let url):
                    if storage.importFromURL(url) {
                        alertMsg = "导入恢复成功！"
                    } else {
                        alertMsg = "导入失败：文件格式不匹配。"
                    }
                case .failure(let err):
                    alertMsg = "读取文件失败: \(err.localizedDescription)"
                }
                showAlert = true
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
