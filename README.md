# Proton Pass
This repository contains the source code for the Proton Pass iOS application. 

* [Installation](#installation)
* [Technical Choices](#technical-choices)
    * [UI](#ui)
    * [Dependency manager] (#dependency-manager)
    * [Modularization] (#dodularization)
* [Debug](#debug)
    * [Debug network traffic](#debug-network-traffic)
    * [Debug Sentry activities](#debug-sentry-activities)
* [Tools](#tools)
	* [Dependency injection] (#dependency-injection) 
	* [SwiftLint] (#swiftlint)
	* [SwiftFormat] (#swiftformat)

# Installation

The app targets iOS 15 and above. Make sure you have Xcode 14+ installed, check out the repo and open `ProtonPass.xcworkspace` to run the project.

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
- Client: network layer, database operation & models
- Core: coordinator, domain parser, password/passphrase generator, 2FA token generator, useful extensions...
- UIComponents: UI utilities (custom views, view modifiers, icons, colors...)

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

# License
The code and data files in this distribution are licensed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See <https://www.gnu.org/licenses/> for a copy of this license.

See [LICENSE](LICENSE) file