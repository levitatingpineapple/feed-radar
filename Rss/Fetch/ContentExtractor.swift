import WebKit

class ContentExtractor: NSObject {
	private let webView = WKWebView()
	private var continuation: CheckedContinuation<String, Error>?
	
	override init() {
		super.init()
		webView.navigationDelegate = self
		webView.configuration.suppressesIncrementalRendering = true
		webView.configuration.userContentController.addUserScript(
			WKUserScript(
				source: try! String(
					contentsOf: Bundle.main.url(forResource: "Readability", withExtension: "js")!,
					encoding: .utf8
				),
				injectionTime: .atDocumentStart,
				forMainFrameOnly: true
			)
		)
	}
	
	func extract(from url: URL) async throws -> String {
		await webView.load(URLRequest(url: url))
		return try await withCheckedThrowingContinuation { continuation = $0 }
	}
}

extension ContentExtractor: WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.evaluateJavaScript("new Readability(document).parse();") { result, error in
			if let parsed = result as? NSDictionary,
			   let content = parsed["content"] as? String {
				self.continuation?.resume(returning: content)
			} else if let error {
				self.continuation?.resume(throwing: error)
			} else {
				self.continuation?.resume(returning: "Parsing Error")
			}
		}
	}
}

