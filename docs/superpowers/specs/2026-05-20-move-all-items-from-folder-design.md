# Move all items from a folder — Design

**Status:** Draft
**Date:** 2026-05-20
**Author:** Martin Lukacs (with Claude)
**Branch:** `feature/folder-implementation-part-2`

## Summary

Extend the existing "Move all items" feature so it can be triggered from a folder, not only from a vault. Moving items from a folder includes the folder's direct items **and** items in all descendant subfolders, transferred to a single user-picked destination. Folders themselves stay in place (empty after the move). The destination picker is shared with all other move flows.

## Motivation

Today, "Move all items" only exists at the vault level (three-dots menu next to a vault row in `EditableVaultListView`). With folders introduced as a primary organizational unit, users need a symmetric action at the folder level — otherwise emptying a folder requires either deleting it (destructive) or moving items one-by-one. This design reuses the existing pipeline so the new action behaves identically to its vault-level counterpart in terms of UX, errors, and telemetry surface.

## Agreed scope decisions

| Decision | Value | Rationale |
|---|---|---|
| Source | The folder being acted on + recursive items from all descendant subfolders | What the user requested. |
| Destination | **Anywhere** — any vault root or any folder, no exclusions | Picker stays unrestricted; backend handles same-folder and descendant-folder destinations gracefully (no-ops where applicable). |
| Folder structure after move | Folders stay in place (now empty) | Symmetric with vault-level "Move all items" (source vault remains, now empty). User can manually delete folders later. |
| Entry point | `FolderMenuView` (three-dots menu on a folder row in `EditableVaultListView`) | Mirrors `vaultTrailingMenuView` placement. |
| Wording | Success message branches on destination type (vault vs folder) for **all** source types, not just the new one | User feedback — match the user's mental model of where items landed. |

## Non-goals

- Moving the folder structure itself (only items move; folders stay).
- Auto-deleting now-empty source folders.
- A new bulk-move backend API. The implementation uses the existing `move(items:toShareId:destinationFolderId:)` repository method.
- Restricting destinations based on the source folder.

## Architecture & data flow

The new action reuses the existing destination-picker pipeline verbatim. Only a fourth `MovingContext` case ("all items recursively contained in a folder") is added.

```
[FolderMenuView] ── viewModel.moveAllItemsInFolder(folder) ──▶ [Router.moveItemsBetweenVaults(.allItemsInFolder(folder))]
                                                                            │
                                                                            ▼
[HomepageCoordinator.itemMoveBetweenVault(context:)] ──▶ [ItemMoveVaultListView] ◀── existing picker, unchanged
                                                                            │ user picks destination, taps Move
                                                                            ▼
[ItemMoveVaultListViewModel.doMove()] ──▶ [MoveItemsBetweenContainersUseCase.execute(context:to:destinationFolderId:)]
                                                                            │
                                                                            ▼   (new case)
                appContentManager.getShareContent(for: folder.shareId)?.flattenedItems(from: folder.folderId)
                                                                            │
                                                                            ▼
                              [ItemRepositoryProtocol.move(items:toShareId:destinationFolderId:)]
                                                                            │
                                                                            ▼
                                           existing same-share or cross-share move path
                                                                            │
                                                                            ▼
                                  Destination-aware success toast ("...vault « V »" or "...folder « F »")
```

## Detailed changes

### 1. Client layer — `MovingContext`

**File:** `LocalPackages/Client/Sources/Client/ClientModels/MovingContext.swift`

Add a fourth case:

```swift
public enum MovingContext: Sendable, Equatable, Hashable {
    case singleItem(any ItemTypeIdentifiable)
    case allItems(Share)
    case allItemsInFolder(FolderUiModel)     // NEW
    case selectedItems([any ItemIdentifiable])
}
```

`FolderUiModel` is already `Sendable + Equatable + Hashable`, so enum conformances stay satisfied. Extend `==` with `(.allItemsInFolder(l), .allItemsInFolder(r)) => l.id == r.id` and `hash(into:)` with `hasher.combine(folder.id)`. `FolderUiModel.id` is `folderId + shareId`, the right uniqueness key.

### 2. UseCases layer — `MoveItemsBetweenContainers`

