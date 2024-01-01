# Syncing

How the app syncs between multiple devices

@Metadata {
	@PageImage(purpose: icon, source: "syncIcon")
	@PageImage(purpose: card, source: "syncCard")
	@PageColor(purple)
}

## Overview

Some overview here

### Manual iCloud Setup

1. Add a container to [iCloud Containers](https://developer.apple.com/account/resources/identifiers/list/cloudContainer) formatted `"iCloud." + appBundleId` for example: `iCloud.com.mydomain.feedradar` For testing consider using an existing container since once created **CONTAINERS CAN NOT BE DELETED**
2. Add an identifier `com.mydomain.feedradar` to [App IDs](https://developer.apple.com/account/resources/identifiers/list) with following capabilities:
	- **iCloud** (Include CloudKit support)
	- **Push notifications**
3. After identifier has beed created, select it from the list and add the created container to the **iCloud** capability.
4. Generate a Provisioning Profile, download it and import into Xcode.

Now the project should build.
