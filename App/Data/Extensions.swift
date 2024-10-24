import Foundation
import AVKit
import SwiftUI
import os.log

extension Logger {
	static let sync = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: "Sync"
	)
	static let store = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: "Store"
	)

	static let ui = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: "UI"
	)
}

extension String {
	static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
	static let filterKey = "filter"
	static let isReadFilteredKey = "isReadFiltered"
	static func iconKey(source: URL) -> String { "icon:" + source.absoluteString }
	static func displayKey(source: URL) -> String { "display:" + source.absoluteString }
	static func conditionalHeadersKey(source: URL) -> String { "conditionalHeaders:" + source.absoluteString }
	
	var url: URL? { URL(string: self) }
	
	/// - Returns: String without the prefix.
	func strippingPrefix(_ prefix: String) -> String {
		hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
	}
	
	/// A simple hashing algorithm. Not randomly seeded.
	var stableHash: Int64 {
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
	static var documents: URL {
		FileManager.default.urls(
			for: .documentDirectory,
			in: .userDomainMask
		).first!
	}
	
	static var attachments: URL {
		URL.documents.appendingPathComponent(
			"attachments"
		)
	}
	
	static func attachments(itemId: Item.ID) -> URL {
		URL.attachments.appendingPathComponent(
			String(format: "%02x", itemId)
		)
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

extension View {
	func boxed(padded: Bool = true) -> some View {
		self
			.scaledToFit()
			.padding(padded ? 6 : 0)
			.frame(width: 32, height: 32)
			.background(Color(.systemGray2).opacity(0.25))
			.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
	}
}

extension DynamicTypeSize {
	var scale: Double {
		switch self {
		case .xSmall:         0.90
		case .small:          0.95
		case .medium:         1.00
		case .large:          1.05
		case .xLarge:         1.10
		case .xxLarge:        1.15
		case .xxxLarge:       1.20
		case .accessibility1: 1.25
		case .accessibility2: 1.30
		case .accessibility3: 1.35
		case .accessibility4: 1.40
		case .accessibility5: 1.45
		@unknown default:     1.50
		}
	}
}

extension CGSize {
	var aspectRatio: Double? {
		width.isNormal && height.isNormal
		? width / height
		: nil
	}
}

extension CMTime {
	init(timeInterval: TimeInterval) {
		self = CMTime(
			seconds: timeInterval,
			preferredTimescale: CMTimeScale(NSEC_PER_SEC)
		)
	}
}
