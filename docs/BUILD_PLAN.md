# Swing — Build Plan

Last updated 2026-10-20. The git history lists every change to this plan.

Swing is a simple, cute macOS menu bar app for tracking work time. You start a timer when you begin working and tag what you're doing with categories that can be archived. Momo the monkey is the first character, and works alongside you in a small scene in the panel.

## Status

Update this section at the end of every working session: where things stand, then what comes next.

**Where we are (2026-10-20):** Milestone 1 is done. Swing is a menu bar app: the icon, or ⌃⌥S from any app, opens a panel with a stand-in timer (`TemporaryTracker`, in memory only, until TrackingService exists), and "Open Swing" opens a placeholder main window that brings the Dock icon with it. The idle and sleep spike is done: `ActivityMonitor` logs idle time every 30 seconds and every sleep, wake and display change (results under Risks and unknowns).

**Next:**

1. Start milestone 2: the Category and Session models and TrackingService.

## Guiding principles

- **Starting tracking takes one click.** No setup is required before the first timer. Categories are optional.
- **Only one thing is tracked at a time.** Starting something new ends whatever was running.
- **Everything is stored locally first,** with iCloud sync added on top in phase 2. There are no accounts or servers.
- **Pay once, no subscription, sold directly from Swing's website.**
- **Mac first, but set up for iPhone from day one.**

## Version 1 scope (Mac)

**In:**

- Start and stop from the menu bar
- Pick or switch a category, and add an optional short note about what you're doing
- Today's running total
- A Momo scene in the panel: Momo works alongside you (gardening, cooking, cleaning, painting) and naps when the timer isn't running. Scenes rotate; seasonal scenes come later
- Idle and sleep handling
- Archivable categories
- A simple history view with a breakdown chart
- A desktop widget
- Launch at login

**Out, for now:** iCloud sync (phase 2; the data model is built to allow it), projects inside categories, tags, billing and rates, report exports, a daily end time and goals, changing a running session's start time from the panel (for example, "I started 30 minutes ago"), pomodoro timers, automatic activity tracking, and the iPhone app (phase 2).

## Data model

Every property has a default or is optional, and nothing uses unique constraints, so iCloud sync (CloudKit) can be turned on in phase 2 without reshaping the data.

**Category**

| Property | Type | Notes |
| --- | --- | --- |
| id | UUID | |
| name | String | |
| colorHex | String | |
| sortOrder | Int | |
| isArchived | Bool | Hidden from the picker, kept in history |
| createdAt | Date | |
| sessions | [Session]? | Optional, for CloudKit |

**Session**

| Property | Type | Notes |
| --- | --- | --- |
| id | UUID | |
| start | Date | |
| end | Date? | No end means it's still running |
| category | Category? | None means the default category, shown as "General" |
| note | String? | |
| deviceName | String | Mac name on macOS; on iPhone, iOS returns only "iPhone", so use a user-set name there |

Small settings go in `UserDefaults`: the idle threshold, launch at login, and the current scene. A future end time setting can use `NSUbiquitousKeyValueStore` later so it syncs between devices.

Elapsed time is always calculated as `(end ?? now) - start`. The app never keeps a counter in memory.

Settle the model before deploying the CloudKit schema to production (phase 2). Once the CloudKit schema is deployed to production, fields can be added but never removed or renamed.

## Architecture

