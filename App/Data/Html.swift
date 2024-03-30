import SwiftUI

/// Html provices a wrapper for ``Item``'s content
///
/// The CSS style is provided from the bundle
/// and the theme colours are system colors, evaluated using the environment
/// This enables toggling between dark and light modes
/// as well as handleing of elevated background color (split-screen, slideover).
struct Html {
	let scale: Double
	let style: String
	let body: String
	let environmentValues: EnvironmentValues
	
	private func themeColor(name: String, color: Color) -> String {
		"--\(name): \(color.resolve(in: environmentValues).description);"
	}
	
	var theme: String {
		[
			themeColor(name: "primary", color: Color.primary),
			themeColor(name: "secondary", color: Color.secondary),
			themeColor(name: "accent", color: Color.accentColor),
			themeColor(name: "background", color: Color(.systemBackground)),
			themeColor(name: "secondaryBackground", color: Color(.secondarySystemBackground)),
			themeColor(name: "accentBackground", color: Color(.tertiarySystemBackground)),
		].joined(separator: "\n")
	}
	
	var string: String {
"""
<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="initial-scale=\(String(format: "%.1f", scale))">
		<style>
			:root {
				\(theme)
			}
			\(style)
		</style>
	</head>
	<body>
		\(body)
	</body>
</html>
"""
	}
}

extension Html: Equatable {
	static func == (lhs: Html, rhs: Html) -> Bool {
		lhs.scale == rhs.scale &&
		lhs.style == rhs.style &&
		lhs.body == rhs.body &&
		rhs.theme == rhs.theme
	}
}
