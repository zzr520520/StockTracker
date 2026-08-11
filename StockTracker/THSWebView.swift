import SwiftUI
import WebKit

struct THSWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
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

// 网页弹窗 Modal
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