One Xcode project with separate macOS and iOS targets (not Xcode's single-target Multiplatform template), with shared logic in a Swift package (SwingKit) that every target uses.

```
(repo root)
├── CLAUDE.md                instructions for Claude (kept out of git)
├── docs/BUILD_PLAN.md       this plan
└── Swing/
    ├── Swing.xcodeproj      the Xcode project: open this
    ├── Swing/               macOS app target: menu bar item and panel, history window, settings
    ├── SwingTests/          unit tests (Swift Testing)
    ├── SwingUITests/        UI tests
    ├── SwingKit/            Swift package with the shared logic, used by every target (`import SwingKit`)
    │   ├── Sources/SwingKit/    ElapsedTime now. Later: Models (Category, Session), TrackingService,
    │   │                        Stats (totals by day and category), Intents (App Intents)
    │   └── Tests/SwingKitTests/ unit tests (Swift Testing)
    ├── Widgets/             not created yet. WidgetKit extension (Mac now, iOS later)
    └── iOS/                 phase 2
```

- **Swing is a menu bar app:** a normal installable Mac app that lives as an icon in the top menu bar. The menu bar item is just an icon (later the character); clicking it opens the panel with the full UI.
- **Menu bar panel:** a custom borderless, rounded window (`MenuBarPanel`) with the menu background, not `NSPopover`. A popover always has an arrow, and it re-positions itself whenever the menu bar item changes size; macOS resizes the item in two steps (first growing to the right, then sliding it back about a second later), so the popover ended up in the wrong place. The panel is placed once under the icon and closes on a click elsewhere, Esc, switching apps, or clicking the icon. It has `hidesOnDeactivate` off, because macOS doesn't always make Swing the active app when the icon is clicked, and the panel would otherwise open hidden. The time next to the menu bar icon was taken out for now; bringing it back means putting the icon on the right of the time so the icon doesn't move.
- **Main window and Dock icon:** history, stats and settings live in a main window, opened from the panel. The Dock icon (and ⌘-Tab entry) shows only while the main window is open, by switching `NSApp.setActivationPolicy` between `.accessory` and `.regular`. The panel can open on top of the main window; clicking into the main window closes the panel, like a menu. Closing the main window never quits the app, and clicking the Dock icon with no window open reopens it. Quit lives in the main window (and ⌘Q while it's open), not the panel, where it was too easy to hit by accident.
- **TrackingService** is the only code that creates or ends sessions. The UI, the widget, and Shortcuts all go through it.
- **App Group:** the widget runs as a separate process, so the SwiftData store lives in a shared App Group container that both can read.
- **Minimum macOS 15.** SwiftData first shipped in macOS 14 but had known bugs there (see Risks and unknowns).

**Tech stack:**

| Need | Choice | Confidence |
| --- | --- | --- |
| Language and UI | Swift, SwiftUI | High |
| Menu bar item and panel | AppKit `NSStatusItem` + a custom borderless panel hosting SwiftUI views. `MenuBarExtra` still can't open from code (Apple's docs, checked 2026-09-25) | High: decided in the milestone 1 spike |
| Storage and sync | SwiftData now; CloudKit private database for sync in phase 2 | High for storage, medium for sync behaviour |
| Charts | Swift Charts | High |
| Widget | WidgetKit with App Intents buttons | Medium: shared-store writes need testing |
| Shortcuts and Spotlight | App Intents | High |
| Global hotkey | KeyboardShortcuts package by sindresorhus | High |
| Launch at login | `SMAppService` | High |
| Notifications | UserNotifications | High |
| Idle and sleep | `CGEventSource` idle time, `NSWorkspace` sleep and wake notifications | High: confirmed in the milestone 1 spike |
| Signing and distribution | Developer ID signing, Hardened Runtime, Apple notarization, shipped as a DMG | High |
| Updates | Sparkle (sparkle-project.org) | High |
| Payments and licences | A merchant of record such as Paddle or Lemon Squeezy, which handles sales tax and issues licence keys | Medium: compare fees and licence features before choosing |

Outside the Mac App Store, App Sandbox is optional but Hardened Runtime is required for notarization. Keep the sandbox on unless it blocks something, so moving to the App Store later stays possible.

## Project setup

Facts about how the project is set up. Change these only when the setup itself changes.

**Identifiers:**

| What | Value | Notes |
| --- | --- | --- |
| Organization identifier | `com.emmalu` | Based on the owner's name. No website or domain is needed |
| Bundle ID | `com.emmalu.Swing` | Don't change it: macOS names the app's data folder after it, so changing it makes existing data seem to disappear |
| Extension bundle IDs | Start with `com.emmalu.Swing.`, for example `com.emmalu.Swing.Widget` | Apple requires extensions to use the app's bundle ID as a prefix |
| App Group | `group.com.emmalu.swing` | The shared data folder for the app and the widget. Set in `Swing/Swing/Swing.entitlements` |
| iCloud container | `iCloud.com.emmalu.swing` (planned for phase 2, not created) | Can never be deleted or renamed once created |
| Apple team | Free Personal Team, Team ID `JU74583U8M` | Likely changes when enrolling in the paid program (not confirmed). If so, pick the new team in Signing & Capabilities |
| GitHub repo | `eemmalu/swing`, private | |

**Build settings:**

- Created with Xcode 26.6 (Swift 6.3 compiler) on macOS 26.4.
- Minimum macOS 15.0 for the app. The test targets use 26.4, which is fine because tests only run on the development Mac.
- Swift 5 language mode, with Xcode 26's new-project defaults: "Approachable Concurrency" on, and code runs on the main thread unless marked otherwise (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). This avoids most concurrency errors while learning.
- `MemberImportVisibility` is on: a file must import the module a name comes from, even if another file already imports it (for example, AppKit for `.control` and `.option`).
- There's no `Info.plist` file. Xcode generates it from build settings, so Info.plist keys are added as `INFOPLIST_KEY_…` build settings or in the target's Info tab. Hiding the Dock icon, for example, is `INFOPLIST_KEY_LSUIElement = YES`.
- App Sandbox and Hardened Runtime are build settings (`ENABLE_APP_SANDBOX`, `ENABLE_HARDENED_RUNTIME`), shown in Signing & Capabilities. Only the App Group is in the entitlements file.
- The project uses synchronized folders: any file added inside `Swing/Swing/` on disk automatically becomes part of the app, with no project file edit.
- SwingKit (`Swing/SwingKit/`) is a local Swift package: platforms macOS 15 and iOS 18, Swift 5 mode, main-thread default and Approachable Concurrency, all set in its `Package.swift` to match the app. It's added to the project as a folder in the sidebar (not through Add Package Dependencies), because only then does Xcode let its tests into the Swing scheme. Only code marked `public` is visible to the apps.
- Outside packages: KeyboardShortcuts (`https://github.com/sindresorhus/KeyboardShortcuts`), up to next major from 3.1.0, linked to the app target only. The exact version is pinned in `Package.resolved`, which is committed.
- The Swing scheme is shared (saved in the repo) and its Test action runs the SwingKit tests plus the app's unit tests. In Xcode: ⌘U. The UI tests (`SwingUITests`) are switched off in the scheme: they're still Xcode's starter examples, and they take over the screen ("Automation Running") for minutes. Turn them back on (Edit Scheme → Test) once the panel is worth testing that way.

**Working on the project:**

- Build from the terminal: `xcodebuild -project Swing/Swing.xcodeproj -scheme Swing -configuration Debug -derivedDataPath .context/DerivedData -allowProvisioningUpdates build`
- Test SwingKit alone, fast: `swift test` inside `Swing/SwingKit`. Everything: the same xcodebuild command with `-destination 'platform=macOS,arch=arm64' test`. When the UI tests are back on: the launch test is slow and once failed with "has not loaded accessibility", then passed on the rerun.
- Close Xcode before an agent edits `project.pbxproj` or the entitlements file, or Xcode may overwrite the changes.
- If Xcode shows "Missing package product 'SwingKit'" (seen after adding a package), use File → Packages → Reset Package Caches, or restart Xcode. The project itself is fine.
- The repo lives at `~/Dev/swing`. Open the Xcode project from there.
- Work and commit directly on `main`. Push to GitHub only after the owner has reviewed the commit and said OK. No feature branches or pull requests: the owner is the only developer.

## Risks and unknowns

These are the parts I'm least sure about. Each gets checked early, before the code depends on it.

| Unknown | Why it matters | How to check | When |
| --- | --- | --- | --- |
| Recent OS changes | My knowledge stops at May 2026. The macOS and iOS releases since then may have changed MenuBarExtra, SwiftData or widgets | Skim the WWDC 2026 "What's new" notes for SwiftUI, SwiftData and WidgetKit. Partly checked 2026-09-22: found no new official way to open `MenuBarExtra` from code. SwiftData reportedly gained `HistoryObserver` (reacting to synced changes, useful in phase 2), probably only on the newest macOS; not yet confirmed in Apple's docs. Xcode 27 is out; the project was created with Xcode 26.6 | Before milestone 1 |
| Showing the Dock icon only while the main window is open | Switching the activation policy at runtime is reported to be glitchy | Resolved 2026-09-25: works on macOS 26, tested by the owner | Milestone 1 |
| Idle detection | I believe `CGEventSource` idle time works without extra permission, even in the sandbox, but I haven't confirmed it | Resolved 2026-10-20 on macOS 26, in the signed, sandboxed app: idle time works with no permission prompt and keeps counting while the display is off. Sleep, wake and display notifications all arrive (only through `NSWorkspace.shared.notificationCenter`). Idle time does **not** include time asleep: it is about 0 on waking, since waking takes input. Locking the screen is not tested yet | Milestone 1 |
| iCloud sync outside the App Store | I believe CloudKit works for Developer ID apps outside the App Store, but I haven't confirmed the current setup steps | Spike: sync one record from a notarized, Developer ID-signed build | Before phase 2 |
| Minimum macOS | SwiftData on macOS 14 had bugs that were fixed later. Requiring a newer version shrinks the audience a little | Confirmed 2026-10-20: macOS 15.0. Nothing in the spikes needs newer, and the app builds for 15. Only run on macOS 26 so far, so test on 15 before beta (milestone 8) | Milestone 1 |
| Widget and app writing the same store | A widget button that stops the timer writes from a second process. SwiftData's handling of that with CloudKit on top is the part I'm least sure of | Test start and stop from both in milestone 7, then again with sync on in phase 2 | Milestone 7 and phase 2 |
| iPhone app pricing | The iPhone app must go through the App Store. App Store rules on unlocking features with a licence bought elsewhere are strict, and I'm not sure what's allowed | Read the current App Review Guidelines on payments; the safe option is a free companion app or a separate App Store price | Before phase 2 |
| Resolving two running sessions | SwiftData has no merge hook. The fix is a cleanup pass whenever synced changes arrive, and I'm not sure how cleanly SwiftData reports those | Prototype with two Macs or a Mac and a simulator | Phase 2 |
| CloudKit sync speed | Sync usually takes seconds but can take minutes, so "stop on phone" may lag on the Mac | Measure it on real devices | Phase 2 |
| Live Activity started from the Mac | Starting a Live Activity on the iPhone when tracking began on the Mac needs push notifications from a server, which conflicts with "no servers" | Decide whether it only appears when tracking starts on the phone | Phase 2 |
| Paid developer account | Selling outside the App Store still needs the $99/year Apple Developer Program, for Developer ID signing, notarization and iCloud. Building and running on your own Mac works with a free account | Enroll a few days before sharing builds with testers, since approval can take time | Milestone 8 |
| App Group on a free account | The widget reads the data from a shared App Group folder. I'm not sure a free account can set one up on macOS. If not, the data starts in the app's own folder and must be moved later, which needs careful migration code | Resolved 2026-09-22: works. With a free account, Xcode created a provisioning profile that includes `group.com.emmalu.swing`, and the signed app launched | Milestone 1 |

## Milestones

Each milestone leaves you with an app that works. Compared with the first draft, the risky menu bar questions are tested first, and idle handling and history move earlier because they decide whether you can trust the numbers.

### 1. Project setup and spike (a weekend)

The spike is written as real code to keep and tidy up, not thrown away.

- [x] Create an Xcode project with a macOS app target and an App Group, with Hardened Runtime and App Sandbox on (a free Apple account is enough)
- [x] Add the shared package (SwingKit) and connect it to the app
- [x] Spike: menu bar item that opens a panel, and a main window that shows the Dock icon only while it's open
- [x] Decide `MenuBarExtra` or `NSStatusItem`: `NSStatusItem` with a custom panel
- [x] Spike: panel opened from a global hotkey: ⌃⌥S via the KeyboardShortcuts package, works with App Sandbox on
- [x] Spike: idle seconds and sleep/wake logged (`ActivityMonitor`)
- [x] Confirm the minimum macOS: 15.0

### 2. Core tracking

- [ ] Write the Category and Session models following CloudKit's rules (every property has a default or is optional, no unique constraints), so sync can be turned on in phase 2
- [ ] Write TrackingService: start, stop, switch, and the one-active-session rule
- [ ] Unit test the time math, especially sessions that cross midnight

### 3. Menu bar panel

- [ ] Layout, top to bottom: timer, current category with its color, note field ("What are you working on?"), stop/start button, Momo scene, then Open history and Settings
- [ ] Category switcher that opens from the current category. Before starting, it only sets the category; while running, it ends the session and starts a new one with an empty note
- [ ] Momo scenes as simple animations, rotating between them. When the timer isn't running, Momo naps on a pillow with floating Z's
- [ ] Not-started state: 0:00:00 in a muted color with a Start button. Stop returns here

### 4. Idle and sleep

- [ ] Detect sleep and wake, and no input past a threshold (for example, 10 minutes). Idle time resets on waking, so time away across a sleep is the idle time when sleep began plus the time asleep: record idle time in `willSleep`. Remove the spike's 30-second idle log
- [ ] On return, ask: "You were away 47 min. Keep, discard, or stop at when you left?"

### 5. History and editing

- [ ] Day list of sessions in the app's history window, with edit (times, category, note), delete, and add a session manually
- [ ] Day and week breakdown with Swift Charts, showing time per category

### 6. Categories

- [ ] Add, edit, and reorder categories, each with a color
- [ ] Archive and unarchive (hidden from the picker, kept in history)

### 7. Widget and shortcuts

- [ ] Desktop widget with a live timer and a start/stop button
- [ ] App Intents so Shortcuts and Spotlight can start and stop tracking
- [ ] Global keyboard shortcut to start and stop

### 8. Polish and release

- [ ] Enroll in the Apple Developer Program early in this milestone (needed for Developer ID signing and notarization; approval can take a few days)
- [ ] Launch at login and a first run that just works
- [ ] App icon and character design
- [ ] Automated release build: sign with Developer ID, notarize, package as a DMG
- [ ] Sparkle for automatic updates
- [ ] Payments and licence keys through a merchant of record, with a free trial
- [ ] Simple website with the download, price and privacy note
- [ ] Run the app on macOS 15 (a second Mac or a macOS 15 virtual machine), since it has only run on 26 so far
- [ ] Beta test by sharing notarized builds directly (TestFlight is for App Store apps)

## Phase 2: iPhone and more

The iPhone app reuses the SwingKit package, so most of the work is a new phone layout.

- [ ] iPhone app on the same SwingKit package
- [ ] Live Activity on the Lock Screen and Dynamic Island (without a server, it only appears when tracking starts on the phone)
- [ ] Control Center button, Lock Screen widgets, and Action button support
- [ ] Turn on iCloud sync (CloudKit) and test starting on one device and stopping on the other
- [ ] Deploy the CloudKit schema to production (after this, fields can only be added)
- [ ] Decide iPhone pricing: universal purchase only works when both apps are sold through the App Store, so choose a free companion app or a separate App Store price
- [ ] Later, possibly an Apple Watch app

**Characters:** users choose a companion in settings, starting with Momo. Each character has a few expressions: idle, working, nearly done, finished.

## Edge cases

- **Two running sessions after a sync (phase 2).** If each device started one while offline, keep the newer one and end the older one at the moment the newer one started.
- **Sessions crossing midnight** are split into separate days in reports, but stay as one session in storage.
- **Time zone changes and travel.** Store times as absolute dates and convert to local time only for display.
- **The app quits or crashes while tracking.** Nothing is lost, because a running session is just a stored start time with no end.
- **Edited or added times that overlap another session.** Trim the neighbouring session to fit, and show what changed so it can be undone.

## Open questions

- [x] App name: **Swing**, with **Momo** the monkey as the first character. More selectable characters come later. Still to do: run a trademark check.
- [x] End time and goals are left out of v1. When they're added, the end time only nudges and never stops the timer.
- [x] Distribution: a direct download from Swing's own website, not the Mac App Store.
- [x] Default category name: **General**, for now. It's only a display label, so it can change any time.
- [x] iCloud sync is out of v1 and comes in phase 2. The data model still follows CloudKit's rules.
- [x] Apple Developer Program: a free account until milestone 8, when builds are shared.
- [x] App identifiers use the owner's name (`com.emmalu`). See Project setup.
