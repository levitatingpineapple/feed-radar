import SwiftUI

struct CircularProgressView: View {
	let width: Double
	let progress: Double
	
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: width / 2)
				.fill(Color.accentColor)
				.frame(width: width * 4, height: width * 4)
			Circle()
				.stroke(
					Color.primary.opacity(0.2),
					lineWidth: width
				)
			Circle()
				.trim(from: 0, to: progress)
				.stroke(
					Color.accentColor,
					style: StrokeStyle(
						lineWidth: width,
						lineCap: .round
					)
				)
				.rotationEffect(.degrees(-90))
		}.padding(width / 2)
	}
}
