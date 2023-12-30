![License](https://img.shields.io/github/license/levitatingpineapple/feed)
![Tests](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/tests.yml?label=tests)
![Documentation](https://img.shields.io/github/actions/workflow/status/levitatingpineapple/feed/docc.yml?label=docc)
![Version](https://img.shields.io/github/v/tag/levitatingpineapple/feed?label=version)

<div align="center">
	<img src="./App/Support/Assets.xcassets/AppIcon.appiconset/macOS-256.png" />
</div>

# Feed Radar

A modern Feed reader for Apple's platforms with good media support.

Check out the [documentation](https://levitatingpineapple.github.io/feed-radar/documentation/feedradar) to learn more.

# Installation

### Clone

Clone repository and initalise it's submodules:

```bash
git clone git@github.com:levitatingpineapple/feed-radar.git
git submodule init
git submodule update
```

### Setup Signing

1. Add a container to [iCloud Containers](https://developer.apple.com/account/resources/identifiers/list/cloudContainer). Example: `iCloud.com.mydomain.feedradar` This will be used for syncing. For testing consider using an existing container since **CONTAINERS CAN NOT BE DELETED**
2. Add an identifier Example: `com.mydomain.feedradar` to [App IDs](https://developer.apple.com/account/resources/identifiers/list) with following capabilities:
	- **iCloud** (Include CloudKit support)
	- **Push notifications**
3. After identifier has beed created, select it from the list and add the created container to the **iCloud** capability.
4. Generate a Provisioning Profile, download it and import into Xcode.

Now the project should build.