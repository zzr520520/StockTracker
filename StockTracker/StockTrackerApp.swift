import SwiftUI

@main
struct StockTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.locale, Locale(identifier: "zh_CN")) // 强制全 App 语言环境为简体中文
        }
    }
}
