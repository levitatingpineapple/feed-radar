import Foundation

struct ConditionalHeaders: Codable {
	private let source: URL
	private let lastModified: String?
	private let etag: String?
	
	/// Fetches ``ConditionalHeaders`` from `UserDefaults`
	/// - Parameter source: source, for which the headers where previously stored
	init?(source: URL) {
		let stored = UserDefaults.standard
			.data(forKey: .conditionalHeadersKey(source: source))
			.flatMap { ConditionalHeaders(rawValue: $0) }
		if let stored { self = stored }
		else { return nil }
	}
	
	/// Extracts ``ConditionalHeaders`` from a `URLResponse`
	/// - Parameter response: Response must be `HTTPURLResponse`
	init?(response: URLResponse, source: URL) {
		if let httpResponse = response as? HTTPURLResponse {
			self.source = source
			lastModified = httpResponse.value(forHTTPHeaderField: "last-modified")
			etag = httpResponse.value(forHTTPHeaderField: "etag")
			if etag == nil && lastModified == nil { return nil } 
		} else {
			return nil
		}
	}
	
	/// Request, decorated with headers for conditionally fetching feeds
	///
	/// Only one of two headers is used with `lastModified`
	/// being the preferred one, 
	/// as various servers require different formatting for the `etag`
	/// like removing the `W/` (weak etag) prefix or surrounding quotes.
	var request: URLRequest {
		var request = URLRequest(
			url: source,
			cachePolicy: .reloadIgnoringLocalCacheData
		)
		if let lastModified {
			request.addValue(lastModified, forHTTPHeaderField: "if-modified-since")
		} else if let etag {
			request.addValue(etag, forHTTPHeaderField: "if-none-match")
		}
		return request
	}
	
	/// Stores ``ConditionalHeaders`` in `UserDefaults`
	func store() {
		UserDefaults.standard.setValue(
			rawValue,
			forKey: .conditionalHeadersKey(source: source)
		)
	}
}

extension ConditionalHeaders: RawRepresentable {
	init?(rawValue: Data) {
		self = try! JSONDecoder().decode(Self.self, from: rawValue)
	}
	
	var rawValue: Data {
		try! JSONEncoder().encode(self)
	}
}

