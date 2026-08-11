import SwiftUI
import SafariServices

// 使用 SFSafariViewController 完全模拟原生浏览器环境
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredBarTintColor = UIColor.systemBackground
        vc.preferredControlTintColor = UIColor.systemRed
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// 供 Modal 弹窗调用的容器
struct WebSheetView: View {
    let urlString: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if let url = URL(string: urlString) {
            SafariView(url: url)
                .edgesIgnoringSafeArea(.all)
        } else {
            VStack {
                Text("无效的网址")
                Button("关闭") { dismiss() }
            }
        }
    }
}
