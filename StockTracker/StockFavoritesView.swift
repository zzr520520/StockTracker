import SwiftUI

struct StockFavoritesView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var newCode = ""
    @State private var newName = ""
    @State private var selectedStockURL: String? = nil
    
    var sortedStocks: [StockItem] {
        storage.favoriteStocks.sorted { $0.isPinned && !$1.isPinned }
    }
    
    // 全市场兼容：A股、港股、美股智能识别逻辑
    private func getTHSStockURL(code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var formattedCode = clean
        
        // 1. 如果自带前缀直接使用
        if clean.hasPrefix("hs_") || clean.hasPrefix("sz_") || clean.hasPrefix("hk_") || clean.hasPrefix("us_") {
            formattedCode = clean
        } 
        // 2. 港股判断：5位数字（如 00700、09988）
        else if clean.count == 5 && Int(clean) != nil {
            formattedCode = "hk_" + clean
        }
        // 3. A股沪市判断：6开头、9开头、688等
        else if clean.hasPrefix("6") || clean.hasPrefix("9") || clean.hasPrefix("688") || clean.hasPrefix("1a") {
            formattedCode = "hs_" + clean
        }
        // 4. A股深市判断：00、300等
        else if clean.count == 6 && Int(clean) != nil {
            formattedCode = "sz_" + clean
        }
        // 5. 纯字母默认美股（如 AAPL）
        else {
            formattedCode = "us_" + clean
        }
        
        return "https://m.10jqka.com.cn/stockpage/\(formattedCode)/#refCountId=R_554997ea_731&atab=geguNews"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    TextField("代码(如 00700 或 600519)", text: $newCode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.asciiCapable)
                        .frame(width: 150)
                    
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
                            .buttonStyle(PlainButtonStyle())
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
