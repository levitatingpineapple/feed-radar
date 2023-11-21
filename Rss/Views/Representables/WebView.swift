import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
	let url: URL
	
	func makeUIView(context: Context) -> some WKWebView {
		WKWebView()
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) {
		uiView.load(URLRequest(url: url))
	}
}
