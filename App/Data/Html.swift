import SwiftUI

/// Html provides a wrapper for ``Item``'s content
///
/// The CSS style is provided from the bundle
/// and the theme colours are system colors, evaluated using the environment
/// This enables toggling between dark and light modes
/// as well as handling of elevated background color (split-screen, slide-over).
struct Html: Hashable, CustomStringConvertible {
	let scale: Double
	let theme: Theme
	let body: String

	init?(body: String?, in environmentValues: EnvironmentValues) {
		if let body {
			self.scale = environmentValues.dynamicTypeSize.scale
			self.theme = Theme(in: environmentValues)
			self.body = body
		} else { return nil }
	}

	static let style: String = try! String(
		contentsOf: Bundle.main.url(
			forResource: "Style",
			withExtension: "css"
		)!
	)
	
	var description: String {
"""
<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="initial-scale=\(String(format: "%.2f", scale))">
		<style>
			:root {
				\(theme)
			}
			\(Self.style)
		</style>
	</head>
	<body>
		\(body)
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

extension Html {
	struct Theme: Hashable, CustomStringConvertible {
		private let primary: Color.Resolved
		private let secondary: Color.Resolved
		private let accent: Color.Resolved
		private let background: Color.Resolved
		private let secondaryBackground: Color.Resolved
		private let accentBackground: Color.Resolved

		init(in environmentValues: EnvironmentValues) {
			func resolved(_ uiColor: UIColor) -> Color.Resolved {
				Color(uiColor).resolve(in: environmentValues)
			}
			primary = resolved(.label)
			secondary = resolved(.secondaryLabel)
			accent = resolved(.tintColor)
			background = resolved(.systemBackground)
			secondaryBackground = resolved(.secondarySystemBackground)
			accentBackground = resolved(.tertiarySystemBackground)
		}

		var description: String {
"""
--primary: \(primary.description);
--secondary: \(secondary.description);
--accent: \(accent.description);
--background: \(background.description);
--secondayBackground: \(secondaryBackground.description);
--accentBackground: \(accentBackground.description);
"""
		}
	}
}
