# Proton Pass
This repository contains the source code for the Proton Pass iOS application. 

* [Installation](#installation)
* [Technical Choices](#technical-choices)
    * [UI](#ui)
    * [Dependency manager](#dependency-manager)
    * [Modularization](#modularization)
* [Debug](#debug)
    * [Debug network traffic](#debug-network-traffic)
    * [Debug Sentry activities](#debug-sentry-activities)
* [Tools](#tools)
	* [Dependency injection](#dependency-injection) 
	* [SwiftLint](#swiftlint)
	* [SwiftFormat](#swiftformat)
    * [Sourcery](#sourcery)
* [Changelog](#changelog)
* [Contributing](#contributing)
* [License](#license)

# Installation

The app targets iOS 16 and above. Make sure you have Xcode 15+ installed, check out the repo and open `ProtonPass.xcodeproj` to run the project.

# Technical Choices

## UI

- All the views are written in SwiftUI
- Navigation between views are done using UIKit:
  - `UINavigationController` when running on iPhones
  - `UISplitViewController` when running on iPads

## Dependency manager
CocoaPods & Swift Package Manager

## Modularization
The project is modularized into targets:

- iOS: the main app target
- AutoFill: the AutoFill extension

And local Swift packages:

- Entities: models
- Client: network layer, database operations, repositories...
- Core: coordinator, domain parser, password/passphrase generator, 2FA token generator, useful extensions...
- DesignSystem: UI utilities (custom views, view modifiers, icons, colors...)
- Macro: macro
- UseCases: use cases, interface for Rust library

# Debug

## Debug network traffic
You can print to the console information related to requests (HTTP method, path, headers, & parameters) and responses (HTTP method, status code, url, headers & result) by activating `me.proton.pass.NetworkDebug` environment variable in the scheme configuration. This is disabled by default.

## Debug Sentry activities
You can print to the console Sentry activities by activating `me.proton.pass.SentryDebug` environment variable in the scheme configuration. This is disabled by default.

# Tools

## Dependency injection

The main DI tool used is [Factory](https://github.com/hmlongco/Factory). It is very light but yet very powerful.

## SwiftLint

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

## Pre-commit

Make sure codes are properly linted and formatted before committing.

First install pre-commit
```bash
brew install pre-commit
```

Then create a pre-commit hook
```bash
pre-commit install --hook-type pre-commit
```

After initializing pre-commit for the repo, the next first commit will take a bit of time because pre-commit needs to download and compile necessary tools configured in `.pre-commit-config.yaml` (swiftlint, swiftformat...)

## Sourcery

This is a tool to easily generate mocks for unit testing. 
To install it run the following [Homebrew](https://brew.sh/) command:

```bash
brew install sourcery
```

If you don't have this tool installed please refer to the following link to set it up: [Sourcery](https://github.com/krzysztofzablocki/Sourcery)
The configuration for this tool can be found in the `.sourcery.yml` file.
At the moment the configuration only take into account iOSTests but it could be extended to take into account dependencies in the near future.

**To Generate the mocks** please follow these instructions:
- First you need to annotate your protocol like following:
```swift
// sourcery: AutoMockable
protocol Test {
 // implementation of protocol
}
``` 

- Then run the following CLI command 

```bash
sourcery
```

You should now see the new mocks appear in the `Generated` subfolder of iOSTests target

# Changelog
For a detailed list of changes in each version of the project, please refer to the [CHANGELOG](CHANGELOG.md) file.


# Contributing

We value and welcome contributions from the community to help make this project better.

Please note that while we encourage contributions, we have a specific process in place for handling pull requests (PR) and merging changes. To ensure a smooth workflow, we manage contributions internally on our GitLab repository rather than directly on GitHub.

Here's how you can contribute:

1. **Fork the Repository**: Start by forking this repository to your own GitHub account.

2. **Make Your Changes**: Create a new branch from `main` in your forked repository and make the necessary changes.

3. **Test Your Changes**: Ensure that all tests, swiftlint check and swiftformat check are passing.

To do a swiftlint check, run this command:

```bash
> swiftlint
```

To do a swiftformat check, run this command:

```bash
> swiftformat --lint .
```

To let swiftformat format your code, run this command:

```bash
> swiftformat .
```

4. **Submit a PR**: Once your changes are ready for review, you can submit a PR on this repository. Our team will review your PR, provide feedback, and collaborate with you if any adjustments are needed.

5. **Collaborate**: Feel free to engage in discussions and address any feedback or questions related to your PR. Collaboration is key to delivering high-quality contributions.

6. **Finalization**: Once the PR is approved and meets our criteria, it will be merged into our internal Gitlab repository. Subsequently, your PR will be closed, and your changes will be incorporated when we periodically synchronize updates to GitHub.


# License
The code and data files in this distribution are licensed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See <https://www.gnu.org/licenses/> for a copy of this license.

See [LICENSE](LICENSE) file
