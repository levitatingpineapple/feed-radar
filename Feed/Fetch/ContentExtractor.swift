import WebKit

actor ContentExtractor {
	static let shared = ContentExtractor()
	private let readability = Readability()
	
	func extract(item: Item) async throws {
		if let url = item.url {
			if var fetchedItem = Store.shared.item(id: item.id),
			   fetchedItem.extracted == nil {
				fetchedItem.extracted = try await readability.extract(from: url)
				Store.shared.update(item: fetchedItem)
			}
		}
	}
}

private class Readability: NSObject {
	let webView = WKWebView()
	var continuation: CheckedContinuation<String, Error>?
	
	enum ReadabilityError: Error {
		case parsingError
	}
	
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
	
	public func extract(from url: URL) async throws -> String {
		await webView.load(URLRequest(url: url))
		return try await withCheckedThrowingContinuation { continuation = $0 }
	}
}

extension Readability: WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		webView.evaluateJavaScript("new Readability(document).parse()") { result, error in
			if let parsed = result as? NSDictionary,
			   let content = parsed["content"] as? String {
				self.continuation?.resume(returning: content)
			} else if let error {
				self.continuation?.resume(throwing: error)
			} else {
				self.continuation?.resume(throwing: ReadabilityError.parsingError)
			}
			self.continuation = nil
		}
	}
}

