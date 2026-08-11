import SwiftUI

struct StockFavoritesView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var newCode = ""
    @State private var newName = ""
    @State private var selectedStockURL: String? = nil
    
    var sortedStocks: [StockItem] {
        storage.favoriteStocks.sorted { $0.isPinned && !$1.isPinned }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 顶部新增股票输入框
                HStack {
                    TextField("代码(如 600519)", text: $newCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 130)
                    
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
                            VStack(alignment: .leading) {
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
                            
                            Button("查看行情") {
                                // 拼接同花顺网页端个股链接
                                selectedStockURL = "https://m.10jqka.com.cn/stockpage/\(stock.code)/"
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .controlSize(.small)
                        }
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
