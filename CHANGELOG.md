## Version 1.8.0
Features:
- Item history: easily review and restore previous versions of an item
- Share Extension: quickly create note or login item from an URL or text

Bug fixes:
- Fixed crash when removing custom fields

Others:
- Bumped to core 16.3.2 -> 18.0.1
- Take into account business plan
- Default password length increased to 20 characters
- Auto-copy 2FA code enabled by default
- Fixed issue with sequential dashes being converted into a single long dash

## Version 1.7.3
Improvements:
- Enabled search for custom text fields
- Optimized item revision creation process by avoiding unnecessary changes

Others:
- Rust library updated to version 0.5.6
- Sentry updated from 8.16.1 to 8.18.0
- Addressed issue preventing bug reports after multiple file changes
- Added persistent item filter option
- Included link to tutorial video and account settings in-app

## Version 1.7.2
Improvements:
- Added email suggestions when sharing
- Improved fav icons availability
- Added support for file and photo attachments when contacting custom support

Bug fixes:
- Addressed sorting/filtering issue on iOS 16
- Resolved an issue that caused passwords containing quotes to be tampered with

Others:
- Bumped core 16.3.2
- Added more logs to sharing flow
- Fixed duplicated item count when displaying search results
- Preserved linked Android packages
- Enabled full concurrency check for the host application
- Removed obsolete feature flags (sharing & pinning)
- Improved event loop
- Alias prefix validation using Rust
- Added "Item ID" & "Vault ID" to "More info" section on item detail pages

## Version 1.7.1
- Fixed "+" button disabled

## Version 1.7.0
Features:
- Added support for bulk actions (move, trash, restore or delete multiple items)

Bug fixes:
- Fixed not being able to share to external users
- Fixed card's number is not masked when its length is less than 12
- Fixed item list glitch on iPad when closing search page
- Fixed UI glitch when opening vault list

Improvements:
- Used YY format when displaying card details
- Showed localized month symbols when picking card's expiration date
- Showed instructions to enable AutoFill on macOS when clicking on the CTA button of the spotlight
- Hid suggestion section in AutoFill extension when an application has no associated URLs
- Disabled create item buttons when entering read-only vaults
- Limited actions on read-only items (disable swipe to delete/restore...)

Others:
- Send UserID to Sentry when capturing errors
- Added support for pinning behind a feature flag

## Version 1.6.1
- Added support for Norwegian language
- Improved passwords display
- Fixed occasional crashes after creating items
- Fixed copying notes for login items with 2FA secrets

## Version 1.6.0
Features:
- Added password vulnerability score
- Improved search precision

Improvements:
- Increased default clipboard expiration from 1 minute to 2 minutes
- Added confirmation when deleting any vaults whether the vault is empty or not
- Fixed alerts not matched theme settings
- Reduced favicons size from 64 to 32
- Showed inline TOTP URI error when creating and editing login items
- Fixed occasional crashes when sending bug reports
- Fixed occasional clipped note

Others:
- Log out when encountering 403 errors
- Prepare for session forking by storing credentials separately (parent session, host application & AutoFill extension)
- New implementation of `AuthDelegate` that no more relies on cached credential
- Moved more use cases to UseCases package

## Version 1.5.7
- Updated last used time of items right after autofilling instead of scheduling background tasks
- Removed sync event loop in AutoFill extension. Only sync when the extension is launched or pulled to refresh.
- Extended sync event loop threshold to 1 minute
- More detailed error messages when showing to users and logging
- Improved Sentry logging:
    - Attached session UID when capturing logout events
    - Customize `environment` value of events. Possible values: `production`, `black`, `scientist` & `custom`

## Version 1.5.6
Others:
- Send logout events to Sentry
- Merged different errors into PassError

## Version 1.5.5
Bug fixes:
- Fixed occasional crashes when autofilling

Others:
- Improved DI process (no more redundant injections)
- Updated copy for several places (banners, password generator, credit card page...)
- Updated sharing upselling page
- Localized alerts when users are forcefully logged out (session expiration or failed local authentication)

