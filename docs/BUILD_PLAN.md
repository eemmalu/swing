# Swing — Build Plan

Last updated 2026-09-21 (revised: emoji removed, tech stack reviewed, build order changed, direct distribution, end time out of v1, Momo scenes). Live version: https://claude.ai/code/artifact/7484dedd-756d-468a-a7b4-bec73e847de4

Swing is a simple, cute macOS menu bar app for tracking work time. You start a timer when you begin working and tag what you're doing with categories that can be archived. Momo the monkey is the first character, and works alongside you in a small scene in the panel.

## Guiding principles

- **Starting tracking takes one click.** No setup is required before the first timer. Categories are optional.
- **Only one thing is tracked at a time.** Starting something new ends whatever was running.
- **Everything is stored locally first,** with iCloud sync on top. There are no accounts or servers.
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

**Out, for now:** projects inside categories, tags, billing and rates, report exports, a daily end time and goals, changing a running session's start time from the panel (for example, "I started 30 minutes ago"), pomodoro timers, automatic activity tracking, and the iPhone app (phase 2).

## Data model

Every property has a default or is optional, and nothing uses unique constraints, so the model works with CloudKit sync from the start.

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

Settle the model before the first TestFlight build. Once the CloudKit schema is deployed to production, fields can be added but never removed or renamed.

## Architecture

One multiplatform Xcode project, with shared logic in a Swift package that every target uses.

```
Swing/
├── Shared/                ← Swift package, used by every target
│   ├── Models/            Category, Session
│   ├── TrackingService    start / stop / switch, one active session
│   ├── Stats              totals by day and category, split at midnight
│   └── Intents/           App Intents: Start, Stop, Switch Category
├── macOS/                 MenuBarExtra popover, history window, settings
├── Widgets/               WidgetKit extension (Mac now, iOS later)
└── iOS/                   empty for now
```

- **Swing is a menu bar app:** a normal installable Mac app that lives as an icon in the top menu bar (no Dock icon by default, via `LSUIElement`). The menu bar item shows the character and a live timer; clicking it opens the popover with the full UI.
- **TrackingService** is the only code that creates or ends sessions. The UI, the widget, and Shortcuts all go through it.
- **App Group:** the widget runs as a separate process, so the SwiftData store lives in a shared App Group container that both can read.
- **Minimum macOS 14,** the first version with SwiftData. Consider macOS 15 instead: SwiftData on macOS 14 had known bugs (see Risks and unknowns).

**Tech stack:**

| Need | Choice | Confidence |
| --- | --- | --- |
| Language and UI | Swift, SwiftUI | High |
| Menu bar item and popover | SwiftUI `MenuBarExtra`, or AppKit `NSStatusItem` + `NSPopover` if it falls short | Medium: decide in the milestone 1 spike |
| Storage and sync | SwiftData, CloudKit private database | High for storage, medium for sync behaviour |
| Charts | Swift Charts | High |
| Widget | WidgetKit with App Intents buttons | Medium: shared-store writes need testing |
| Shortcuts and Spotlight | App Intents | High |
| Global hotkey | KeyboardShortcuts package by sindresorhus | High |
| Launch at login | `SMAppService` | High |
| Notifications | UserNotifications | High |
| Idle and sleep | `CGEventSource` idle time, `NSWorkspace` sleep and wake notifications | Medium: check it in the spike |
| Signing and distribution | Developer ID signing, Hardened Runtime, Apple notarization, shipped as a DMG | High |
| Updates | Sparkle (sparkle-project.org) | High |
| Payments and licences | A merchant of record such as Paddle or Lemon Squeezy, which handles sales tax and issues licence keys | Medium: compare fees and licence features before choosing |

Outside the Mac App Store, App Sandbox is optional but Hardened Runtime is required for notarization. Keep the sandbox on unless it blocks something, so moving to the App Store later stays possible.

## Risks and unknowns

These are the parts I'm least sure about. Each gets checked early, before the code depends on it.

