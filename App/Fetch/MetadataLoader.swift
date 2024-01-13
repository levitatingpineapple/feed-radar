import Foundation
import OutcastID3

enum MetadataLoaderError: Error { case headerNotFound }

final class MetadataLoader: NSObject {
	fileprivate var continuation: CheckedContinuation<Metadata, Error>?
	fileprivate var dataTask: URLSessionDataTask?
	fileprivate var buffer = Data()
	fileprivate var size: UInt32?
	
	/// Loads ID3 metadata, assuming it's located at the beginning of the file
	func metadata(url: URL) async throws -> Metadata {
		dataTask = URLSession(
			configuration: .default,
			delegate: self,
			delegateQueue: nil
		).dataTask(with: url)
		dataTask?.resume()
		return try await withCheckedThrowingContinuation { continuation = $0 }
	}
}

extension MetadataLoader: URLSessionDataDelegate {
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		buffer.append(data)
		if let size {
			if buffer.count > size {
				dataTask.cancel()
				let localUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
				do {
					try buffer.write(to: localUrl)
					continuation?.resume(
						returning: Metadata(
							frames: try OutcastID3
								.MP3File(localUrl: localUrl)
								.readID3Tag().tag.frames
						)
					)
				} catch {
					continuation?.resume(throwing: error)
				}
			}
		} else if buffer.count > 10 {
			// Try extracting metadata size from ID3 Header.
			// Abort download, if header is not found
			if String(bytes: buffer[..<3], encoding: .isoLatin1) == "ID3" &&
				buffer[6] <= 0x7F &&
				buffer[7] <= 0x7F &&
				buffer[8] <= 0x7F &&
				buffer[9] <= 0x7F {
				size =
					(UInt32(buffer[6]) << 21) +
					(UInt32(buffer[7]) << 14) +
					(UInt32(buffer[8]) << 7) +
					(UInt32(buffer[9]) << 0)
			} else {
				dataTask.cancel()
				continuation?.resume(throwing: MetadataLoaderError.headerNotFound)
			}
		}
	}
}
