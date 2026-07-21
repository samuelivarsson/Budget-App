# Budget — project notes

## Versioning

Version fields live in `Budget.xcodeproj/project.pbxproj`:

- `MARKETING_VERSION` — user-facing version (e.g. `2.0`).
- `CURRENT_PROJECT_VERSION` — build number (e.g. `6`).

Both must be **identical across every target** (main app + widget extensions +
tests). App Store Connect rejects an upload if an extension's version/build
doesn't match the app. After changing them, verify every config matches:

```bash
grep -o "MARKETING_VERSION = [0-9.]*" Budget.xcodeproj/project.pbxproj | sort | uniq -c
grep -o "CURRENT_PROJECT_VERSION = [0-9]*" Budget.xcodeproj/project.pbxproj | sort | uniq -c
```

The **build number must be unique and strictly increasing** for each
TestFlight / App Store upload — never reuse a build number that's already been
uploaded.

Minimum deployment target is **iOS 26** (`IPHONEOS_DEPLOYMENT_TARGET`).

## Release flow (feature branch → master)

1. Do all functional / project changes (including any `IPHONEOS_DEPLOYMENT_TARGET`
   bump) on the feature branch — these are not release metadata.
2. Merge into `master` with a merge commit:
   `git checkout master && git merge --no-ff <feature-branch>`
3. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` (all targets) as the
   **last commit before tagging**, so the tagged commit's version matches the tag.
   A major redesign warrants a major bump (e.g. `2.0`).
4. Tag that commit: `git tag -a vX.Y -m "X.Y"`.

Keep release bookkeeping (version/build bump) out of feature commits — bump once
at the release point, not scattered across branches.

## Pushing (the user does this, not Claude)

- **Never push from Claude.** Leave commits and tags local and report what's ready.
- The user pushes with either:
  - `git push --follow-tags`, or equivalently
  - `git push` then `git push origin tag vX.Y`
- Never add Claude / AI attribution (`Co-Authored-By`, "Generated with…") to
  commit messages or PR descriptions.

## Build / test

```bash
xcodebuild -project Budget.xcodeproj -scheme Budget \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build   # or: test
```

SourceKit frequently shows false errors for these files (e.g. "No such module
'Firebase'", "Cannot find type 'UserViewModel'"). Trust a clean `xcodebuild`
over the editor diagnostics.
