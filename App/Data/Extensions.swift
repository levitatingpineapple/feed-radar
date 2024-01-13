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
}

extension String {
	static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
	static let style: String = try! String(
		contentsOf: Bundle.main.url(
			forResource: "Style",
			withExtension: "css"
		)!
	)
	static let filterKey = "filter"
	static let contentScaleKey = "contentScale"
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
