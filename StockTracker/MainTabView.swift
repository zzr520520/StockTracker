import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("晴雨板", systemImage: "sun.rain.fill")
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
