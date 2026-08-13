import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var searchText = ""
    @State private var shareURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showImporter = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var filteredRecords: [DailyRecord] {
        let all = Array(storage.records.values).sorted { $0.recordKey > $1.recordKey }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return all
        }
        var result: [DailyRecord] = []
        for record in all {
            let matchDate = record.recordKey.contains(trimmed)
            var matchRemark = false
            for row in record.rows {
                if row.rowRemark.contains(trimmed) {
                    matchRemark = true
                    break
                }
            }
            if matchDate || matchRemark {
                result.append(record)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("备份与恢复")) {
                        HStack(spacing: 12) {
                            Button(action: exportAndShareZip) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("分享导出 Zip 备份")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { showImporter = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("导入 Zip 恢复")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section(header: Text("历史月份记录")) {
                        ForEach(filteredRecords) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(record.recordKey)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("大涨:\(record.bigUpCount) 小涨:\(record.smallUpCount) 大跌:\(record.bigDownCount) 小跌:\(record.smallDownCount)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                let remarks = record.rows.filter { $0.isSet && !$0.rowRemark.isEmpty }.map { $0.rowRemark }
                                if !remarks.isEmpty {
                                    Text("备注: \(remarks.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = filteredRecords[index]
                                storage.deleteRecord(key: item.recordKey)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("历史记录")
            .searchable(text: $searchText, prompt: "搜索年月或备注内容...")
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL { ShareSheet(activityItems: [url]) }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip, .archive, .item]) { result in
                switch result {
                case .success(let url):
                    if storage.importFromURL(url) {
                        alertMessage = "恢复备份数据成功！"
                    } else { alertMessage = "导入失败：文件无效。" }
                case .failure(let err):
                    alertMessage = "读取失败: \(err.localizedDescription)"
                }
                showAlert = true
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            }
        }
    }
    
    private func exportAndShareZip() {
        if let url = storage.generateZipFileURL() {
            self.shareURL = url
            self.showShareSheet = true
        } else {
            alertMessage = "生成备份失败"
            showAlert = true
        }
    }
}
