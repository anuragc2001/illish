# Illish — Bugs, Edge Cases & Enhancement Opportunities

> **Last Audit Date**: 2026-08-08
> **Scope**: Full `lib/` directory review
> **Status**: Documentation only — no code changes made

---

## 🔴 Critical (Crash / Data Loss Risk)

### ~~BUG-001: `NotificationService.unreadCount` creates a new leaked `ValueNotifier` on every access~~

**File**: `lib/services/notification_service.dart`
**Status**: ✅ FIXED

**Resolution**: `unreadCount` is now a singleton `ValueNotifier<int>` field initialized once in `NotificationService._internal()`, preventing memory leaks on frame rebuilds.

**Problem**: The `unreadCount` getter creates a **new** `ValueNotifier<int>` and adds a **new listener** to `notifications` every time it is called. In `camera_screen.dart`, this getter is called inside a `ValueListenableBuilder` in the `build()` method, which runs on every frame rebuild. This causes:

1. **Unbounded memory leak** — every rebuild allocates a new `ValueNotifier` and its listener is never removed.
2. **Cascading re-renders** — each listener fires `setState`-equivalent updates, causing more rebuilds.

**Suggested Fix**: Cache `unreadCount` as a field initialized once in the constructor, not as a getter.

```dart
// Instead of:
ValueNotifier<int> get unreadCount { ... }

// Use:
late final ValueNotifier<int> unreadCount = ValueNotifier<int>(notifications.value.length);
// And attach listener once in constructor
```

---

### ~~BUG-002: `_cleanupImageIfUnused` runs inside `writeTxn` but calls `existsSync` / `deleteSync`~~

**File**: `lib/services/db_service.dart`
**Status**: ✅ FIXED

**Resolution**: Image cleanup and cloud archiving operations are now performed outside of `isar.writeTxn()` in `saveScan()`, preventing main-thread blocking during database transactions.

**Problem**: `_cleanupImageIfUnused` is called from within `isar.writeTxn()` in `saveScan()` (line 151). The method performs blocking file I/O (`existsSync`, `deleteSync`) on the main isolate **inside** an Isar write transaction. On slow storage (e.g., older iPhones), this can block the UI thread and cause jank or ANRs.

**Suggested Fix**: Collect image paths to clean up, and perform file deletion **after** the transaction completes.

---

### ~~BUG-003: `updateDailyAggregate` called inside `writeTxn` but opens its own query~~

**File**: `lib/services/db_service.dart`
**Status**: ✅ FIXED

**Resolution**: Wrapped `dailyScanAggregates.put` with `if (isar.isInTxn)` check to safely execute within existing transactions without opening nested transactions or failing standalone calls.

**Problem**: `updateDailyAggregate` internally calls `isar.dailyScanAggregates.filter().dateEqualTo(dateKey).findFirst()`. When `updateDailyAggregate` is called from within `saveScan`'s `writeTxn`, this read-inside-write-transaction pattern is safe in Isar, but the method also calls `isar.dailyScanAggregates.put(aggregate)` (line 429) **without** being in a transaction when called standalone. This creates **nested transaction potential** in certain call paths from `SyncService.syncFromCloudToLocal` where it's called inside another `writeTxn`.

**Impact**: May silently fail or deadlock on certain Isar versions.

---

## 🟠 High (Functional Bug)

### BUG-004: `AppNotificationModel.time` field stored in Isar but never used

**File**: `lib/core/models/app_notification_model.dart` Line 15
**Status**: 🟡 OPEN

**Problem**: The `time` field is declared in the model and included in Isar schema generation, but `AppNotification.fromModel()` at `notification_service.dart` Line 40 computes `time` dynamically via `_formatTimeAgo(model.timestamp)` and ignores the stored `time` value. This field wastes schema space and could confuse future developers.

---

### ~~BUG-005: `_loadFromLocal` in `NotificationService` filters by `isCleared` never applied~~

**File**: `lib/services/notification_service.dart` / `lib/services/db_service.dart`
**Status**: ✅ FIXED

**Resolution**: Updated `DBService.getNotifications()` to apply `.filter().isClearedEqualTo(false)` so cleared notifications are never returned from local storage.

**Problem**: `DBService.getNotifications()` fetches **all** `AppNotificationModel` records without filtering out `isCleared == true`. The `markNotificationCleared` method deletes the record entirely, so this is currently benign — but if the deletion ever changes to a soft-delete (setting `isCleared = true` instead of deleting), cleared notifications would re-appear.

---

### ~~BUG-006: `SyncService.upsertScanRecord` called fire-and-forget inside `writeTxn`~~