| Unknown | Why it matters | How to check | When |
| --- | --- | --- | --- |
| Recent OS changes | My knowledge stops at May 2026. The macOS and iOS releases since then may have changed MenuBarExtra, SwiftData or widgets | Skim the WWDC 2026 "What's new" notes for SwiftUI, SwiftData and WidgetKit | Before milestone 1 |
| `MenuBarExtra` limits | As far as I know, there's no official way to open its popover from code. The idle prompt and the global hotkey both need that. It also has no right-click handling | Spike: open the popover from a hotkey | Milestone 1 |
| Live timer in the menu bar | Updating the menu bar label every second can be unreliable with `MenuBarExtra` | Spike: show a ticking timer in the label | Milestone 1 |
| Idle detection | I believe `CGEventSource` idle time works without extra permission, even in the sandbox, but I haven't confirmed it | Spike: log idle seconds in a signed build | Milestone 1 |
| iCloud sync outside the App Store | I believe CloudKit works for Developer ID apps outside the App Store, but I haven't confirmed the current setup steps | Spike: sync one record from a notarized, Developer ID-signed build | Milestone 1 |
| Minimum macOS | SwiftData on macOS 14 had bugs that were fixed later. Requiring a newer version shrinks the audience a little | Pick macOS 15 unless the spike shows a reason to go higher | Milestone 1 |
| Widget and app writing the same store | A widget button that stops the timer writes from a second process. SwiftData's handling of that with CloudKit on top is the part I'm least sure of | Test start and stop from both, with sync on | Milestone 7 |
| iPhone app pricing | The iPhone app must go through the App Store. App Store rules on unlocking features with a licence bought elsewhere are strict, and I'm not sure what's allowed | Read the current App Review Guidelines on payments; the safe option is a free companion app or a separate App Store price | Before phase 2 |
| Resolving two running sessions | SwiftData has no merge hook. The fix is a cleanup pass whenever synced changes arrive, and I'm not sure how cleanly SwiftData reports those | Prototype with two Macs or a Mac and a simulator | Phase 2 |
| CloudKit sync speed | Sync usually takes seconds but can take minutes, so "stop on phone" may lag on the Mac | Measure it on real devices | Phase 2 |
| Live Activity started from the Mac | Starting a Live Activity on the iPhone when tracking began on the Mac needs push notifications from a server, which conflicts with "no servers" | Decide whether it only appears when tracking starts on the phone | Phase 2 |
| Paid developer account | Selling outside the App Store still needs the $99/year Apple Developer Program, for Developer ID signing, notarization and iCloud | Enroll before milestone 1 | Before milestone 1 |

## Milestones

Each milestone leaves you with an app that works. Compared with the first draft, the risky menu bar and sync questions are tested first, and idle handling and history move earlier because they decide whether you can trust the numbers.

### 1. Project setup and spike (a weekend)

- [ ] Enroll in the Apple Developer Program (needed for signing, notarization and iCloud)
- [ ] Create a multiplatform Xcode project, the Shared package, an App Group, and an iCloud container, with Hardened Runtime and App Sandbox on
- [ ] Spike: menu bar item with a ticking timer, popover opened from a hotkey, idle seconds logged, one record synced through iCloud from a notarized build
- [ ] Decide `MenuBarExtra` or `NSStatusItem` from the spike, and set the minimum macOS

### 2. Core tracking

- [ ] Write the Category and Session models, with CloudKit turned on in development so incompatible models fail early
- [ ] Write TrackingService: start, stop, switch, and the one-active-session rule
- [ ] Unit test the time math, especially sessions that cross midnight

### 3. Menu bar popover

- [ ] Layout, top to bottom: timer, current category with its color, note field ("What are you working on?"), stop/start button, Momo scene, then Open history and Settings
- [ ] Category switcher that opens from the current category. Before starting, it only sets the category; while running, it ends the session and starts a new one with an empty note
- [ ] Momo scenes as simple animations, rotating between them. When the timer isn't running, Momo naps on a pillow with floating Z's
- [ ] Not-started state: 0:00:00 in a muted color with a Start button. Stop returns here. The menu bar item shows the elapsed time only while tracking

### 4. Idle and sleep

- [ ] Detect sleep and wake, and no input past a threshold (for example, 10 minutes)
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

- [ ] Launch at login and a first run that just works
- [ ] App icon and character design
- [ ] Automated release build: sign with Developer ID, notarize, package as a DMG
- [ ] Sparkle for automatic updates
- [ ] Payments and licence keys through a merchant of record, with a free trial
- [ ] Simple website with the download, price and privacy note
- [ ] Deploy the CloudKit schema to production (after this, fields can only be added)
- [ ] Beta test by sharing notarized builds directly (TestFlight is for App Store apps)

## Phase 2: iPhone and more

The iPhone app reuses the Shared package, so most of the work is a new phone layout.

- [ ] iPhone app on the same Shared package
- [ ] Live Activity on the Lock Screen and Dynamic Island (without a server, it only appears when tracking starts on the phone)
- [ ] Control Center button, Lock Screen widgets, and Action button support
- [ ] Turn on CloudKit sync and test starting on one device and stopping on the other
- [ ] Decide iPhone pricing: universal purchase only works when both apps are sold through the App Store, so choose a free companion app or a separate App Store price
- [ ] Later, possibly an Apple Watch app

**Characters:** users choose a companion in settings, starting with Momo. Each character has a few expressions: idle, working, nearly done, finished.

## Edge cases

- **Two running sessions after a sync.** If each device started one while offline, keep the newer one and end the older one at the moment the newer one started.
- **Sessions crossing midnight** are split into separate days in reports, but stay as one session in storage.
- **Time zone changes and travel.** Store times as absolute dates and convert to local time only for display.
- **The app quits or crashes while tracking.** Nothing is lost, because a running session is just a stored start time with no end.
- **Edited or added times that overlap another session.** Trim the neighbouring session to fit, and show what changed so it can be undone.

## Open questions

- [x] App name: **Swing**, with **Momo** the monkey as the first character. More selectable characters come later. Still to do: run a trademark check.
- [x] End time and goals are left out of v1. When they're added, the end time only nudges and never stops the timer.
- [x] Distribution: a direct download from Swing's own website, not the Mac App Store.
- [x] Default category name: **General**, for now. It's only a display label, so it can change any time.
