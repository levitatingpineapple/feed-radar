import Foundation
import AVKit
import os.log

extension Logger {
	private static func logger(category: String) -> Logger {
		Logger(
			subsystem: Bundle.main.bundleIdentifier ?? "test-target",
			category: category
		)
	}

	static let sync = logger(category: "Sync")
	static let store = logger(category: "Store")
	public static let ui = logger(category: "ui")
}

extension String {
	public static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
	public static let filterKey = "filter"
	public static let isReadFilteredKey = "isReadFiltered"
	public static func iconKey(source: URL) -> String { "icon:" + source.absoluteString }
	public static func displayKey(source: URL) -> String { "display:" + source.absoluteString }
	public static func conditionalHeadersKey(source: URL) -> String { "conditionalHeaders:" + source.absoluteString }
	
	public var url: URL? { URL(string: self) }
	
	/// - Returns: String without the prefix.
	public func strippingPrefix(_ prefix: String) -> String {
		hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
	}
	
	/// A simple hashing algorithm. Not randomly seeded.
	public var stableHash: Int64 {
		Int64(
			bitPattern: self
				.data(using: .utf8)!
				.reduce(into: UInt64(5381)) { result, byte in
					result = 0x7F * (result & 0x00FFFFFFFFFFFFFF) + UInt64(byte)
				}
		)
	}
}

extension URL {
	public static var documents: URL {
		FileManager.default.urls(
			for: .documentDirectory,
			in: .userDomainMask
		).first!
	}
	
	public static var attachments: URL {
		URL.documents.appendingPathComponent(
			"attachments"
		)
	}
	
	public static func attachments(itemId: Item.ID) -> URL {
		URL.attachments.appendingPathComponent(
			String(format: "%02x", itemId)
		)
	}
	
	public var favicon: URL? {
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
	
	public var base: URL? {
		if var components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
			components.path = String()
			return components.url
		} else {
			return nil
		}
	}
}

#if canImport(UIKit)
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
#endif

extension Data {
#if canImport(UIKit)
	var scaledPng: Data? {
		UIImage(data: self)?
			.cropScaled(max: 128)
			.pngData()
	}
#else
	// Image resizing not implemented for test target
	var scaledPng: Data? { nil }
#endif
}
