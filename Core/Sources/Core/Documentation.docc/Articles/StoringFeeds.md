# Storing Feeds

How feeds are persisted in database

@Metadata {
	@PageImage(purpose: icon, source: "storeIcon")
	@PageImage(purpose: card, source: "storeCard")
	@PageColor(blue)
}

## Overview

- All database write operations are handled by ``Store`` class.
- Each feed is ``Mapped`` into three types ``Feed``, ``Item`` and ``Attachment``\
that conform to ``Storable`` protocol.
- Every subsequent type has one-to-many relationship with the previous one.
- The database serves as *source-of-truth* and drives the UI using `GRDB.ValueObservation`

### Schema

All foreign key references are set to cascade on delete.

![Schema](schema)

## Topics

### Integration

- ``Store``
- ``Storable``