**File**: `lib/services/db_service.dart` Line 134
**Status**: ✅ FIXED

**Resolution**: Moved `SyncService.upsertScanRecord(record)` outside of `isar.writeTxn` in `saveScan` and safely `await`ed it. This ensures Firebase sync failures can be caught without blocking the local database write thread.

**Problem**: `SyncService.upsertScanRecord(record)` is called inside the `isar.writeTxn()` closure but is **not awaited**. This means:
- If the sync fails, the error is silently swallowed.
- The record's `isSynced` flag is never set to `true` after local save (it stays `false` forever until `syncLocalToCloud` runs).
- The Firestore write may execute concurrently with subsequent Isar operations.

---

### ~~BUG-007: `_firebaseMessagingBackgroundHandler` re-initializes Firebase without options~~

**File**: `lib/main.dart`
**Status**: ✅ FIXED

**Resolution**: Passed `options: DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp()` inside `_firebaseMessagingBackgroundHandler`.

**Problem**: The background handler calls `Firebase.initializeApp()` without passing `DefaultFirebaseOptions.currentPlatform`. On iOS, this can cause a crash if the default app hasn't been configured yet in the background isolate. The foreground `main()` correctly passes `options:` (line 102-103), but the background handler does not.

**Suggested Fix**:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

---

### ~~BUG-008: Premium status not persisted locally — lost on cold boot before Firestore listener attaches~~

**File**: `lib/config/app_config.dart` Lines 34-60
**Status**: ✅ FIXED

**Resolution**: `initOfflinePremiumState()` now loads `isPremium`, `premiumPlan`, and `premiumExpiry` from `SharedPreferences` on cold boot and validates the expiry date. This is called in `main()` before `runApp()`.

---

### ~~BUG-022: `_handleAction` payment gate triggers on very first scan (bypassCount 0)~~

**File**: `lib/screens/recognition_sheet.dart`
**Status**: ✅ FIXED

**Resolution**: Changed condition to `bypassCount > 0 && bypassCount % 3 == 0` so new users get initial free scans before being prompted for payment.

**Problem**: `bypassCount % 3 == 0` evaluates to `true` when `bypassCount` is `0` (fresh install or first-ever scan). This means the very first time a new user scans a fish, they are immediately shown the `PaymentScreen` instead of seeing the result — a terrible first-time user experience. Users should get at least 1-2 free scans before being prompted to pay.

**Suggested Fix**: Change to `bypassCount > 0 && bypassCount % 3 == 0` or start the counter at 1.

---

## 🟡 Medium (UX / Edge Case)

### ~~EDGE-009: Camera screen shows loading spinner forever if `cameras` list is empty and `availableCameras()` fails~~

**File**: `lib/screens/camera_screen.dart`
**Status**: ✅ FIXED

**Resolution**: Updated `_initCamera` to set `_isCameraError` when camera availability fails and display a clear 'Camera Unavailable' message instead of spinning indefinitely.

---

### ~~EDGE-010: `_processImage` uses `context` after `await` without rechecking `mounted`~~

**File**: `lib/screens/camera_screen.dart`
**Status**: ✅ FIXED

**Resolution**: Added `if (!mounted) return;` guard immediately prior to showing the recognition bottom sheet after `DBService.saveScan()`.

---

### EDGE-011: `payment_sheet_copy.dart` is a dead file

**Files**: `lib/screens/payment_sheet_copy.dart` (16KB)
**Status**: 🟡 OPEN

**Problem**: This file is an unused copy of `payment_sheet.dart` and is not imported anywhere. Note: `payment_sheet_single.dart` is intentionally kept as an experimental switching screen for the future.

---

### ~~EDGE-012: PhonePe `callbackUrl` hardcoded to `webhook.site` example URL~~

**Status**: ✅ RESOLVED — PhonePe SDK has been fully replaced by Razorpay SDK. No callback URL is needed.

---

### ~~EDGE-013: `print()` used instead of `debugPrint()` in payment_service.dart~~

**Status**: ✅ FIXED — All `print()` calls across the entire codebase have been replaced with `debugPrint()`. Zero bare `print()` statements remain.

---

### ~~EDGE-014: `_locationTimer` kept as dead code in `camera_screen.dart`~~

**File**: `lib/screens/camera_screen.dart`
**Status**: ✅ FIXED

**Resolution**: Removed deprecated `_locationTimer` variable and its cancel call.

**Problem**: `Timer? _locationTimer` is declared with comment "Deprecated, kept for reference if needed" and cancelled in `dispose()`. This is dead code that should be removed for clarity.

---

### ~~EDGE-015: `SyncService.archiveScanRecord` and `SyncService.upsertScanRecord` called fire-and-forget without error handling~~

