# Debug network traffic
You can print to the console information related to requests (HTTP method, path, headers, & parameters) and responses (HTTP method, status code, url, headers & result) by activating `me.proton.pass.NetworkDebug` environment variable in the scheme configuration. This is disabled by default.

# Debug Sentry activities
You can print to the console Sentry activities by activating `me.proton.pass.SentryDebug` environment variable in the scheme configuration. This is disabled by default.

# Make a new build and upload to TestFlight
Create an "App-specific password" via [https://appleid.apple.com](https://appleid.apple.com)
Create Sentry auth token by going to User settings > Auth Tokens > Create new token with default selected scopes

Run this command

> SENTRY_AUTH_TOKEN=<sentry_auth_token> FASTLANE_USER=<apple_id_email> FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=<app_specific_password> fastlane build_and_upload

You will be asked for Apple ID's password on first run.

Select a build variant when prompted:
1. App Store: public builds for App Store
2. TestFlight: beta builds for TestFlight (In-App Purchase disabled)
3. QA: internal builds for QA

Enter version number in semver format when prompted.

The script will automatically gets the latest build number of the given version, increase by 1 to make the new build number and begin the build & upload processes.

The output IPA & dSYM files are stored in "build" folder