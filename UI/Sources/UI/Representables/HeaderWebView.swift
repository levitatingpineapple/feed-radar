import UIKit
import SwiftUI
import os.log
import WebKit
import Core

struct HeaderWebView: UIViewRepresentable {
	let extracted: Bool
	let item: Item
	@Environment(\.self) var environment
	@State var cache = Cache()
	
	func makeUIView(context: Context) -> WebView {
		Self.queue.webView
	}

	func updateUIView(_ webView: WebView, context: Context) {
		let html = Html(
			body: extracted ? item.extracted : item.content,
			in: environment
		)
		if cache.html != html?.hashValue {
			webView.loadHTMLString(html?.description ?? Html.blank, baseURL: item.url)
			cache.html = html?.hashValue
		}
		if cache.item != item {
			webView.headerController.rootView = HeaderView(
				item: item
			) { [weak webView] in webView?.setNeedsLayout() }
			cache.item = item
		}
	}

	static func dismantleUIView(_ webView: WebView, coordinator: Void) {
		Self.queue.release(webView)
	}

	// The `EnvironmentValues` is used to infer the colors used by the `WebView`s style
	// Observing it however will cause many unneeded updates
	// Cache helps to filter out updates, which does not affect the `ViewController`
	class Cache {
		var item: Item? = nil
		var html: Int? = nil
	}

	class WebView: WKWebView {
		let headerController = UIHostingController<HeaderView?>(rootView: .none)

		init() {
			super.init(frame: .zero, configuration: .init())
			navigationDelegate = self
			isOpaque = false
			backgroundColor = .clear
			headerController.view.backgroundColor = .clear
			scrollView.addSubview(headerController.view)
			loadHTMLString(Html.blank, baseURL: nil)
		}

		@available(*, unavailable)
		required init(coder: NSCoder) { fatalError() }

		override func layoutSubviews() {
			super.layoutSubviews()
			let width = bounds.width - safeAreaInsets.left - safeAreaInsets.right
			let sizeThatFits = headerController.view.sizeThatFits(
				CGSize(width: width, height: .infinity)
			)
			headerController.view.frame = CGRect(
				x: .zero,
				y: -sizeThatFits.height,
				width: width,
				height: sizeThatFits.height
			)
			// Workaround for inset jumping, while loading web content in `.doubleColumn` visibility.
			if case .regular = traitCollection.horizontalSizeClass {
				scrollView.contentInsetAdjustmentBehavior = .never
				scrollView.contentInset = safeAreaInsets
				scrollView.contentInset.top += sizeThatFits.height
			} else {
				scrollView.contentInsetAdjustmentBehavior = .automatic
				scrollView.contentInset.top = sizeThatFits.height
				scrollView.contentOffset.y = -(safeAreaInsets.top + sizeThatFits.height)
			}
			scrollView.contentOffset.y = -(safeAreaInsets.top + sizeThatFits.height)
		}

		func prepareForReuse() {
			resignFirstResponder()
			removeFromSuperview()
			headerController.rootView = nil
			loadHTMLString(Html.blank, baseURL: nil)
			scrollView.contentOffset = .zero
			scrollView.contentInset = .zero
		}
	}
}

extension HeaderWebView {
	static let queue = Queue()
	
	/// WebViews take long time to initialize.
	@MainActor
	class Queue {
		private var views = Array<WebView>()

		func prepare() { views.append(WebView()) }

		var webView: WebView {
			if views.isEmpty {
				Logger.ui.error("WebView was not prepared")
				views.append(WebView())
			}
			if views.count == 1 {
				Task {
					try? await Task.sleep(for: .milliseconds(200))
					views.append(WebView())
				}
			}
			return views.removeFirst()
		}

		func release(_ webView: WebView) {
			if views.count < 2 {
				webView.prepareForReuse()
				views.append(webView)
			}
		}
	}
}

extension HeaderWebView.WebView: WKNavigationDelegate {
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
		switch navigationAction.navigationType {
		case .linkActivated:
			if let url = navigationAction.request.url {
				await UIApplication.shared.open(url)
			}
			return .cancel
		default:
			return .allow
		}
	}
}
