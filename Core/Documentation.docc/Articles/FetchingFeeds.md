# Fetching Feeds

Various Optimisations for  

@Metadata {
	@PageImage(purpose: icon, source: "fetchIcon")
	@PageImage(purpose: card, source: "fetchCard")
	@PageColor(green)
}

## Overview

One of the main challenges with creating any decentralised feed is having to fetch new items form each source individually. This is especially true on iOS, which does not support any long running background processes that could pre-fetch contents in the background.

While these days the bandwidth might not be an issue anymore, we still want to reduce the time from opening the app till seeing latest published items as much as possible.

The good news is that with few widely supported optimisations, the experience can be very close to fetching feed items from a centralised platform.

### Parallel Fetch

Since feeds are  fully independent, they can be fetched in parallel.\
``FeedFetcher`` **concurrently** and **consecutively** fetches feeds while providing combine publishers which drive the user interface.

### Conditional Requests

[Conditional Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Conditional_requests) are requests that are executed differently, depending on the value of specific headers:

- [Last Modified](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified)
- [Entity Tag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)

The app handles this using ``ConditionalHeaders`` in the following order:

![Fetch Sequence](fetchSequence)

### Additional Resources

Feeds often reference additional contents which can be handled separately:
- ``Downloader`` A progress publishing object for downloading attachments
- ``MetadataLoader`` Loads ID3 Chapters from a media files
- ``ContentExtractor`` Used to extract full article from URL.\
Useful for feeds that only include their abstract.

