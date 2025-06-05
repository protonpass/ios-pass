# Version 1.17.2
New layout for note item

Improvements:
- Display the actual Vault ID (instead of the Share ID) in the item's details view
- Show a custom empty state when no passkeys match during autofill
- Support custom fields across all item types
- Enable sharing of logs when errors occur during full sync

Others:
- Core libraries upgraded from 32.1.2 to 32.3.1

# Version 1.17.1
You can now sign in to another device using a QR code. Go to the Profile tab > "Sign in to another device".

Improvements:
- Fixed issue preventing creation/editing of custom fields and sections on iOS 16
- Fixed file preview failure for filenames with special characters
- Alphabetical sorting now ignores diacritics

Others:
- Core libraries upgraded from 30.0.4 to 32.1.2
- Hide copy options for email/username/password if the field is empty
- Added telemetry for onboarding flow
- Show message when vaults can't be decrypted due to password resets
- Reduced app size by symlinking shared bundles for extensions

# Version 1.17.0
Password history:
You can now view a list of all your previously generated passwords. Navigate to the Profile tab > Generated passwords.

Others:
- New onboarding flow with payment support (behind feature flags)
- Fixed an issue where file picker sometimes not show up
- Renamed "Admin" to "Manager"

# Version 1.16.3
- File attachment v2
- Removed "PassIOSImportCsv" flag
- Core libraries upgraded from 30.0.2 to 30.0.4

# Version 1.16.2
- Allow numbers as separators in password generation, even with "Include numbers" disabled
- Fixed issues where some texts were not properly localized
- Order pinned items by pinning date

# Version 1.16.1
Fixed an issue where search results failed to refresh after moving items to other vaults

# Version 1.16.0
Chrome importer:
You can now import passwords directly from Chrome. Navigate to the Profile tab > Import to Proton Pass.

Improvements:
- Fixed an issue where the "send email" button was unresponsive for alias contacts
- Core libraries upgraded from 29.0.12 to 30.0.2

# Version 1.15.1
In-app AutoFill enabling (iOS 18):
You can now enable AutoFill directly in the app, offering a quicker and more seamless login experience on iOS 18.

Improvements:
- Support simplified Chinese
- Support updating mailbox email addresses
- Resolve invitation issues after invitee address key updates
- Prevent hyphens in long passwords before line breaks

Others:
- Introduce new login screen variant
- Allow admins to restrict vault creation (B2B policy)
- Add discovery banners for alias-related features
- Support restoring purchases
- Secure link creation with item keys
- Update core libraries to 29.0.12 from 29.0.6
- Display trashed items in "Shared with me" and "Shared by me" views

# Version 1.15.0
Individual item sharing:
You can now share items individually, giving you greater control and flexibility over what you share.

Improvements:
- Added a badge for logins with 2FA enabled
- Fixed issue where long notes were not fully visible when editing
- Improved discovery of alias-related features
- Added deep link support for alias management
- Core libraries upgraded from 27.0.0 to 29.0.6

# Version 1.14.3
Better authentication:
Now, when autofilling, you'll only need Face ID or Touch ID for authentication if you've used the app recently—no need to reauthenticate within the app. This streamlines your experience while keeping your data secure.

Improvements:
- Re-encrypt item keys instead of the last 50 revisions when moving items to other vaults
- Enhanced display and editing of shared aliases
- Logins with passkeys are no longer flagged as missing 2FA
- Pinned items now update correctly after being trashed or restored
- Dismiss the keyboard automatically when scrolling through search results

# Version 1.14.1
Features:
- Resolved jumbled favicons issue on iOS 17

Improvements:
- Enhanced autofill to rely on system authentication if the app or autofill was recently used
- Adjust section title color dynamically when editing items based on content emptiness

Others:
- Core libraries upgraded from 26.5.0 to 27.0.0
- Remove FIDO2 feature flag

# Version 1.14.0
Features:
- Advanced alias management part 2 (behind feature flags)

Improvements:
- Improved app launch and search performance with large item sets

Others:
- Core libraries upgraded from 26.1.2 to 26.5.0
- Enabled Swift 6 mode
- Removed PassAccountSwitchV1 feature flag
- Added support for toggling feature flags dynamically

# Version 1.13.3
Show warning when deleting aliases

# Version 1.13.2
Features:
- Added support for arbitrary text filling (iOS 18): Long press on any text field -> AutoFill -> Passwords

Improvements:
- Enabled app launch via protonpass:// deeplink
- Tap the item counter to filter by item type

Others:
- Updated Rust library from 0.8.2 to 0.8.3
- Updated Factory (DI tool) to 2.4.0 for Swift 6 compliance
- Introduced advanced alias management (behind feature flags)

# Version 1.13.1
One-time verification codes autofill (iOS 18)

