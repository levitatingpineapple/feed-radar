import Testing
import Foundation
@testable import Core

@Suite
struct ConditionalGet {
	@Test
	func etag() {
		let source = URL(string: "https://etag.com")!
		ConditionalHeaders(
			response: HTTPURLResponse(
				url: URL(string: "https://response.com")!,
				statusCode: 200,
				httpVersion: nil,
				headerFields: ["etag": "W/\"3kkoIUL-kj3827\""]
			)!,
			source: source
		)?.store()
		let request = ConditionalHeaders(source: source)?.request
		#expect(
			request?.value(forHTTPHeaderField: "if-modified-since") == nil,
			"`if-modified-since` request header should match `last-modified` response header"
		)
		#expect(
			request?.value(forHTTPHeaderField: "if-none-match") == "W/\"3kkoIUL-kj3827\"",
			"`if-none-match` request header should match `etag` response header, including escaped quotes"
		)
		UserDefaults.standard.removePersistentDomain(forName: source.absoluteString)
	}

	@Test
	func lastModified() {
		let source = URL(string: "https://source.com")!
		ConditionalHeaders(
			response: HTTPURLResponse(
				url: URL(string: "https://response.com")!,
				statusCode: 200,
				httpVersion: nil,
				headerFields: [
					"last-modified": "1 Jan 2023 11:01:58 GMT",
					"etag": "W/\"3kkoIUL-kj3827\""
				]
			)!,
			source: source
		)?.store()
		let request = ConditionalHeaders(source: source)?.request
		#expect(
			request?.value(forHTTPHeaderField: "if-modified-since") == "1 Jan 2023 11:01:58 GMT",
			"`if-modified-since` request header should match `last-modified` response header"
		)
		#expect(
			request?.value(forHTTPHeaderField: "if-none-match") == nil,
			"If `last-modified` is present, etag sould not be used."
		)
		UserDefaults.standard.removePersistentDomain(forName: source.absoluteString)
	}
	
	@Test
	func failingTest() {
		#expect(2 != 2)
	}
}
