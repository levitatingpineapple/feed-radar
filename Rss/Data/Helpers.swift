import Foundation
import os.log
import UniformTypeIdentifiers

extension URL {
	var favicon: URL? {
		host(percentEncoded: true).flatMap {
			var components = URLComponents()
			components.scheme = "https"
			components.host = "www.google.com"
			components.path = "/s2/favicons"
			components.queryItems = [
				URLQueryItem(name: "domain", value: $0),
				URLQueryItem(name: "sz", value: "64")
			]
			return components.url
		}
	}
	
	static var documents: URL {
		FileManager.default.urls(
			for: .documentDirectory,
			in: .userDomainMask
		).first!
	}
}

extension String {
	static let cloudKitContainerIdentifier = "iCloud.levitatingpineapple.todo"
	static let cloudKitStateSerializationKey = "newKey"
	static let loggingSubsystem: String = "com.levitatingPineapple.rss"
	
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

extension Int {
	static func hashValues(_ values: (any Hashable)...) -> Int {
		var hasher = Hasher()
		values.forEach { hasher.combine($0) }
		return hasher.finalize()
	}
}

extension Logger {
	static let sync = Logger(subsystem: .loggingSubsystem, category: "☁️")
	static let store = Logger(subsystem: .loggingSubsystem, category: "💽")
}
