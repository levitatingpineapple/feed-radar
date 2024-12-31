import SwiftUI
import Combine

@Observable
@MainActor
class LoadingModel {
	static let shared: LoadingModel = LoadingModel()
	var loading = Set<URL>()
}

struct LoadingView: View {
	let source: URL
	let testModel = LoadingModel.shared
	
	var body: some View {
		if testModel.loading.contains(source) {
			GradientSpinner()
		}
	}
}

private struct GradientSpinner: View {
	@State private var rotation: Double = 0

	var body: some View {
		Circle()
			.fill(
				AngularGradient(
					gradient: Gradient(colors: [.clear, .accentColor, .clear]),
					center: .center,
					angle: .degrees(rotation)
				)
			)
			.padding(-16)
			.onAppear {
				withAnimation(
					.linear(duration: 1)
					.repeatForever(autoreverses: false)
				) { rotation = 360 }
			}
			.mask(
				RoundedRectangle(cornerRadius: 6, style: .continuous)
					.stroke(lineWidth: 4)
					.frame(width: 28, height: 28)
			)
	}
}

