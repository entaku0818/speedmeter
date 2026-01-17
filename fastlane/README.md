fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata and screenshots to App Store Connect and submit for review

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload screenshots only

### ios upload_metadata_only

```sh
[bundle exec] fastlane ios upload_metadata_only
```

Upload metadata only without submitting for review

### ios release

```sh
[bundle exec] fastlane ios release
```

Build, archive and upload to App Store Connect

### ios full_release

```sh
[bundle exec] fastlane ios full_release
```

Full release: build, upload, metadata, and submit for review

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download metadata from App Store Connect

### ios download_screenshots

```sh
[bundle exec] fastlane ios download_screenshots
```

Download screenshots from App Store Connect

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
