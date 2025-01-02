import Foundation
import OutcastID3

public enum MetadataLoaderError: Error { case headerNotFound }

/// Loads metadata without downloading the entire file
public func loadMetadata(from url: URL) async -> Result<Metadata, Error> {
	let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
	var buffer = Data(capacity: 1024)
	var metadataSize: UInt32?
	let dataTask = URLSession(
		configuration: .default,
		delegate: DataDelegate(continuation: continuation),
		delegateQueue: nil
	).dataTask(with: url)
	dataTask.resume()
	for await data in stream {
		buffer.append(data)
		if let metadataSize {
			if buffer.count > metadataSize {
				dataTask.cancel()
				let localUrl = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
				do {
					try buffer.write(to: localUrl)
					return .success(
						Metadata(frames: try OutcastID3
							.MP3File(localUrl: localUrl)
							.readID3Tag().tag.frames
						)
					)
				} catch {
					return .failure(error)
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
				metadataSize =
					(UInt32(buffer[6]) << 21) +
					(UInt32(buffer[7]) << 14) +
					(UInt32(buffer[8]) << 7) +
					(UInt32(buffer[9]) << 0)
			} else {
				dataTask.cancel()
				return .failure(MetadataLoaderError.headerNotFound)
			}
		}
	}
	return .failure(MetadataLoaderError.headerNotFound)
}

private final class DataDelegate: NSObject, URLSessionDataDelegate {
	let continuation: AsyncStream<Data>.Continuation
	
	init(continuation:AsyncStream<Data>.Continuation) {
		self.continuation = continuation
	}
	
	func urlSession(
		_ session: URLSession,
		dataTask: URLSessionDataTask,
		didReceive data: Data
	) {
		continuation.yield(data)
	}
}
