import Foundation

extension String {
	var url: URL? { URL(string: self) }
}

extension URL {
	var favicon: URL? {
		host(percentEncoded: true)
			.flatMap {
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
}
