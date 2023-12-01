import Foundation
import SwiftUI
import UniformTypeIdentifiers
import os.log

extension Logger {
	static let sync = Logger(subsystem: .loggingSubsystem, category: "☁️ Sync")
	static let store = Logger(subsystem: .loggingSubsystem, category: "💽 Store")
}

extension String {
	static let cloudKitContainerIdentifier = "iCloud.levitatingpineapple.todo"
	static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
	static let loggingSubsystem: String = "com.levitatingPineapple.rss"
	static let style: String = try! String(
		contentsOf: Bundle.main.url(
			forResource: "style",
			withExtension: "css"
		)!
	)
	
	static let contentScaleKey = "contentScale"
	static let isReadFilteredKey = "isReadFiltered"
	static func displayKey(source: URL) -> String { "display:" + source.absoluteString }
	static func iconKey(source: URL) -> String { "icon:" + source.absoluteString }
	
	var url: URL? { URL(string: self) }
	var type: UTType? { UTType(mimeType: self) }
	func indented(_ indent: Int) -> String {
		replacingOccurrences(
			of: "\n",
			with: Array<String>(
				repeating: "\t", 
				count: indent
			).joined() + "\n"
		)
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

extension Array where Element == URL {
	mutating func process(workers: UInt, partialCompletion: (Data, URL) async -> Void) async {
		await withTaskGroup(of: Result<(Data, URL), any Error>.self) { taskGroup in
			func addWorker() {
				if let last = popLast() {
					DispatchQueue.main.async { Store.shared.fetching.insert(last) }
					taskGroup.addTask {
						do {
							let success = (try await URLSession.shared.data(from: last).0, last)
							DispatchQueue.main.async { Store.shared.fetching.remove(last) }
							return Result.success(success)
						} catch {
							return Result.failure(error)
						}
					}
				}
			}
			(0..<workers).forEach { _ in addWorker() }
			while let next = await taskGroup.next() {
				switch next {
				case let .success((data, source)):
					await partialCompletion(data, source)
				case let .failure(error): Logger.store.debug("Failed to Download \(error)")
				}
				addWorker()
			}
		}
	}
}
