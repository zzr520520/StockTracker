import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("行情看板", systemImage: "chart.grid.5x7.fill")
                }
            
            EditRecordView()
                .tabItem {
                    Label("新增数据", systemImage: "square.and.pencil")
                }
            
            HistoryView()
                .tabItem {
                    Label("历史记录", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