**File:** `LocalPackages/UseCases/Sources/UseCases/Vaults/MoveItemsBetweenVaults.swift`

Add `appContentManager` as a constructor dependency and handle the new case:

```swift
public final class MoveItemsBetweenContainers: MoveItemsBetweenContainersUseCase {
    private let repository: any ItemRepositoryProtocol
    private let appContentManager: any AppContentManagerProtocol  // NEW

    public init(repository: any ItemRepositoryProtocol,
                appContentManager: any AppContentManagerProtocol) {
        self.repository = repository
        self.appContentManager = appContentManager
    }

    public func execute(context: MovingContext,
                        to shareId: ShareID,
                        destinationFolderId: String?) async throws {
        switch context {
        case let .singleItem(item):
            try await repository.move(items: [item], toShareId: shareId,
                                      destinationFolderId: destinationFolderId)
        case let .allItems(fromVault):
            try await repository.move(currentShareId: fromVault.shareId,
                                      toShareId: shareId,
                                      destinationFolderId: destinationFolderId)
        case let .allItemsInFolder(folder):                                   // NEW
            guard let shareContent = appContentManager
                .getShareContent(for: folder.shareId) else { return }
            let items = shareContent.flattenedItems(from: folder.folderId)
            guard !items.isEmpty else { return }
            try await repository.move(items: items, toShareId: shareId,
                                      destinationFolderId: destinationFolderId)
        case let .selectedItems(items):
            try await repository.move(items: items, toShareId: shareId,
                                      destinationFolderId: destinationFolderId)
        }
    }
}
```

`ShareContent.flattenedItems(from:)` (Entities, `ShareContent.swift:138`) already returns `[ItemUiModel]`, and `ItemUiModel` conforms to `ItemIdentifiable`. No new traversal code is introduced — this is the same primitive used by `AppContentManager.deleteFolder` for recursive content discovery.

**DI registration** — `iOS/AppManagement/DependencyInjection/iOS/UseCases+DependencyInjections.swift:308`:

```swift
var moveItemsBetweenContainers: Factory<any MoveItemsBetweenContainersUseCase> {
    self {
        MoveItemsBetweenContainers(repository: self.itemRepository,
                                   appContentManager: SharedServiceContainer.shared.appContentManager())
    }
}
```

(Exact resolver matches the surrounding factory style.)

### 3. Picker — `ItemMoveVaultListViewModel`

**File:** `iOS/Scenes/Homepage/Items Tab/Vault/ItemMoveVaultListViewModel.swift`

**Init switch** (line 55) — preselect the source share:

```swift
let fromShareId: String? = switch context {
case let .singleItem(item):         item.shareId
case let .allItems(vault):          vault.shareId
case let .allItemsInFolder(folder): folder.shareId   // NEW
case .selectedItems:                nil
}
```

**Success message** (line 124) — refactor to be destination-aware across all source types:

```swift
private enum MoveDestination {
    case vault(name: String)
    case folder(name: String)
}

private func successMessage(destination: MoveDestination) -> UIElementDisplay {
    switch context {
    case let .singleItem(item):
        let message: String = switch destination {
        case let .vault(name):  #localized("Item moved to vault « %@ »", name)
        case let .folder(name): #localized("Item moved to folder « %@ »", name)
        }
        return .successMessage(message, config: .dismissAndRefresh(with: .update(item.type)))

    case let .allItems(fromVault):
        let message: String = switch destination {
        case let .vault(name):
            #localized("Items from « %@ » moved to vault « %@ »", fromVault.vaultName ?? "", name)
        case let .folder(name):
            #localized("Items from « %@ » moved to folder « %@ »", fromVault.vaultName ?? "", name)
        }
        return .successMessage(message, config: .dismissAndRefresh)

    case let .allItemsInFolder(folder):
        let message: String = switch destination {
        case let .vault(name):
            #localized("Items from folder « %@ » moved to vault « %@ »", folder.content.name, name)
        case let .folder(name):
            #localized("Items from folder « %@ » moved to folder « %@ »", folder.content.name, name)
        }
        return .successMessage(message, config: .dismissAndRefresh)

    case let .selectedItems(items):
        let message: String = switch destination {
        case let .vault(name):  #localized("%lld items moved to vault « %@ »", items.count, name)
        case let .folder(name): #localized("%lld items moved to folder « %@ »", items.count, name)
        }
        return .successMessage(message, config: .dismissAndRefresh)
    }
}
```

