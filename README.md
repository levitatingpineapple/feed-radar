![License](https://img.shields.io/github/license/levitatingpineapple/feed-radar)
![Tests](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed-radar/tests.yml?label=tests)
![Documentation](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed-radar/docc.yml?label=docc)
![Version](https://img.shields.io/github/v/tag/levitatingpineapple/feed-radar?label=version)

<div align=center>
<img src=".readme/banner.png" />
</div>

A modern Feed reader for Apple's platforms with pretty good media support.

![app](.readme/app.webp)

## Why?

With most recommendation algorithms evolving into [engagement maximizers](https://medium.com/understanding-recommenders/whats-right-and-what-s-wrong-with-optimizing-for-engagement-5abaac021851) and spam generation becoming both cheaper and more effective, compiling feeds locally has once again become an enticing solution for ensuring high quality information.

However, the media format is always changing. It's not just blogs and news articles anymore. While feed protocols do have enough flexibility to support rich media formats, the same can't be said about the software which implements them.

The goal of this project it to provide comparable user experience to that of centralized feeds by leveraging already existing features of open standards.

## Features

<img align="left" width="160" src=".readme/media.gif"/>

### Media Attachments

Stream video, audio or view images.\
Save for offline use.\
**QuickLook** and **ShareSheet** integration.\
**ID3** Chapters with chapter art.

<br><br><br><br><br><br><br>

<img align="right" width="160" src=".readme/fetch.gif"/>

### Parallel Fetch

Simultaneously fetching multiple feeds\
combined with [conditional requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Conditional_requests)\
makes for a fast refresh even with many sources added.

<br><br><br><br><br><br><br><br>

<img align="left" width="160" src=".readme/extract.gif"/>

### Article Extraction

Some feeds do not include full content.\
Feed Radar can extract articles\
without relying on any third party services

<br><br><br><br><br><br><br>

## Join Public Beta!

<img align="right" src=".readme/testFlight.png"/>

Scan the QR code or visit [**TestFlight**](https://testflight.apple.com/join/kRcbarg4) to try out the app.\
For questions and/or feedback join [**#feed-radar:n0g.rip**](https://matrix.to/#/#feed-radar:n0g.rip) on matrix.\
Supported platforms:

- `iOS 17.0+`
- `iPadOS 17.0+`
- `macOS 14.0+` [^1]

[^1]: Runs in *Designed for iPad* mode. An ARM MacBook required.

## Documentation

To learn more check out the generated [**Documentation**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar)\
A high level overview is available in following articles:

- [**Fetching Feeds**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/fetchingfeeds)\
How feeds are fetched and mapped
- [**Storing Feeds**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/storingfeeds)\
How feeds are persisted in database
- [**Syncing**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar/syncing)\
How the app syncs between multiple devices

## Dependencies

This project would not be possible without:

- [**FeedKit**](https://github.com/nmdias/FeedKit)\
Handles the complex world of feed decoding
- [**Readablity**](https://github.com/mozilla/readability)\
The library - used in [Firefox Reader View](https://support.mozilla.org/en-US/kb/firefox-reader-view-clutter-free-web-pages) enables article extraction
- [**GRDB**](https://github.com/groue/GRDB.swift)\
A robust SQLite toolkit
- [**OutcastID3**](https://github.com/CrunchyBagel/OutcastID3)\
ID3 Metadata Parser

## Roadmap

⚠️ The project is still in a very early stage. Expect bugs.
Some of the core functionality is yet to be added, such as:

- Finding feed's URL from a website
- Grouping feeds in folders
