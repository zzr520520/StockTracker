import SwiftUI

struct StockFavoritesView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var newCode = ""
    @State private var newName = ""
    @State private var selectedStockURL: String? = nil
    
    var sortedStocks: [StockItem] {
        storage.favoriteStocks.sorted { $0.isPinned && !$1.isPinned }
    }
    
    // 精准对齐同花顺真实 H5 路径逻辑
    private func getTHSStockURL(code: String) -> String {
        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var formattedCode = cleanCode
        
        // 自动补全 hs_ 或 sz_ 前缀
        if !cleanCode.hasPrefix("hs_") && !cleanCode.hasPrefix("sz_") {
            // 沪市/上证指数：6开头、9开头、688科创板、1A指数等
            if cleanCode.hasPrefix("6") || cleanCode.hasPrefix("9") || cleanCode.hasPrefix("688") || cleanCode.hasPrefix("1a") {
                formattedCode = "hs_" + cleanCode
            } else {
                formattedCode = "sz_" + cleanCode
            }
        }
        
        // 生成完全正确的链接结构
        return "https://m.10jqka.com.cn/stockpage/\(formattedCode)/#refCountId=R_554997ea_731&atab=geguNews"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部输入栏
                HStack(spacing: 10) {
                    TextField("代码(如 600519)", text: $newCode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.asciiCapable)
                        .frame(width: 140)
                    
                    TextField("股票名称", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addStock) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                // 列表展示区
                List {
                    ForEach(sortedStocks) { stock in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if stock.isPinned {
                                        Image(systemName: "pin.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    Text(stock.name)
                                        .font(.headline)
                                }
                                Text(stock.code)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedStockURL = getTHSStockURL(code: stock.code)
                            }) {
                                Text("查看行情")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle()) // 规避单元格高亮干扰
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(stock)
                            } label: {
                                Label(stock.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                    }
                    .onDelete(perform: deleteStock)
                }
                .listStyle(.plain)
            }
            .navigationTitle("自选收藏")
            .sheet(item: Binding(
                get: { selectedStockURL != nil ? IdentifiableURL(url: selectedStockURL!) : nil },
                set: { selectedStockURL = $0?.url }
            )) { item in
                WebSheetView(urlString: item.url)
            }
            .withFloatingTHSButton()
        }
    }
    
    private func addStock() {
        guard !newCode.isEmpty, !newName.isEmpty else { return }
        let item = StockItem(code: newCode, name: newName)
        storage.favoriteStocks.append(item)
        storage.saveStocks()
        newCode = ""
        newName = ""
    }
    
    private func togglePin(_ stock: StockItem) {
        if let idx = storage.favoriteStocks.firstIndex(where: { $0.id == stock.id }) {
            storage.favoriteStocks[idx].isPinned.toggle()
            storage.saveStocks()
        }
    }
    
    private func deleteStock(at offsets: IndexSet) {
        storage.favoriteStocks.remove(atOffsets: offsets)
        storage.saveStocks()
    }
}

struct IdentifiableURL: Identifiable {
    var id: String { url }
    let url: String
}
