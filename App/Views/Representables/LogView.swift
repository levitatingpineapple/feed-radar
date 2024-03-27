import SwiftUI
import UIKit

struct LogView: UIViewRepresentable {
	static var count: Int = .zero
	
	func makeUIView(context: Context) -> UILabel {
		Self.count += 1
		let label = UILabel()
		label.backgroundColor = .magenta
		return label
	}

	func updateUIView(_ view: UILabel, context: Context) {
		view.text = "\(Self.count)"
	}
}
