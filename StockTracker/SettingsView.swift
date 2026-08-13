import SwiftUI
import UniformTypeIdentifiers

// MARK: - 设置页面（使用剪贴板 + 文本粘贴方式备份恢复，彻底放弃文件选择器）
struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var alertMsg = ""
    @State private var showAlert = false
    @State private var showRestoreSheet = false
    @State private var pasteText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("数据备份"), footer: Text("点击备份数据会自动复制到剪贴板，同时弹出分享面板可保存到文件。")) {
                    Button(action: exportBackup) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("备份数据（复制到剪贴板）")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("数据恢复"), footer: Text("点击恢复数据后，粘贴之前备份的 JSON 文本即可恢复。")) {
                    Button(action: { 
                        pasteText = ""
                        showRestoreSheet = true 
                    }) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("恢复数据（粘贴 JSON）")
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
            // 恢复数据的粘贴 Sheet
            .sheet(isPresented: $showRestoreSheet) {
                RestorePasteView(
                    pasteText: $pasteText,
                    onRestore: {
                        if storage.importFromString(pasteText) {
                            alertMsg = "恢复成功！共 \(storage.records.count) 条记录"
                        } else {
                            alertMsg = "恢复失败：JSON 格式不正确"
                        }
                        showRestoreSheet = false
                        showAlert = true
                    },
                    onCancel: {
                        showRestoreSheet = false
                    }
                )
            }
        }
    }
    
    // 备份：复制 JSON 到剪贴板 + 弹出分享面板
    private func exportBackup() {
        guard let jsonString = storage.generateBackupString() else {
            alertMsg = "生成备份数据失败"
            showAlert = true
            return
        }
        
        // 1. 复制到剪贴板
        UIPasteboard.general.string = jsonString
        
        // 2. 同时写临时文件，弹出系统分享面板（可选保存到文件）
        let fileName = "晴雨板备份_\(Int(Date().timeIntervalSince1970)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try jsonString.data(using: .utf8)!.write(to: tempURL)
            // 延迟弹出分享面板，确保剪贴板已写入
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.presentShareSheet(items: [tempURL])
            }
            alertMsg = "数据已复制到剪贴板！\n也可通过分享面板保存到文件。"
        } catch {
            alertMsg = "数据已复制到剪贴板！"
        }
        showAlert = true
    }
    
    private func presentShareSheet(items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        top.present(activityVC, animated: true)
    }
}

// MARK: - 恢复数据粘贴页面
struct RestorePasteView: View {
    @Binding var pasteText: String
    let onRestore: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("粘贴备份 JSON 文本")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("打开备忘录或其他 App，粘贴之前复制的备份内容，再粘贴到下方输入框")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // 从剪贴板粘贴按钮
                Button(action: {
                    if let clip = UIPasteboard.general.string {
                        pasteText = clip
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("从剪贴板粘贴")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                TextEditor(text: $pasteText)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .padding(.horizontal)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("恢复数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("恢复") { onRestore() }
                        .fontWeight(.bold)
                        .foregroundColor(pasteText.isEmpty ? .gray : .blue)
                        .disabled(pasteText.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}
