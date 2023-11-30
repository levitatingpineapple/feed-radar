import Foundation

extension Feed {
	struct Display {
		enum Mode: UInt8 { case item, link }
		var mode: Mode
		var opensReader: Bool
		var isInverted: Bool
	}
}

extension Feed.Display: RawRepresentable {
	init?(rawValue: Int) {
		mode = 			(UInt8(rawValue) & (1 << 0)) != .zero ? .link : .item
		opensReader = 	(UInt8(rawValue) & (1 << 1)) != .zero
		isInverted = 	(UInt8(rawValue) & (1 << 2)) != .zero
	}
	
	var rawValue: Int {
		Int(
			(UInt8(truncating: (mode == .link) as NSNumber) << 0) |
			(UInt8(truncating: opensReader as NSNumber) << 1) |
			(UInt8(truncating: isInverted as NSNumber) << 2)
		)
	}
}