## Version 1.5.4
Bug fixes:
- Fixed blank screen when autofilling

Others:
- Point to Core in Gitlab
- Added sharing upselling
- Password generation operations using Rust
- Bump core from 12.2.0 to 14.0.1
- Update lastUseTime in background tasks instead of after autofilling

## Version 1.5.3
- Added ability to share a vault to non-Proton users
- Added 2FA telemetry

## Version 1.5.2
Improvements:
- Improved AutoFill extension's reliability

Others:
- Bump core from 11.0.1 to 12.2.0
- Full sync animation

## Version 1.5.1
Bug fixes:
- Fixed TOTP URI automatically added to login items

Others:
- Share from item detail pages
- No more primary vault behind a feature flag
- Improved Rust library integration
- Improved copy for share flow
- Passwords showed with colors in full screen mode
- Removed non main vault items from autofill list for free users

## Version 1.5.0
Features:
- Added support for Italian, Georgian, Spanish, Spanish (Latin America), Belarusian, Czech, Finnish, Greek, Japanese, Korean, Polish, Portuguese, Portuguese (Brazil), Romanian, Slovak, Swedish, Turkish, Ukrainian & Vietnamese languages

Improvements:
- Improved AutoFill extension’s reliability
- Improved “Default browser” settings

Others:
- Only show secret when editing TOTP URI if the URI has default parameters
- Fixed empty initials when item titles contain only numbers
- Display a toast message after transferring ownership
- Integrated Rust library
- Added signature context when sharing vaults
- Integrated “Dynamic plans” behind a core’s feature flag

## Version 1.4.0
Features:
- Added support for German language
- Display sync progress during login and full sync
- Move items between vaults

Improvements:
- Able to quickly copy the content of notes

Bug Fixes:
- Corrected alphabetical sorting

Others:
- Migrated to SPM
- Mitigated logout issue
- Improved item creation sheet
- Improved swipe-to-delete for items on the search page
- Migrated to String Catalogs
- Swift 5.9 adapation
- Make use of Macro

## Version 1.3.0
Features:
- Added support for the French language
- Introduced credit card scanning functionality
- Enabled document scanning directly into notes

Improvements:
- Implemented monospaced font for improved password readability
- Included AutoFill activation instructions for macOS
- Enabled email editing for logins with associated aliases
- Added support for Firefox Focus browser

Bug fixes:
- Fixed an issue where items were not syncing when there were inactive user keys
- Addressed an issue where the "Generate Password" and "Scan TOTP URI" buttons were not displayed on iOS 15

Others:
- Allowed to set a PIN code for devices without a passcode
- Removed "Default browser" option on macOS
- Enhanced navigation system for better page coordination
- Spinner now persists after accepting invitations for smoother vault reloading
- Eliminated digit validation for PIN codes
- Added the possibility to filter logs (QA builds only)

Vault sharing (WIP):
- Access level updates
- Access revocation
- Shared vault icon

## Version 1.2.2
- Resolved an issue where search highlights were occasionally failing to appear
- Fixed no autofill suggestions after logging in

## Version 1.2.1
### Improvements
- Improved TOTP URI parsing
- Enhanced indexation of login items for AutoFill

### Fixes
- Fixed an issue where non-empty vaults couldn't be deleted
- Fixed a problem with permanently deleting items on iOS 15
- Resolved occasional crashes when authenticating with Face ID/Touch ID or PIN

## Version 1.2.0
### Features
- Able to filter items by type

### Improvements
- Tap to copy hidden custom fields

### Fixes
- Fix unresponsive search bar & vault switcher
- Fix aliases not created when editing login items
- Fix page scrolled to bottom when editing notes
- Fix confirm PIN code button hidden behind the keyboard

## Version 1.1.0
- Allow to use a custom PIN code to lock the app

## Version 1.0.3
- Added new report page
- Improved TabBar accessibility to work with VoiceOver
- Custom fields are now automatically focused when they are being created or edited
- Improved the search page responsiveness

## Version 1.0.2
- Bug fixes and improvements

## Version 1.0.1
- Initial version