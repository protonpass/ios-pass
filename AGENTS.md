# Proton Pass - iOS/macOS

Proton Pass password manager for iOS and macOS (GPLv3), built with Swift 6.2, SwiftUI and Clean Architecture + MVVM + Coordinator.

## Project map

- `ProtonPass.xcodeproj` - Xcode project for all app targets
- `iOS/`, `macOS/`, `iOS & macOS/` - app targets and shared app code
- `AutoFill/`, `Share/`, `Action/` - extensions
- `LocalPackages/` - SPM modules; dependency flow `Screens -> DIComposition -> UseCases -> Client -> Core -> Entities` (+ `PassRustCore`)
- `LocalPackages/DIComposition/` - Factory DI containers
- `LocalPackages/DesignSystem/` - shared UI components
- `LocalPackages/TestingToolkit/` - shared test helpers
- `iOSTests/`, `iOSUITests/`, `TestPlans/` - app-level tests and test plans
- `docs/claude/` - detailed architecture and pattern docs (table below)

## Tech stack

- Swift 6.2 (`swift-tools-version: 6.2`, Swift 6 language mode) with `NonisolatedNonsendingByDefault` and `InferIsolatedConformances` (DIComposition: Swift 6 mode only)
- Screens and DesignSystem use `.defaultIsolation(MainActor.self)`
- DI via Factory (FactoryKit); 100% SwiftUI views; navigation via NavigationStack + router and UIKit (`UINavigationController` / `UISplitViewController`)

<important if="you need to run commands to build, test, lint, format, generate mocks, or validate strings">

Pre-commit hooks run SwiftFormat then SwiftLint (strict). Run these before committing:

| Command | What it does |
|---|---|
| `swiftformat .` | Format code (config: `.swiftformat`) |
| `swiftlint lint` | Lint (config: `.swiftlint.yml`, custom rules included) |
| `./scripts/binary/string-catalogs-scanner --allow-needs-review-translations --verbose` | Validate string catalogs |
| `MissingBundleScanner --config .missing-bundle-scanner.yml` | Check package strings pass `bundle: .module` |
| `sourcery` | Regenerate mocks from `// sourcery: AutoMockable` |
| `periphery scan` | Find unused code |
| `fastlane unit_test` | Run unit tests |

Exact commands for one target or suite (skills run these verbatim; keep them current):

- Build: `xcodebuild build -project ProtonPass.xcodeproj -scheme iOS -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation -skipMacroValidation`
- AutoFill build: `xcodebuild build -project ProtonPass.xcodeproj -scheme AutoFill -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation -skipMacroValidation ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`. The Rust xcframework has no x86_64 simulator slice
- Tests, one target: `xcodebuild test -project ProtonPass.xcodeproj -scheme iOS -testPlan iOS -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation -skipMacroValidation -collect-test-diagnostics never -only-testing:<Target>` where `<Target>` is `ClientTests`, `CoreTests`, `EntitiesTests` or `UseCasesTests`. Without `-collect-test-diagnostics never`, a failing run spends up to 10 minutes and several GB collecting simulator diagnostics. `iOSTests` is disabled and empty: logic that needs unit tests goes in `Entities`
- Faster for Entities and UseCases: from `LocalPackages/<Name>`, `xcodebuild test -scheme <Name>-Package -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation -skipMacroValidation -collect-test-diagnostics never -only-testing:<Name>Tests/<Suite>`. `swift test`, `-scheme Client`, `ClientTests` and `UnitTests` don't work; other `-Package` schemes are untested
- One suite: `-only-testing:<Target>/<Suite>`. One backtick-named test: quote the whole argument and keep the backticks and `()`, e.g. ``'-only-testing:EntitiesTests/FolderSupportStateTests/`a not yet loaded plan grants nothing`()'``. Check the `Test run with N tests` line: a filter that matches nothing still reports success
- Destination: the simulator must be on a runtime the selected Xcode supports (`xcrun simctl list devices available`). A name on an older runtime resolves to "My Mac" and fails; `-destination 'id=<udid>'` avoids the ambiguity
- Lint changed files: `swiftlint lint --strict <paths>` and `swiftformat --lint <paths>`, source files only. Test folders are excluded by config, and passing a test path explicitly reports violations CI never flags
- Before any `xcodebuild`, note `git status --porcelain`. Afterwards revert every file that changed and isn't yours: the iOS target's SwiftFormat build phase (also in AutoFill builds) can reformat files across the repo. Always revert `iOSUITests/ObfuscatedConstants.swift` and `LocalPackages/*/Package.resolved`, and delete any untracked `Package.resolved` a package-directory run leaves
- E2E: not configured.
</important>

<important if="you are editing generated or vendored files">

Do not edit:
- `**/*.pb.swift` - Protobuf generated
- `LocalPackages/*/Sources/*Mocks/` and `iOSTests/Mocks/Generated/` - Sourcery generated; regenerate with `sourcery`
- `LocalPackages/PassRustCore/` - binary xcframework
</important>

