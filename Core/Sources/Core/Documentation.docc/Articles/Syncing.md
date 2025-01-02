# Syncing

How the app syncs between multiple devices

@Metadata {
	@PageImage(purpose: icon, source: "syncIcon")
	@PageImage(purpose: card, source: "syncCard")
	@PageColor(purple)
}

## Overview

The syncing between devices is handled by ``Sync`` using CloudKit's [`CKSyncEngine`](https://developer.apple.com/documentation/cloudkit/cksyncengine).\
While this first-party solution allows for sync without running a dedicated server there are few limitations:

- Due to iCloud [bandwidth limitations](https://github.com/Ranchero-Software/NetNewsWire/wiki/iCloud-Sync-and-NetNewsWire:-Where-We’re-Stuck) only user interactions such as `.isRead` and `.isStarred` are synced for each ``Item``
- Since [`CKRecord.Reference`](https://developer.apple.com/documentation/cloudkit/ckrecord/reference) only supports up to **750** references per record,\
it can't be used to fully map ``Feed`` - ``Item`` relationships. The solution for this is to store each feed in its own [`CKRecordZone`](https://developer.apple.com/documentation/cloudkit/ckrecordzone) mapping source of the ``Feed`` to the [`CKRecordZone.ID`](https://developer.apple.com/documentation/cloudkit/ckrecordzone/id). This way, when the feed gets deleted all of its records are removed too.



## Manual Container Setup

> **Once created, CloudKit containers can never be deleted!**

1. Add a container to [iCloud Containers](https://developer.apple.com/account/resources/identifiers/list/cloudContainer) formatted `"iCloud." + appBundleId` for example: `iCloud.com.mydomain.feedradar`
2. Add an identifier `com.mydomain.feedradar` to [App IDs](https://developer.apple.com/account/resources/identifiers/list) with following capabilities:
	- **iCloud** (Include CloudKit support)
	- **Push notifications**
3. After identifier has been created, select it from the list and add the created container to the **iCloud** capability.
4. Generate a Provisioning Profile, download it and import into Xcode.

Now the project should build.

## Topics

### Integration

- ``Sync``

