import Foundation
import UIKit
import UniformTypeIdentifiers
import os.log

extension Logger {
	static let sync = Logger(subsystem: .loggingSubsystem, category: "☁️")
	static let store = Logger(subsystem: .loggingSubsystem, category: "💽")
}

extension String {
	static let cloudKitContainerIdentifier = "iCloud.levitatingpineapple.todo"
	static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
	static let loggingSubsystem: String = "com.levitatingPineapple.rss"
	
	// App Storage
	static let contentScaleKey = "contentScale"
	static func displayKey(source: URL) -> String { "display:" + source.absoluteString }
	static func iconKey(source: URL) -> String { "icon:" + source.absoluteString }
	
	
	var url: URL? { URL(string: self) }
	var type: UTType? { UTType(mimeType: self) }
	func wrappedInHtml(scale: Double) -> String { """
<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="initial-scale=\(String(format: "%.1f", scale))">
		<style>
			\(try! String(contentsOf: Bundle.main.url(forResource: "style", withExtension: "css")!))
		</style>
	</head>
	<body>
		\(self)
	</body>
</html>
"""
	}
}

extension URL {
	static var documents: URL {
		FileManager.default.urls(
			for: .documentDirectory,
			in: .userDomainMask
		).first!
	}
	
	var favicon: URL? {
		host(percentEncoded: true).flatMap {
			var components = URLComponents()
			components.scheme = "https"
			components.host = "www.google.com"
			components.path = "/s2/favicons"
			components.queryItems = [
				URLQueryItem(name: "domain", value: $0),
				URLQueryItem(name: "sz", value: "128")
			]
			return components.url
		}
	}
	
	var base: URL? {
		if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
			components.path = String()
			return components.url
		} else {
			return nil
		}
	}
}


extension Int {
	static func hashValues(_ values: (any Hashable)...) -> Int {
		var hasher = Hasher()
		values.forEach { hasher.combine($0) }
		return hasher.finalize()
	}
}

extension UIImage {
	func cropScaled(max: Double) -> UIImage {
		let scaled = min(max, size.width, size.height)
		return UIGraphicsImageRenderer(size: CGSize(width: scaled, height: scaled)).image { _ in
			if size.width > size.height {
				let clippedWidth = scaled * size.width / size.height
				draw(
					in: CGRect(
						x: (scaled - clippedWidth) / 2,
						y: .zero,
						width: clippedWidth,
						height: scaled
					)
				)
			} else {
				let clippedHeight = scaled * size.height / size.width
				draw(
					in: CGRect(
						x: .zero,
						y: (scaled - clippedHeight) / 2,
						width: scaled,
						height: clippedHeight
					)
				)
			}
		}
	}
}

extension Data {
	var scaledPng: Data? {
		UIImage(data: self)?
			.cropScaled(max: 128)
			.pngData()
	}
}