# Version 1.13.0
Features:
- Autofill now supports all logged-in accounts
- Tinted icons support for iOS 18

Improvements:
- Bulk pin/unpin for items
- Email or username can now be entered when creating login items
- New toggle in Settings to always display the username field

Others:
- Core library upgraded from 25.3.4 to 26.1.2
- Fixed mailbox selection not highlighting
- Resolved CryptoKit issue on iOS 18
- Bulk alias enable/disable (feature flag controlled)

# Version 1.12.3
Features:
- Support for multiple accounts (behind feature flags)

Fixes:
- Resolved issue preventing PIN lock setup on devices without a passcode
- Fixed cursor jumping during note edits
- Fixed context loss after switching apps with "Immediately" lock time

Improvements:
- Enhanced search functionality
- Social security numbers now handled as sensitive data
- Case-insensitive alphabetical sorting
- Last selected vault is now remembered
- Redesigned bug report page

Others:
- Bump core library from 25.2.0 to 25.3.4
- Full sync restarts if the app is terminated mid-process
- "Manage subscription" hidden for non-admin B2B users
- Fixed issue with adding username when creating login from AutoFill extension

# Version 1.12.2
Improvements:
- Fixed secure link list not refreshing after moving items
- Added identity result count to the search page

# Version 1.12.1
Improvements:
- Fixed the issue where the homepage gets stuck in a loading state when switching to another tab while items are not fully synced
- Added the ability to show/hide extra passwords during definition

# Version 1.12.0
Features:
- Added support for secure links
- Added support for extra password

Others:
- Bumped core 25.2.0
- Bumped Rust library 0.7.13
- Removed Pass Monitor flag check
- Disabled editing functionality during the creation and save operations
- [B2B] Send item read events to the BE
- Removed "Sync complete" screen and show a toast message instead

# Version 1.11.3
Fixed crashes when revealing passwords on iOS 18

# Version 1.11.2
- Fixed theme settings not respected
- Fixed 2FA code being copied when no local authentication method set
- Fixed overflowed email textfield when sharing vaults

# Version 1.11.1
Fixes:
- Resolved issue where users were unable to request a new verification code for custom emails

Others:
- Bumped core version to 25.0.1
- Implemented retrieval of root domains of URLs using Rust library
- Added support for separate username

## Version 1.11.0
Features:
- Introducing Pass Monitor: Dark Web Monitoring, password health analytics, and more

Improvements:
- Addressed occasional crashes 

Others:
- Bumped core version to 24.0.0
- Bumped Rust library version to 0.7.8
- Migrated preferences storage from Keychain to Core Data
- Displayed item content format version for QA builds
- Handled Pass Essentials upgrade
- Added Passkeys metadata
- Moved vault picker to navigation bar when creating new items
- Able to change password (behind core's feature flags)

## Version 1.10.2
Improvements:
- Preserved item history when moving between vaults
- Enhanced app accessibility

Fixes:
- Resolved inability to edit custom fields when dealing with a large quantity

Others:
- Added support for push notifications and account recovery
- Upgraded core version to 21.0.0
- Utilized throwing functions of Keychain
- Updated content format to version 4, including passkey metadata
- Enhanced password scorer with Rust library version 0.7.7
- Set default to 5-word passphrases
- Cleanup of unused code
- Fixed issue where 2FA codes were sometimes not automatically copied
- Implemented tips to promote niche features
- Ensured adherence to organization's automatic lock settings
- Introduced new APIs to prepare for preferences migration

## Version 1.10.1
Fixed passkeys generated by other platforms sometimes not usable

## Version 1.10.0
Features:
- Added support for Passkeys
- Added support for Dutch, Danish, Indonesian and Slovenian languages
- Implemented item cloning feature

Fixes:
- Fixed issue preventing QR code scanning in photos selected from the photo library

Others:
- Updated core library version to 20.0.0
- Updated Rust library version 0.7.1
- Changed the position of quick action buttons when creating/editing login items
- Updated the error message when B2B users reach vault sharing limit
- Implemented server update message handling
- Respect organization settings when sharing to addresses outside of the organization
- Show TOTP token instead of URI when viewing item's history
- Implemented upselling feature for item history
- Added more actions to context menu for credit cards
- Added localization for permission descriptions
- Added support for Optic ID in visionOS
- Added "view history" option to context menu
- Declared app privacy manifest
- Mitigated crashes on AutoFill extension

## Version 1.9.1
Improvements:
- Made alias addresses searchable

Others:
- Updated protobuf models & bumped item content format version from 2 to 3
- Do not dismiss search page when selecting results
- Fixed free users can not autofill from shared vaults

## Version 1.9.0
Features:
- Added support for "Set up verification codes"
- Added support for Spotlight

Others:
- Bumped core version from 18.0.1 to 19.0.0
- Updated protobuf models & bumped item content format version from 1 to 2

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
