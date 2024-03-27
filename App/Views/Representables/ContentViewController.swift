import UIKit
import SwiftUI
import WebKit

struct ContentViewController: UIViewControllerRepresentable {
	let display: ItemDetailView.Display
	let item: Item
	@Environment(\.self) var environmentValues
	@Binding var scale: Double
	
	func makeUIViewController(context: Context) -> ViewController {
		ViewController()
	}
	
	func updateUIViewController(
		_ viewController: ViewController,
		context: Context
	) {
		viewController.attachmentsController.rootView = AttachmentsView(
			item: item,
			scale: scale
		) { [weak viewController] in
			viewController?.attachmentsController.view.invalidateIntrinsicContentSize()
		}
		viewController.webView.loadHTMLString(
			Html(
				scale: scale,
				style: .style,
				body: body ?? String(),
				environmentValues: environmentValues
			).string,
			baseURL: item.url
		)
	}
	
	private var body: String? {
		switch display {
		case .content:
			item.content
		case .extractedContent:
			item.extracted
		case .webView:
			nil
		}
	}
}

extension ContentViewController {
	class ViewController: UIViewController {
		let attachmentsController = UIHostingController<AttachmentsView?>(rootView: .none)
		private var observation: NSKeyValueObservation?
		
		var webView: WKWebView { view as! WKWebView }
		
		deinit {
			attachmentsController.rootView = .none
			attachmentsController.removeFromParent()
			observation = nil
		}
		
		required init?(coder: NSCoder) { fatalError() }
		
		init() {
			super.init(nibName: nil, bundle: nil)
			super.viewDidLoad()
			view = WKWebView()
			webView.navigationDelegate = self
			webView.isOpaque = false
			webView.backgroundColor = .clear
			view = webView
			addChild(attachmentsController)
			attachmentsController.view.backgroundColor = .clear
			webView.scrollView.addSubview(attachmentsController.view)
			attachmentsController.view.translatesAutoresizingMaskIntoConstraints = false
			attachmentsController.view.bottomAnchor.constraint(equalTo: webView.scrollView.topAnchor).isActive = true
			attachmentsController.view.widthAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
			attachmentsController.view.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
			
			// Updates content inset based height of the attachments, as they load.
			observation = attachmentsController.view.observe(\.bounds, options: [.new]) { [weak self] (view, change) in
				if let webView = self?.webView,
				   let webContentHeight = change.newValue?.height,
				   webContentHeight != webView.scrollView.contentInset.top {
					webView.scrollView.contentInset.top = webContentHeight
					webView.scrollView.setContentOffset(
						CGPoint(x: .zero, y: -(webView.safeAreaInsets.top + webContentHeight)),
						animated: false
					)
				}
			}
		}
	}
	
}

extension ContentViewController.ViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		switch navigationAction.navigationType {
		case .linkActivated:
			decisionHandler(.cancel)
			if let url = navigationAction.request.url {
				UIApplication.shared.open(url)
			}
		default:
			decisionHandler(.allow)
		}
	}
}