**Files**: `lib/services/db_service.dart` Lines 134, 152, 244, 286, 298, 314, 331
**Status**: ✅ FIXED

**Resolution**: Updated all `SyncService` usages in `db_service.dart` (such as `clearAll`, `hideScan`, `deleteScan`) to be safely `await`ed outside of local Isar transactions.

**Problem**: Multiple fire-and-forget calls to `SyncService` methods. If these fail silently (e.g., user signed out mid-operation, network dropped), the local and cloud databases fall out of sync with no recovery mechanism.

---

### ~~EDGE-023: Dead constants in `app_config.dart` — `kEnableAds`, `geminiApiKey`, `youtubeApiKey`, `geminiModel`~~

**File**: `lib/config/app_config.dart` Lines 5-10
**Status**: ✅ FIXED

**Resolution**: These constants were entirely removed from `app_config.dart` during a previous cleanup. They no longer exist in the codebase.

**Problem**: The following fields in `AppConfig` are defined but **never referenced** by any file in the codebase:
- `geminiApiKey` — production code uses `RemoteConfigService.geminiApiKey.value`
- `youtubeApiKey` — production code uses `RemoteConfigService.youtubeApiKey.value`
- `geminiModel` — production code uses `RemoteConfigService.geminiModel.value`
- `kEnableAds` (via `bool.fromEnvironment('ENABLE_ADS')`) — ad gating now uses `AppConfig.isPremiumUser` checks

These orphaned constants contain **hardcoded API keys** in plain text, which is a security risk if the repo is ever made public. They should be removed to avoid confusion and potential key leakage.

---

### ~~EDGE-024: `showRewardedInterstitialAd` callbacks may fire after widget disposal~~

**File**: `lib/screens/recognition_sheet.dart`
**Status**: ✅ FIXED

**Resolution**: Replaced `Navigator.pop` + `Navigator.push` with atomic `Navigator.pushReplacement` inside `onRewardEarned` callback to eliminate context race conditions.

**Problem**: `AdMobService.showRewardedInterstitialAd` receives `onRewardEarned` and `onAdDismissedWithoutReward` closures that capture the `RecognitionSheet`'s `context` and call `mounted`, `Navigator.pop/push`, and `setState`. However, the ad is asynchronous — the user might press the back button or the system might pop the recognition sheet while the ad is still showing. When the ad's callback fires afterward:
- `setState(() => _isUnlocking = false)` will throw `"setState() called after dispose()"`.
- `Navigator.pop(context)` will use a stale context.

The `if (!mounted) return;` guard on lines 84 and 89 only partially protects — `Navigator.pop(context)` and `Navigator.push` after a `mounted` check could still race with the widget tree if another navigation event happens between the check and the call.

**Suggested Fix**: Use `WidgetsBinding.instance.addPostFrameCallback` or store a `GlobalKey<NavigatorState>` to safely navigate from ad callbacks.

---

## 🟢 Low (Enhancement / Polish)

### ENH-016: `IllishApp` is a `StatelessWidget` — cannot react to runtime changes

**File**: `lib/main.dart` Lines 201-214
**Status**: 🟡 OPEN

**Suggestion**: If features like dynamic theming, locale switching, or deep-link routing are planned, `IllishApp` should be converted to a `StatefulWidget` or wrapped with a state management solution.

---

### ~~ENH-017: No error boundary / global error handler~~

**File**: `lib/main.dart`
**Status**: ✅ FIXED

**Resolution**: Added `FlutterError.onError` and `PlatformDispatcher.instance.onError` top-level error handlers in `main()` to safely intercept uncaught asynchronous and framework exceptions.

**Problem**: The app has no `FlutterError.onError` or `runZonedGuarded` wrapper in `main()`. Unhandled exceptions in async code or widget build will show grey/red error screens in production.

**Suggestion**: Add a global error handler that catches and logs crashes (e.g., Crashlytics) and shows a user-friendly fallback UI.

---

### ENH-018: `DailyScanAggregate.fishCounts` uses string serialization instead of proper types

**File**: `lib/core/models/daily_scan_aggregate.dart` Line 19
**Status**: 🟡 OPEN

**Problem**: `fishCounts` stores data as `List<String>` with format `"FishName:Count"`, requiring manual splitting and parsing everywhere it's accessed. This is fragile — names containing `:` would break the parser.

**Suggestion**: Consider using an embedded Isar object or a JSON string field with proper serialization.

---

### ENH-019: No pagination guard in `ProfileScreen._loadAnalytics`

**File**: `lib/screens/profile_screen.dart`
**Status**: 🟡 OPEN

