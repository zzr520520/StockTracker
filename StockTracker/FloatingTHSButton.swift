import SwiftUI

struct FloatingTHSButtonModifier: ViewModifier {
    @State private var showWeb = false
    @State private var webURL = "https://www.10jqka.com.cn/"
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        webURL = "https://www.10jqka.com.cn/"
                        showWeb = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.diagonal.arrow.trianglehead.rise.box.fill")
                            Text("同花顺官网")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showWeb) {
            WebSheetView(urlString: webURL)
        }
    }
}

extension View {
    func withFloatingTHSButton() -> some View {
        self.modifier(FloatingTHSButtonModifier())
    }
}