**Call site** in `doMove()`:

```swift
let destination: MoveDestination = if let folder = selectedContainer.folder {
    .folder(name: folder.content.name)
} else {
    .vault(name: selectedContainer.share.vaultName ?? "")
}
router.display(element: successMessage(destination: destination))
```

Names are pulled from canonical sources (`folder.content.name`, `share.vaultName`) rather than the picker row's display title, so messaging is unaffected by future picker-UI changes.

### 4. Source UI — `EditableVaultListViewModel` + `FolderMenuView`

**File:** `iOS/Scenes/Homepage/Items Tab/Vault/EditableVaultListViewModel.swift`

Add two helpers alongside the existing `canMoveItems(vault:)` (line 224):

```swift
func canMoveItems(folder: FolderUiModel) -> Bool {
    guard let content = shareContent(for: folder.shareId),
          canUserPerformActionOnVault(for: content.share) else { return false }
    return content.flattenedItems(from: folder.folderId).count > 0
}

func moveAllItemsInFolder(_ folder: FolderUiModel) {
    router.present(for: .moveItemsBetweenVaults(.allItemsInFolder(folder)))
}
```

**File:** `iOS/Scenes/Homepage/Items Tab/Vault/EditableVaultListView.swift` — `FolderMenuView` (line 529)

Add a new entry between "Rename" and the `Divider() + Delete folder` block:

```swift
if viewModel.canMoveItems(folder: folder) {
    Button(action: { viewModel.moveAllItemsInFolder(folder) }, label: {
        Label(title: {
            Text("Move all items")
        }, icon: {
            IconProvider.folderArrowIn
                .renderingMode(.template)
                .foregroundStyle(PassColor.textWeak)
        })
    })
}
```

Placement before `Divider()` keeps the destructive "Delete folder" action visually isolated, matching the vault menu's pattern. The "Move all items" string already exists in the catalog (used at vault level), so no new entry is needed for it.

### 5. Localization

**File:** `iOS/Shared/Localization/Localizable.xcstrings`

Five new entries (existing "vault" strings stay):

| Key | Source × Destination |
|---|---|
| `"Item moved to folder « %@ »"` | `.singleItem` → folder |
| `"Items from « %@ » moved to folder « %@ »"` | `.allItems` (vault source) → folder |
| `"Items from folder « %@ » moved to vault « %@ »"` | `.allItemsInFolder` → vault |
| `"Items from folder « %@ » moved to folder « %@ »"` | `.allItemsInFolder` → folder |
| `"%lld items moved to folder « %@ »"` | `.selectedItems` → folder |

All five mirror existing entries in shape. The pre-commit string-catalogue scanner picks them up on the next run.

## Edge cases & error handling

| Case | Handling |
|---|---|
| Folder has no items recursively | UI hides menu entry via `canMoveItems(folder:)`. |
| Share content unloaded between menu-tap and execute | Use case's `guard let shareContent` returns silently. |
| `flattenedItems` returns empty (race: sync emptied folder) | Use case's `guard !items.isEmpty` returns silently. |
| Destination = source folder itself | Allowed per agreed scope. Same-share move is a no-op for items already in the target folder; subfolder items move into it. |
| Destination = descendant of source folder | Same: items in that descendant stay; items elsewhere in the subtree move into it. Backend handles via `MoveItemsInSameShareEndpoint`. |
| User loses share permission between tap and execute | Backend rejects; existing error-banner path in `doMove()` displays the error. |
| Folder name contains `%` or `«` | `#localized` macro escapes safely — same as existing vault-name placeholders. |

No new error paths are introduced. Failures bubble up to the existing `catch` in `ItemMoveVaultListViewModel.doMove()` (`logger.error` + `displayErrorBanner`).

## Testing

Uses Swift Testing (project standard).

