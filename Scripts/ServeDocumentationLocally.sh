#!/bin/zsh

# The documentation rendering can have inconsistencies between Xcode and the web.
# Serve locally to verify everything looks good in the browser.

./Scripts/RenderDocumentationDiagrams.sh

rm -rf .docs
rm -rf .derivedData

xcodebuild docbuild \
	-scheme FeedRadar \
	-destination 'generic/platform=iOS Simulator' \
	-derivedDataPath .derivedData
	
xcrun docc process-archive transform-for-static-hosting \
	.derivedData/Build/Products/Debug-iphonesimulator/FeedRadar.doccarchive \
	--output-path .docs
	
python3 -m http.server -d .docs & open http://localhost:8000/documentation/feedradar

echo "Press any key to exit..." && read -k1 -s -r