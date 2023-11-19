import SwiftUI
import WebKit

struct HtmlView: UIViewRepresentable {
	let body: String
	
	func sizeThatFits(_ proposal: ProposedViewSize, uiView: WebView, context: Context) -> CGSize? {
		return CGSize(width: proposal.width!, height: uiView.intrinsicContentSize.height - 3)
	}
	
	func makeUIView(context: Context) -> WebView { WebView() }
	
	func updateUIView(_ webView: WebView, context: Context) {
		webView.loadHTMLString(body.wrappedInHtml, baseURL: nil)
	}
}

extension HtmlView {
	class WebView: WKWebView, WKNavigationDelegate {
		
		override var intrinsicContentSize: CGSize {
			CGSize(width: bounds.width, height: scrollView.contentSize.height)
		}
		
		var observer: NSKeyValueObservation?
		
		init() {
			super.init(frame: .zero, configuration: .init())
			isOpaque = false
			backgroundColor = .clear
			navigationDelegate = self

			scrollView.isScrollEnabled = false
			observer = scrollView.observe(
				\UIScrollView.contentSize,
				 options: [NSKeyValueObservingOptions.new]
			) { [weak self] (scrollView: UIScrollView, change: NSKeyValueObservedChange<CGSize>) in
				if let contentSize = change.newValue, let self, contentSize.height > self.bounds.height {
					self.invalidateIntrinsicContentSize()
				}
			}
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) { fatalError("Missing Coder") }
		
		func webView(
			_ webView: WKWebView,
			decidePolicyFor navigationAction: WKNavigationAction,
			decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
		) {
			if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
				decisionHandler(.cancel)
				UIApplication.shared.open(url)
			} else {
				decisionHandler(.allow)
			}
		}
		
	}
}


extension String {
	
	var wrappedInHtml: String { """
<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="initial-scale=1.5">
		<style>
			\(try! String(contentsOf: Bundle.main.url(forResource: "style", withExtension: "css")!))
		</style>
	</head>
	<body>
		\(self)
	</body>
</html>
"""
	}

}
