import SwiftUI
import Combine

@MainActor
class LoadingManager {
	@Observable
	fileprivate class Model {
		// TODO: Add failed state
		//	enum State {
		//		case ready, loading, failed
		//	}
		var isLoading = false
	}
	
	static let shared: LoadingManager = LoadingManager()
	
	private var models = Dictionary<URL, Model>()
	
	fileprivate func model(source: URL) -> Model {
		if let model = models[source] {
			return model
		} else {
			models[source] = Model()
			return model(source: source)
		}
	}
	
	func start(source: URL) {
		model(source: source).isLoading = true
	}
	
	func stop(source: URL) {
		model(source: source).isLoading = false
	}
}

struct LoadingView: View {
	private let model: LoadingManager.Model
	@State private var rotation: Double = 0
	
	init(source: URL) {
		model = LoadingManager.shared.model(source: source)
	}
	
	var body: some View {
		if model.isLoading {
			Circle()
				.fill(
					AngularGradient(
						gradient: Gradient(colors: [.clear, .accentColor, .clear]),
						center: .center,
						angle: .degrees(rotation)
					)
				)
				.padding(-16)
				.mask(
					RoundedRectangle(cornerRadius: 6, style: .continuous)
						.stroke(lineWidth: 4)
						.frame(width: 28, height: 28)
				)
				.onAppear {
					rotation = 0
					withAnimation(
						.linear(duration: 1)
						.repeatForever(autoreverses: false)
					) { rotation = 360 }
				}
		}
	}
}
