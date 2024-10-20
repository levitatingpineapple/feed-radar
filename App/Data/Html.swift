import SwiftUI

/// Html provides a wrapper for ``Item``'s content
///
/// The CSS style is provided from the bundle
/// and the theme colours are system colors, evaluated using the environment
/// This enables toggling between dark and light modes
/// as well as handling of elevated background color (split-screen, slide-over).
struct Html {
	let style: String
	let body: String?
	let environmentValues: EnvironmentValues
	
	private func themeColor(name: String, color: Color) -> String {
		"--\(name): \(color.resolve(in: environmentValues).description);"
	}
	
	private var theme: String {
		[
			themeColor(name: "primary", color: Color.primary),
			themeColor(name: "secondary", color: Color.secondary),
			themeColor(name: "accent", color: Color.accentColor),
			themeColor(name: "background", color: Color(.systemBackground)),
			themeColor(name: "secondaryBackground", color: Color(.secondarySystemBackground)),
			themeColor(name: "accentBackground", color: Color(.tertiarySystemBackground)),
		].joined(separator: "\n")
	}
	
	private var scale: String {
		String(format: "%.2f", environmentValues.dynamicTypeSize.scale)
	}
	
	var string: String {
"""
<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="initial-scale=\(scale)">
		<style>
			:root {
				\(theme)
			}
			\(style)
		</style>
	</head>
	<body>
		\(body ?? String())
	</body>
</html>
"""
	}

	static let blank =
"""
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8">
	</head>
	<body>
		<div style="width: 200px; height: 200px;"></div>
	</body>
</html>
"""
}

extension Html: Equatable {
	static func == (lhs: Html, rhs: Html) -> Bool {
		lhs.environmentValues.dynamicTypeSize == rhs.environmentValues.dynamicTypeSize &&
		lhs.style == rhs.style &&
		lhs.body == rhs.body &&
		rhs.theme == rhs.theme
	}
}
