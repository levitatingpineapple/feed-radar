import SwiftUI
import WebKit

#if os(macOS)
struct WebView: NSViewRepresentable {
	let html: WKWebView.Content

	func makeNSView(context: Context) -> WKWebView {
		let view = WKWebView()
		view.setValue(true, forKey: "drawsTransparentBackground")
		view.configuration.preferences.isElementFullscreenEnabled = true
		view.configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
		return view
	}
	
	func updateNSView(_ webView: WKWebView, context: Context) {
		webView.load(html)
	}
}
#elseif os(iOS)
struct WebView: UIViewRepresentable {
	let html: WKWebView.Content

	func makeUIView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.isOpaque = false
		webView.backgroundColor = .clear
		return webView
	}
	
	func updateUIView(_ webView: WKWebView, context: Context) {
		webView.load(html)
	}
}
#endif

extension WKWebView {
	enum Content {
		case html(String)
		case url(URL)
	}
	
	func load(_ content: Content) {
		switch content {
		case let .html(html):
			loadHTMLString("""
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
\(try! String(contentsOf: Bundle.main.url(forResource: "style", withExtension: "css")!))
</style>
</head>
<body>
\(html)
</body>
</html>
""", baseURL: nil)
		case let .url(url):
			load(URLRequest(url: url))
		}
	}
}

#if os(iOS)
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(context: Context) -> SFSafariViewController {
		SFSafariViewController(url: url, entersReaderIfAvailable: true)
	}
	
	func updateUIViewController(_: SFSafariViewController, context: Context) {
		
	}
}
#endif
