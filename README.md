# Proton Pass

## Getting Started
* [Installation](#installation)
* [Technical Choices](#technical-choices)
    * [UI](#ui)
* [Debug](#debug)
    * [Debug network traffic](#debug-network-traffic)
    * [Debug Sentry activities](#debug-sentry-activities)
* [CI/CD](#ci/cd)
    * [Build & Testflight](#make-a-new-build-and-upload-to-testFlight)
* [Tools](#tools)

# Installation

Just check out the repository and open the project. The project is available for iOS >= 15.
You will need to have swiftlint and swiftformat installed to be able to compile.

# Technical Choices

### UI

The project was created using a mix of SwiftUI & UIKit.

# Debug

## Debug network traffic
You can print to the console information related to requests (HTTP method, path, headers, & parameters) and responses (HTTP method, status code, url, headers & result) by activating `me.proton.pass.NetworkDebug` environment variable in the scheme configuration. This is disabled by default.

## Debug Sentry activities
You can print to the console Sentry activities by activating `me.proton.pass.SentryDebug` environment variable in the scheme configuration. This is disabled by default.

# CI/CD

## Make a new build and upload to TestFlight
Create an "App-specific password" via [https://appleid.apple.com](https://appleid.apple.com)
Create Sentry auth token by going to User settings > Auth Tokens > Create new token with default selected scopes

Run this command

```bash
> SENTRY_AUTH_TOKEN=<sentry_auth_token> FASTLANE_USER=<apple_id_email> FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=<app_specific_password> fastlane build_and_upload
```

You will be asked for Apple ID's password on first run.

Select a build variant when prompted:
1. App Store: public builds for App Store
2. Beta: beta builds for TestFlight (In-App Purchase disabled)
3. QA: internal builds for QA

Enter version number in semver format when prompted.

The script will automatically gets the latest build number of the given version, increase by 1 to make the new build number and begin the build & upload processes.

The output IPA & dSYM files are stored in "build" folder

# Tools

## Dependency injection

The main DI tool used is [Factory](https://github.com/hmlongco/Factory). It is very light but yet very powerful.

## Swiftlint

This is the main linter for the project.
To install run the following [Homebrew](https://brew.sh/) command:

```bash
brew install swiftlint
```

If you don't have this tool installed please refer to the following link to set it up: [SwiftLint](https://github.com/realm/SwiftLint)
The configuration for this tool can be found in the `.swiftlint.yml` file.


## SwiftFormat

This is the main code reformatting tool for the project.
To install run the following [Homebrew](https://brew.sh/) command:

```bash
brew install swiftformat
```

If you don't have this tool installed please refer to the following link to set it up: [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
The configuration for this tool can be found in the `.swiftformat` file
