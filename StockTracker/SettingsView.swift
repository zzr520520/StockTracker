import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件选择器（直接从 root VC 弹出，绕过 SwiftUI sheet 嵌套问题）
class DocumentImporter: ObservableObject {
    static let shared = DocumentImporter()
    var pickerDelegate: DocumentPickerDelegate?
    
    func pickFile(completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            guard let rootVC = self.getRootViewController() else {
                completion(nil)
                return
            }
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.item, UTType.data])
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true
            
            let delegate = DocumentPickerDelegate(completion: completion)
            self.pickerDelegate = delegate  // 强引用，防止被释放
            picker.delegate = delegate
            
            rootVC.present(picker, animated: true)
        }
    }
    
    func presentShareSheet(items: [Any]) {
        DispatchQueue.main.async {
            guard let rootVC = self.getRootViewController() else { return }
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            // iPad 适配
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = rootVC.view
                pop.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return nil
        }
        // 找到最顶层的 VC
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let completion: (URL?) -> Void
    
    init(completion: @escaping (URL?) -> Void) {
        self.completion = completion
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        DocumentImporter.shared.pickerDelegate = nil  // 释放
        completion(urls.first)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        DocumentImporter.shared.pickerDelegate = nil  // 释放
        completion(nil)
    }
}

// MARK: - 设置页面
struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var alertMsg = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("数据备份与恢复"), footer: Text("导出：将数据保存为 JSON 文件\n导入：从 JSON 文件恢复数据")) {
                    // 导出备份
                    Button(action: exportBackup) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出备份 (JSON)")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // 导入恢复
                    Button(action: importBackup) {
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
            .alert(alertMsg, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
        }
    }
    
    // 导出：写 JSON 到临时文件，通过系统分享面板保存
    private func exportBackup() {
        guard let data = storage.generateBackupData() else {
            alertMsg = "生成备份数据失败"
            showAlert = true
            return
        }
        
        let fileName = "晴雨板备份_\(Int(Date().timeIntervalSince1970)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            // 从 root VC 直接弹出分享面板，不经过 SwiftUI sheet
            DocumentImporter.shared.presentShareSheet(items: [tempURL])
        } catch {
            alertMsg = "导出失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // 导入：从 root VC 直接弹出文件选择器，不经过 SwiftUI sheet
    private func importBackup() {
        DocumentImporter.shared.pickFile { url in
            DispatchQueue.main.async {
                guard let url = url else { return }  // 用户取消
                
                if storage.importFromURL(url) {
                    alertMsg = "导入恢复成功！共 \(storage.records.count) 条记录"
                } else {
                    alertMsg = "导入失败：文件格式不匹配或读取失败"
                }
                showAlert = true
            }
        }
    }
}
