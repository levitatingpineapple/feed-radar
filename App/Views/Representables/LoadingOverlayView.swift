import SwiftUI
import Combine

/// Displays loading spinner
struct LoadingOverlayView: UIViewRepresentable {
	@Environment(\.store) var store
	
	let source: URL
	
	func makeUIView(context: Context) -> some UIView {
		LoadingOverlayView(source: source, fetcher: store.fetcher)
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) { }
	
	class LoadingOverlayView: UIVisualEffectView {
		private var isLoading: CurrentValueSubject<Bool, Never>?
		private var bag = Set<AnyCancellable>()
		private let spinner = UIActivityIndicatorView(
			frame: CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
		)
		
		init(source: URL, fetcher: FeedFetcher) {
			super.init(effect: nil)
			self.alpha = 0
			self.contentView.addSubview(spinner)
			Task { @MainActor in
				isLoading = await fetcher.isLoading(source: source)
				isLoading?.sink { [weak self] isLoading in
					UIView.animate(withDuration: 0.2) { self?.display(isLoading: isLoading) }
				}
				.store(in: &bag)
			}
		}
		
		private func display(isLoading: Bool) {
			Task { @MainActor in
				if isLoading {
					spinner.startAnimating()
					alpha = 0.8
					effect = UIBlurEffect(style: .prominent)
				} else {
					spinner.stopAnimating()
					alpha = 0
					effect = nil
				}
			}
		}
		
		required init(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