**Use case tests** — new file at `LocalPackages/UseCases/Tests/UseCasesTests/Vaults/MoveItemsBetweenVaultsTests.swift` (directory exists; sibling tests live alongside `CanUserPerformActionOnVaultTests.swift`):

- `.allItemsInFolder` with items directly in folder → `repository.move(items:...)` called with those items.
- `.allItemsInFolder` with items only in subfolders → flattened set passed.
- `.allItemsInFolder` mixing direct + nested items → flattened set in `flattenedItems` traversal order.
- `.allItemsInFolder` with `getShareContent == nil` → no repository call, no throw.
- `.allItemsInFolder` with empty folder → no repository call, no throw.
- Destination `shareId` and `destinationFolderId` pass through unchanged.

Uses auto-generated `AppContentManagerProtocolMock` and `ItemRepositoryProtocolMock`.

**Picker tests** — new file under `iOSTests/` (the `iOSTests/Homepage/` subdirectory does not exist yet; the new test file should be placed in a subdirectory mirroring the production path `iOS/Scenes/Homepage/Items Tab/Vault/` or in a flat layout consistent with the rest of `iOSTests/`):

- Init with `.allItemsInFolder(folder)` preselects share matching `folder.shareId`.
- Success message: parameterized over `(MovingContext source × hasFolderDestination) → expected key`, covering all 8 combinations.

**Source view model tests** — new `EditableVaultListViewModelTests.swift` under `iOSTests/` (same placement note as the picker tests above):

- `canMoveItems(folder:)` returns true for editable share with non-empty folder.
- Returns false when share is not editable.
- Returns false when folder is recursively empty.

UI/snapshot tests for `FolderMenuView` are out of scope per project testing strategy. The new menu entry is verified manually.

## Risks

| Risk | Mitigation |
|---|---|
| Existing success-message wording changes for folder destinations across all source types | Acknowledged in scope decisions; the user explicitly requested this. Translators see a clean diff (additions only, no key renames). |
| `AppContentManagerProtocol` now a constructor dep on the use case | Already used elsewhere in UseCases via Factory DI; no new layer crossing. |
| Race between menu visibility and execute (folder emptied or share unloaded) | Defensive guards in the use case make the result a silent no-op rather than crash or error toast. |
| Destination = descendant relies on backend correctness | Same code path as same-share move with `destinationFolderId`; already exercised by existing `.singleItem` and `.selectedItems` flows. |

## Out-of-scope follow-ups

- Optional "Delete empty folders" follow-up alert after the move.
- Restricting destination picker to exclude source folder + descendants (we explicitly chose not to).
- Bulk endpoint that takes `(fromShareId, fromFolderId) → (toShareId, toFolderId?)` in a single request.

## Files touched

| File | Change |
|---|---|
| `LocalPackages/Client/Sources/Client/ClientModels/MovingContext.swift` | New enum case + `==` / `hash(into:)` arms |
| `LocalPackages/UseCases/Sources/UseCases/Vaults/MoveItemsBetweenVaults.swift` | New constructor dep + new switch arm |
| `iOS/AppManagement/DependencyInjection/iOS/UseCases+DependencyInjections.swift` | Pass `appContentManager` to factory |
| `iOS/Scenes/Homepage/Items Tab/Vault/ItemMoveVaultListViewModel.swift` | Init switch + `MoveDestination` enum + refactored `successMessage(destination:)` + `doMove` call site |
| `iOS/Scenes/Homepage/Items Tab/Vault/EditableVaultListViewModel.swift` | `canMoveItems(folder:)` + `moveAllItemsInFolder(_:)` |
| `iOS/Scenes/Homepage/Items Tab/Vault/EditableVaultListView.swift` | New menu entry in `FolderMenuView` |
| `iOS/Shared/Localization/Localizable.xcstrings` | Five new strings |
| `LocalPackages/UseCases/Tests/UseCasesTests/Vaults/MoveItemsBetweenVaultsTests.swift` | New file — use-case test cases |
| `iOSTests/.../ItemMoveVaultListViewModelTests.swift` | New file — picker tests (path determined by the implementation plan) |
| `iOSTests/.../EditableVaultListViewModelTests.swift` | New file — source view-model tests (path determined by the implementation plan) |