<important if="you are creating or modifying protocols, use cases, or repositories">

- All protocols must be `Sendable`; use async/await and structured concurrency
- Use cases: `Sendable` protocol declaring `callAsFunction` + `struct` implementation, no `execute()` wrapper. Older ones use `execute()` + extension + class; don't convert them unasked
</important>

<important if="you are adding or resolving dependencies through DI">
- Use Factory. Resolve with `private let x = dependency(\Container.key)` by default; `resolve()` is deprecated
- Use `@LazyInjected` only when resolving at init is wrong (cycle, not yet available, expensive and rarely used); in `@Observable` classes add `@ObservationIgnored`
- Containers, scopes and rules: `docs/claude/dependency-injection.md`
</important>

<important if="you are adding or modifying user-facing strings">
- Use the `#localized("key")` macro, never raw `NSLocalizedString`
- In `LocalPackages`, pass `bundle: .module`, use `Text(verbatim:)` for non-localized strings, or append `// ignore:missing_bundle`
</important>

<important if="you are creating new files or deciding where code belongs in the Screens package">
- Follow the placement rules in `docs/claude/screens-structure.md`
</important>

<important if="you are refactoring, fixing, or building a feature that touches views or view models in the main app target (`iOS/Scenes/`, `iOS/Shared/UIElements/`)">

Views and view models are moving from the app target into the Screens package.
- Before starting, ask the user whether to move the touched files into Screens as part of the change. Never move them unasked
- New screens go into Screens. If one needs app-only code that can't be passed in through a closure or protocol, ask before putting it in the app target
- Follow the recipe in `docs/claude/screens-structure.md` (Migrating app code into Screens)
</important>

<important if="you are writing or modifying tests">

- Swift Testing for anything new, never XCTest
- Every test name is a backticked sentence: ``@Test func `does the thing`()``. Never `@Test("display name")` with a camelCase identifier, never a bare camelCase name
- Traits go on their own line (`@Test(arguments:)`, `@Test(.timeLimit(...))`); otherwise `@Test func` stays inline
- Suites are tagged, not named: `@Suite(.tags(.entity))`
- Assertion mapping and tag list: `docs/claude/testing.md`
</important>

<important if="you are building or changing a feature that touches view models in the Screens package">

- Cover the view-model behaviour you add or change with tests in `ScreensTests`, using the per-test container traits (`ScreensTests/Utils/ContainerTraits.swift`, details in `docs/claude/testing.md`)
- This is an extra layer, not a replacement: keep writing tests first (TDD) for use cases, repositories and entities in their own packages as before, and test in Screens only what lives in the view model
</important>

<important if="you are writing or editing code comments or doc comments">

Default to zero comments. A file with no comments is a normal, complete outcome. Comment only when a senior engineer could not recover the information from the code, and only after renaming, extracting a function, or encoding the rule in a type has failed.

Never write: restatements of the next line; step-by-step narration; doc comments that echo the signature; changelog commentary ("changed to a struct"); commented-out code, banners, or "new"/"for now"/"currently"; explanations aimed at the reviewer (put rationale in your response).

Do write: why this way and not the obvious way; workarounds with a radar/issue/forum reference; invariants the compiler can't express; isolation reasoning (why `nonisolated`, why work leaves the main actor, and a mandatory justification for every `@unchecked Sendable`); the safety proof for any force unwrap or `try!` (if you can't state it, don't use it); performance decisions citing only what was measured; `TODO:`/`FIXME:` only with a tracking ID.

Use `///` on public API of shared modules. For `internal`/`private`, only when the contract is surprising (throwing, cancellation, ownership, isolation).

When editing existing code, match the file's comment density. Remove existing comments only if they're wrong, stale, or in the never-write list, and say so in your response. For a full pass, run the `/comment-audit` skill.
</important>

<important if="you are changing architecture, module boundaries, DI containers, or coding patterns, or adding a new DI container, use case, repository, or coordinator">

Update the matching doc in `docs/claude/` in the same change, and bump its `Last verified` timestamp.

| File | Covers |
|------|--------|
| `docs/claude/architecture.md` | Module map, dependency graph, app targets |
| `docs/claude/local-packages.md` | All LocalPackages in detail |
| `docs/claude/coding-patterns.md` | UseCase, ViewModel, Coordinator, Repository, View patterns |
| `docs/claude/dependency-injection.md` | Factory DI system, containers, registration |
| `docs/claude/swift-concurrency.md` | Swift 6 concurrency model, isolation, Sendable |
| `docs/claude/data-layer.md` | CoreData, networking, repositories, storage |
| `docs/claude/extensions-and-targets.md` | iOS, macOS, AutoFill, Share, Action extensions |
| `docs/claude/testing.md` | Testing strategy, mocks, test plans |
| `docs/claude/tooling.md` | SwiftLint, SwiftFormat, Sourcery, Periphery, CI/CD, Claude skills |
| `docs/claude/screens-structure.md` | Screens package folder structure, placement rules, app-migration plan |
</important>
