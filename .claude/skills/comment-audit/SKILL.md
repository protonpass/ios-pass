---
name: comment-audit
description: "Strips low-value comments out of code and rewrites the survivors to explain why rather than what. Use whenever the user asks to clean up, trim, reduce, audit, or review comments or doc comments; when they mention comment bloat, over-commented code, noisy or redundant comments, or 'too many comments'; when preparing a diff for commit or merge request review; and when reviewing someone else's code for comment quality. Apply even if the user doesn't explicitly ask for an audit — if a file being touched is visibly over-commented, run this."
---

# Comment Audit

A pass that removes comments carrying no information and rewrites the rest to state *why*. Behaviour must not change: this pass edits comments only, never code.

## Scope first

Before editing, establish scope and say what it is:

- Named files, or the working-tree diff, or a specific type — never "the whole repo" unasked.
- **Exclude generated files entirely.** UniFFI bindings, Sourcery output, `*.generated.swift`, protobuf, anything with a "do not edit" header. Editing these is churn that the next codegen run reverts.

## Triage every comment into one of three buckets

### Delete

- **Restatement** — paraphrases the line below it (`// Increment the counter` over `count += 1`).
- **Step narration** — `// 1. Fetch`, `// 2. Parse`, `// 3. Save` over code that already reads in that order.
- **Signature echoes** — `/// - Parameter id: The ID.` and `/// - Returns: The user.` where the declaration already says it.
- **Changelog commentary** — `// Changed to a struct for value semantics`, `// Added error handling`. Belongs in the commit message.
- **Commented-out code** — delete; version control has it.
- **Decorative banners** — box-drawing, `====`, repeated dashes around a `MARK`.
- **Temporal claims** — "new", "for now", "currently", "recently fixed". Unverifiable and quickly false.
- **Untracked `TODO:`/`FIXME:`** with no ticket ID and no owner. Either file the ticket and reference it, or drop the comment.

### Keep untouched

Some comment-shaped lines are load-bearing. Deleting these breaks tooling, CI, or legal compliance. Recognise them and leave them alone:

- `// swiftlint:disable`, `// swiftlint:disable:next`
- `// swift-format-ignore`, `// swift-format-ignore-file`
- `// sourcery:` annotations — these drive code generation
- `// periphery:ignore` and equivalent dead-code-scanner pragmas
- License and SPDX headers
- `// MARK:` — structural, feeds the Xcode jump bar (strip surrounding decoration, keep the directive)
- Any comment containing a radar, issue, or ticket reference — the link is the value

### Rewrite

The interesting bucket: a comment that explains *what* while sitting on code that has a real, undocumented *why*. Don't just delete — recover the reason.

```swift
// before
// Wait 250ms then complete the request
try await Task.sleep(for: .milliseconds(250))
completeRequest()

// after
// `pasteboardd` drops the write if the extension terminates before it flushes.
try await Task.sleep(for: .milliseconds(250))
completeRequest()
```

If you cannot determine the *why* from the surrounding code, do **not** invent one. Delete the restatement and flag the line in your report as needing an author who knows the history.

## Rewriting rules

- State the constraint, not the mechanism. A comment about mechanism goes stale on the next edit; a comment about a constraint stays true.
- One or two lines. If it needs a paragraph, the code needs restructuring instead — say so rather than writing the paragraph.
- Prefer eliminating the comment structurally: rename the symbol, extract a named function, or encode the rule in a type. Propose this when it's clearly better; don't refactor silently during a comment pass.
- Swift specifics worth preserving or adding: the justification for `@unchecked Sendable`, why a member is `nonisolated`, why work leaves the main actor, and the safety proof behind any force unwrap or `try!`.

## Doc comments

- Public API of a shared module or package: keep, tighten.
- `internal` / `private` / `fileprivate`: delete unless the contract is surprising — throwing behaviour, cancellation semantics, ownership, isolation.
- Trim parameter lists to the parameters that need explaining. A partial doc comment beats a padded one.

## Report

After editing, report tersely — counts by bucket, then anything needing a human:

```
comment-audit — Sources/Sync/, 4 files

removed 31
  restatement 18 · step narration 6 · signature echo 5 · commented-out 2
rewritten 3
  SyncEngine.swift:88   sleep duration → reason for the delay
  Store.swift:142       "thread safe" → which actor guarantees it
  Client.swift:210      retry count → why 3 and not backoff

needs an author
  Migration.swift:64    "special case for v2 payloads" — no v2 handling
                        visible; stale or the check moved. Left in place.
kept (load-bearing)
  4 swiftlint pragmas, 2 sourcery annotations, license headers
```

Do not list every deletion individually — the diff shows them. List only rewrites and open questions.

## Verify

Comment-only edits cannot change behaviour, so the check is that nothing but comments moved: confirm the diff touches no executable lines, then build. If a build breaks after a comment pass, a load-bearing pragma or a Sourcery annotation was removed — restore it.
