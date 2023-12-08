import SwiftUI
import Combine

struct LoadingOverlayView: UIViewRepresentable {
	let isLoading: CurrentValueSubject<Bool, Never>
	
	func makeUIView(context: Context) -> some UIView {
		LoadingOverlayView(
			isLoading: isLoading
		)
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) { }
	
	class LoadingOverlayView: UIVisualEffectView {
		private var bag = Set<AnyCancellable>()
		private let spinner = UIActivityIndicatorView(
			frame: CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
		)
		
		init(isLoading: CurrentValueSubject<Bool, Never>) {
			super.init(effect: nil)
			self.alpha = 0
			
			self.contentView.addSubview(spinner)
			isLoading
				.sink { [weak self] isLoading in
					UIView.animate(withDuration: 0.2) { self?.display(isLoading: isLoading) }
				}
				.store(in: &bag)
		}
		
		private func display(isLoading: Bool) {
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
		
		required init(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

