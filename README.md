![License](https://img.shields.io/github/license/levitatingpineapple/feed)
![Tests](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/tests.yml?label=tests)
![Documentation](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/docc.yml?label=docc)
![Version](https://img.shields.io/github/v/tag/levitatingpineapple/feed?label=version)

<div align="center">
	<img src="./App/Support/Assets.xcassets/AppIcon.appiconset/macOS-256.png" />
</div>

# Feed Radar

A modern Feed reader for Apple's platforms with good media support.

![app](.readme/app.webp)

## Features

| Preview                                                                          | Description                                                                                                           |
|:-------------------------------------------------------------------------------- |:--------------------------------------------------------------------------------------------------------------------- |
| **Multiple&nbsp;Attachments**<br><br><img width="160" src=".readme/media.gif" /> | Media previews for Images, Video and Audio with the option to download files for offline use.                                                                                                                      |
| **Parallel Fetch**<br><br><img width="160" src=".readme/fetch.gif" />            | Simultaneously fetching multiple feeds makes for a fast refresh even with many sources.                               |
| **Article Extraction**<br><br><img width="160" src=".readme/extract.gif" />      | Some feeds does not include full content. Feed Radar can extract articles without relying on any third party services |

## Join Public Beta!

<img align="right" src=".readme/testFlight.png"/>

Scan the QR code or visit [**TestFlight**](https://testflight.apple.com/join/kRcbarg4) to try out the app.\
Supported platforms:
- `iOS 17.0+`
- `iPadOS 17.0+`
- `macOS 14.0+` [^1]

[^1]: Runs in (Designed for iPad) mode - requires an ARM Macbook

## Documentation

To learn more check out the generated [**Documentation**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar)\
A high level overview is available in following articles:

- [**Fetching Feeds**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/fetchingfeeds)\
How feeds are fetched and mapped
- [**Storing Feeds**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/storingfeeds)\
How feeds are persisted in database
- [**Syncing**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/syncing)\
How the app syncs between multiple devices