**Problem**: `_loadAnalytics()` calls `findAll()` on both `scanRecords` and `dailyScanAggregates`. For power users with thousands of scans, this loads the entire database into memory on every profile screen visit and on every Isar watcher trigger.

**Suggestion**: Use paginated queries or aggregation queries to reduce memory pressure.

---

### ~~ENH-020: `RemoteConfigService` minimum fetch interval is 1 day~~

**File**: `lib/services/remote_config_service.dart`
**Status**: ✅ FIXED

**Resolution**: The fetch interval is now remotely configurable via the `fetch_interval_seconds` key (default: 3600 seconds / 1 hour). Additionally, a lifecycle observer (`_AppLifecycleObserver`) force-fetches config whenever the user resumes the app. The `onConfigUpdated` real-time listener also dynamically updates the interval.

---

### ~~ENH-021: No deep link or cold-start notification handling~~

**File**: `lib/services/notification_service.dart`
**Status**: ✅ FIXED — Added `onMessageOpenedApp` (background tap) and `getInitialMessage()` (cold-start tap) handlers. Also added `subscribeToTopic('all_users')` in `main.dart` for Firebase Campaign targeting.

---

## Summary Table

| ID | Severity | Status | Category | File |
|----|----------|--------|----------|------|
| ~~BUG-001~~ | ~~🔴 Critical~~ | ✅ FIXED | ~~Memory Leak~~ | ~~`notification_service.dart`~~ |
| ~~BUG-002~~ | ~~🔴 Critical~~ | ✅ FIXED | ~~Blocking I/O~~ | ~~`db_service.dart`~~ |
| ~~BUG-003~~ | ~~🔴 Critical~~ | ✅ FIXED | ~~Nested Txn~~ | ~~`db_service.dart` / `sync_service.dart`~~ |
| BUG-004 | 🟠 High | 🟡 SKIPPED | Dead Field (Requires Schema Gen) | `app_notification_model.dart` |
| ~~BUG-005~~ | ~~🟠 High~~ | ✅ FIXED | ~~Soft-Delete~~ | ~~`notification_service.dart`~~ |
| ~~BUG-006~~ | ~~🟠 High~~ | ✅ FIXED | ~~Fire-and-Forget~~ | ~~`db_service.dart`~~ |
| ~~BUG-007~~ | ~~🟠 High~~ | ✅ FIXED | ~~iOS Crash~~ | ~~`main.dart`~~ |
| ~~BUG-008~~ | ~~🟠 High~~ | ✅ FIXED | ~~Premium UX~~ | ~~`app_config.dart`~~ |
| ~~BUG-022~~ | ~~🟠 High~~ | ✅ FIXED | ~~UX / Payment~~ | ~~`recognition_sheet.dart`~~ |
| ~~EDGE-009~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~UX~~ | ~~`camera_screen.dart`~~ |
| ~~EDGE-010~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Widget Lifecycle~~ | ~~`camera_screen.dart`~~ |
| EDGE-011 | 🟡 Medium | 🟡 OPEN | Dead Code (File Deletion Ready) | `payment_sheet_copy.dart` |
| ~~EDGE-012~~ | ~~🟡 Medium~~ | ✅ RESOLVED | ~~PhonePe~~ | ~~`payment_service.dart`~~ |
| ~~EDGE-013~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Security~~ | ~~`payment_service.dart`~~ |
| ~~EDGE-014~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Dead Code~~ | ~~`camera_screen.dart`~~ |
| ~~EDGE-015~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Data Sync~~ | ~~`db_service.dart`~~ |
| ~~EDGE-023~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Dead Code / Security~~ | ~~`app_config.dart`~~ |
| ~~EDGE-024~~ | ~~🟡 Medium~~ | ✅ FIXED | ~~Widget Lifecycle~~ | ~~`recognition_sheet.dart`~~ |
| ENH-016 | 🟢 Low | 🟡 SKIPPED | Architecture | `main.dart` |
| ~~ENH-017~~ | ~~🟢 Low~~ | ✅ FIXED | ~~Stability~~ | ~~`main.dart`~~ |
| ENH-018 | 🟢 Low | 🟡 SKIPPED | Data Model (Requires Schema Gen) | `daily_scan_aggregate.dart` |
| ENH-019 | 🟢 Low | 🟡 SKIPPED | Performance | `profile_screen.dart` |
| ~~ENH-020~~ | ~~🟢 Low~~ | ✅ FIXED | ~~Config~~ | ~~`remote_config_service.dart`~~ |
| ~~ENH-021~~ | ~~🟢 Low~~ | ✅ FIXED | ~~Notifications~~ | ~~`notification_service.dart`~~ |
