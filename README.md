![License](https://img.shields.io/github/license/levitatingpineapple/feed)
![Tests](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/tests.yml?label=tests)
![Documentation](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/docc.yml?label=docc)
![Version](https://img.shields.io/github/v/tag/levitatingpineapple/feed?label=version)

<div align="center">
	<img src="./App/Support/Assets.xcassets/AppIcon.appiconset/macOS-256.png" />
</div>

# Feed Radar

A modern Feed reader for Apple's platforms with good media support.

## TestFlight

Public beta available [here](https://testflight.apple.com/join/kRcbarg4)
<div align="center">
	<img style="border-radius: 12px" src="./App/Documentation.docc/Resources/testFlight.png"/>
</div>	
## Installation

### Clone

Clone the repository and initalise it's submodules:

```bash
git clone git@github.com:levitatingpineapple/feed-radar.git
git submodule init
git submodule update
```

### Manual iCloud Setup

1. Add a container to [iCloud Containers](https://developer.apple.com/account/resources/identifiers/list/cloudContainer) formatted `"iCloud." + appBundleId` for example: `iCloud.com.mydomain.feedradar` For testing consider using an existing container since once created **CONTAINERS CAN NOT BE DELETED**
2. Add an identifier `com.mydomain.feedradar` to [App IDs](https://developer.apple.com/account/resources/identifiers/list) with following capabilities:
	- **iCloud** (Include CloudKit support)
	- **Push notifications**
3. After identifier has beed created, select it from the list and add the created container to the **iCloud** capability.
4. Generate a Provisioning Profile, download it and import into Xcode.

Now the project should build.

## Documentation

To learn more check out the [**compiled documentation**](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar)\
A high level overview is available in following articles:

- [Fetch Feeds]()
- [Store Feeds]()
- [Sync]()