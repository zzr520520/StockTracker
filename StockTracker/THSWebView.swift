import SwiftUI
import WebKit

struct THSWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // 关键配置：模拟移动端 Mobile Safari 浏览器，防止被同花顺识别防刷拦截
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString), uiView.url?.absoluteString != urlString {
            uiView.load(URLRequest(url: url))
        }
    }
}

struct WebSheetView: View {
    let urlString: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            THSWebView(urlString: urlString)
                .navigationBarTitle("同花顺行情", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
