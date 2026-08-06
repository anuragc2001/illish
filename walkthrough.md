# Illish v2.0 — Final Inspection Report 🐟

Comprehensive audit of the entire codebase performed on July 29, 2026.

---

## 1. What We Have Achieved

### Core App (4-Screen Flow)
| Screen | File | Size | Status |
|:---|:---|:---|:---|
| Bazaar Viewfinder | [camera_screen.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/camera_screen.dart) | 61KB | ✅ Complete |
| Recognition Card | [recognition_sheet.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/recognition_sheet.dart) | 16KB | ✅ Complete |
| UPI Payment Sheet | [payment_sheet.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/payment_sheet.dart) | 14KB | ✅ Complete (hidden from flow) |
| Machi Master Results | [results_screen.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/results_screen.dart) | 66KB | ✅ Complete |

### Services Layer
| Service | File | Purpose | Status |
|:---|:---|:---|:---|
| AI Orchestrator | [ai_service.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/services/ai_service.dart) | Mock/cloud routing, cancelable ops | ✅ |
| Gemini Provider | [gemini_provider.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/services/ai/gemini_provider.dart) | Multimodal Gemini 3.6 Flash API | ✅ |
| AdMob Service | [admob_service.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/services/admob_service.dart) | Banner + Interstitial ads | ✅ |
| Database Service | [db_service.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/services/db_service.dart) | Isar CRUD, pagination, cleanup | ✅ |
| Payment Service | [payment_service.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/services/payment_service.dart) | UPI app detection + launching | ✅ |

### Widgets
| Widget | File | Purpose | Status |
|:---|:---|:---|:---|
| Banner Ad | [banner_ad_widget.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/widgets/banner_ad_widget.dart) | AdMob banner wrapper | ✅ |
| Share Card | [share_card_preview.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/widgets/share_card_preview.dart) | Share card UI | 🔨 WIP |
| UPI Picker | [upi_picker_sheet.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/screens/widgets/upi_picker_sheet.dart) | UPI app selection sheet | ✅ |

### Data Models
| Model | File | Purpose |
|:---|:---|:---|
| ScanRecord | [scan_record.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/core/models/scan_record.dart) | Isar schema for scans + bookmarks |
| RecipeCache | [recipe_cache.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/core/models/recipe_cache.dart) | Isar schema for YouTube API cache |
| UpiApp | [upi_app.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/core/models/upi_app.dart) | UPI app + response models |

### Configuration & Native
| File | Purpose | Status |
|:---|:---|:---|
| [app_config.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/config/app_config.dart) | Feature flags (mockMode, premium, UPI) | ✅ |
| [theme.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/core/theme.dart) | Dark theme, color palette, typography | ✅ |
| [.env](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/.env) | API keys + AdMob unit IDs | ✅ |
| [AndroidManifest.xml](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/android/app/src/main/AndroidManifest.xml) | Permissions + AdMob App ID | ✅ |
| [Info.plist](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/ios/Runner/Info.plist) | Permissions + AdMob App ID | ✅ |
| [MainActivity.kt](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/android/app/src/main/kotlin/com/anuragchak/illish/MainActivity.kt) | Kotlin UPI platform channel | ✅ |

---

## 2. AdMob Production Matrix

| Platform | App ID (Native Config) | Banner Ad Unit ID (.env) | Interstitial Ad Unit ID (.env) |
|:---|:---|:---|:---|
| **iOS** | `~9641109305` ✅ | `/1280357841` ✅ | `/1715472115` ✅ |
| **Android** | `~3112314261` ✅ | `/3814333482` ✅ | `/9402390440` ✅ |

> Currently using **test IDs** as active keys (production IDs commented out in `.env`). Swap before release.

---

## 3. Dependencies (17 packages)

| Package | Version | Purpose |
|:---|:---|:---|
| `camera` | ^0.10.5 | Camera feed, capture, zoom, flash |
| `google_generative_ai` | ^0.4.0 | Gemini multimodal vision API |
| `google_mobile_ads` | ^9.0.0 | AdMob banner + interstitial |
| `isar` / `isar_flutter_libs` | ^3.1.0+1 | On-device NoSQL database |
| `geolocator` / `geocoding` | ^13.0.1 / ^3.0.0 | GPS + reverse geocoding |
| `connectivity_plus` | ^6.1.1 | Network state detection |
| `url_launcher` | ^6.2.4 | YouTube native app launching |
| `youtube_player_flutter` | ^9.0.1 | (available for embedded playback) |
| `image_picker` | ^1.1.2 | Gallery import |
| `share_plus` | ^10.1.0 | Native OS share sheet |
| `gal` | ^2.3.0 | Save images to gallery |
| `google_fonts` | ^6.2.1 | Inter font family |
| `flutter_dotenv` | ^5.1.0 | Environment variable loading |
| `http` | ^1.2.1 | YouTube Data API calls |
| `async` | ^2.11.0 | CancelableOperation for AI |
| `shared_preferences` | ^2.2.3 | (available for onboarding flags, etc.) |
| `workmanager` | ^0.9.0+3 | Background sync (stub for future) |

---

## 4. Key Observations & Callouts

### ⚠️ Critical: `kMockMode = true`
[app_config.dart](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/lib/config/app_config.dart) has `kMockMode = true`. This means the app **never hits the real Gemini API**. You must set this to `false` before any real testing, TestFlight, or App Store submission.

### ⚠️ .env Key Security
The `.env` file is properly excluded from git via `.gitignore` ✅. However, note that `.env` is bundled as a Flutter asset (listed in `pubspec.yaml` assets), which means it gets compiled into the app binary. For production, consider server-side key management or obfuscation.

### 📝 `camera_screen.dart` is 61KB
This is the largest file in the project at ~1600 lines. It handles camera initialization, zoom controls, flash toggle, tap-to-focus, gallery import, AI processing HUD, recognition sheet, scan history, and bookmarks all in one `StatefulWidget`. A future refactor should extract this into separate services/controllers.

### 📝 `results_screen.dart` is 66KB
Similarly large. Contains the freshness ring, cut guide, price card, vendor tips, recipe carousel, share dialog, bookmark logic, and banner ads. Could benefit from widget extraction.

### 📝 Workmanager Callback is a Stub
The `callbackDispatcher` in `main.dart` is initialized but the body is a TODO. This was designed for future Isar → Supabase/Firebase cloud sync.

### ✅ Image Cleanup is Properly Handled
`DBService._cleanupImageIfUnused()` correctly checks whether a scan's image file is referenced by any other record before deleting it from disk. This prevents orphaned files and also prevents accidental deletion of shared images between scans and bookmarks.

---

## 5. Documentation Files Updated

| Document | What Was Updated |
|:---|:---|
| [README.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/README.md) | Complete rewrite with full features, architecture tree, tech stack, setup instructions |
| [CONTEXT.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/CONTEXT.md) | Added "v2.0 Journey" section with AdMob, UPI, Share Card, env config |
| [FUTURE_ENHANCEMENTS.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/FUTURE_ENHANCEMENTS.md) | Updated all statuses (COMPLETED/WIP/NOT STARTED), added 10 new feature ideas, flagged kMockMode |
| [feature_roadmap.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/feature_roadmap.md) | Marked AdMob and Price Intelligence as COMPLETED, added Share Card WIP, updated priority order |
| [UI_GUIDELINES.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/UI_GUIDELINES.md) | No changes needed — still accurate |
| [.agents/AGENTS.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/.agents/AGENTS.md) | No changes needed — all 10 rules still valid |

---

## 6. New Feature Ideas & Revisit List

### 🚀 Quick Wins (Can Do This Weekend)
| Feature | Effort | Impact |
|:---|:---|:---|
| Set `kMockMode = false` | 1 line | **Critical** — unlocks real AI |
| Haptic feedback on shutter tap | 1 line | Feels premium |
| Image compression before API | ~20 lines | 2-3x faster scans on slow networks |
| Onboarding carousel (3 slides) | ~100 lines | Reduces first-use confusion |
| Animate location pill on camera | ~15 lines | Polish |

### 🔨 Medium Effort (1-2 Days)
| Feature | Impact |
|:---|:---|
| Finalize Share Card UI & export | Organic growth engine |
| Freemium paywall (scan limits) | Revenue |
| Scan count badge on home screen | Gamification |

### 🏗️ Large Effort (1+ Week)
| Feature | Impact |
|:---|:---|
| Real-time fish detection (ML Kit) | Core differentiator |
| Multi-fish stall scanning | Premium feature |
| Scan history timeline with stats | Habit loop |
| Vendor trust scores | Stickiness |
| Seasonal fish calendar | Content marketing |
| Architecture refactor (Riverpod) | Dev velocity |

### 🔄 Items to Revisit
| Item | Context |
|:---|:---|
| Share Card UI aesthetic | Paused — user wants to redesign from scratch with fresh eyes |
| Uncomment production AdMob IDs in `.env` | Currently using test IDs; swap when ready for production ads |
| UPI return handshake | Currently launches app only; future: auto-redirect with transaction result |
| Workmanager cloud sync | Stub exists; implement when backend (Supabase/Firebase) is chosen |

---

## 7. v2.1 Session — Monetization Hardening, Sync Reliability & User Conversion

*Completed: August 3, 2026*

### Fixes & Features

| Feature | Files Changed | Detail |
|:---|:---|:---|
| **Locked Scan Paywall** | `scan_record.dart`, `db_service.dart`, `sync_service.dart`, `camera_screen.dart`, `recognition_sheet.dart`, `payment_sheet.dart` | Added `isUnlocked: bool` to `ScanRecord`. New scans default to `false`. Lock icon badge shown on thumbnails in Recent Scans for locked items. Tapping a locked scan forces the `RecognitionSheet` gate instead of bypassing to `ResultsScreen`. |
| **Persistent Unlock** | `db_service.dart`, `payment_sheet.dart` | `DBService.unlockScan(id)` is called on successful ad watch or premium upgrade. Persisted to Isar + Firestore — permanent and cross-device. |
| **Multi-Device UI Sync Fix** | `main.dart`, `camera_screen.dart` | `SyncService.startRealtimeSync()` now fires at app launch if a session exists. `SavedItemsSheet` uses `isar.scanRecords.watchLazy()` to auto-refresh the UI on any background Firestore sync — no more sign-out/sign-in to see the other device's scans. |
| **Persistent Ad Counter** | `admob_service.dart` | `_resultsBackClickCount` moved from in-memory to `SharedPreferences`. Accumulated across app restarts — users can no longer bypass the every-3rd-click interstitial ad by force-closing the app. |
| **Anonymous Conversion Modal** | `results_screen.dart` | Glassmorphic "Save Your Scans" modal shown on 1st scan and every 4th scan after (1st, 5th, 9th...). Appears 2 seconds post-result-load. Button pushes `ProfileScreen` without losing the current `ResultsScreen` context. |
| **Soft Delete / Cloud Archiving** | `db_service.dart`, `sync_service.dart` | `deleteScan` and `clearRecentScans` now call `SyncService.archiveScanRecord(id)` instead of hard-deleting. Firebase Storage image is deleted (cost savings). Firestore document kept with `isArchived: true` for heatmap analytics. |
| **Clear All Cloud Sync Fix** | `db_service.dart` | `clearRecentScans` was wiping local Isar records but not triggering any cloud sync. Now correctly calls `archiveScanRecord` for each deleted scan. |

### Decisions Made

| Decision | Rationale |
|:---|:---|
| Redirect to `ProfileScreen` instead of inline Google Sign-In in modal | Simpler, more reliable. User returns to `ResultsScreen` after signing in. No complex auth state inside a dialog. |
| Soft delete (archive) instead of hard delete | Preserves geospatial fish scan data for future heatmap feature while still freeing Storage costs. |
| `isUnlocked = false` default for new scans | Enforces the paywall for all non-premium users consistently. Premium users get `true` at save time. |
| Ad counter in `SharedPreferences` | Prevents force-close bypass — counter now survives restarts and accumulates across sessions. |

### Pending from This Session

| Item | Priority | Notes |
|:---|:---|:---|
| **Phone OTP Auth** | High | SMS-based sign-in via Firebase Phone Auth for non-Google users |
| **Legacy Scan Migration** | Medium | One-time `DBService.initialize()` migration to set `isUnlocked = true` on pre-existing scans |

---

## 8. v2.2 Session — iOS Camera Init Fix, Profile Grey Screen Fix

*Completed: August 6, 2026*

### Root Causes & Fixes

| Bug | Root Cause | Fix | Files Changed |
|:----|:-----------|:----|:--------------|
| **`Undefined name 'Platform'` compile error** | `Platform.isAndroid` guard in `_initSecondaryServices()` used without `dart:io` import | Added `import 'dart:io';` to `main.dart` | `main.dart` |
| **"No cameras found" on iOS** | `cameras = await availableCameras()` was inside `_initSecondaryServices()` — a fire-and-forget async called **after** `runApp()`. Since `IllishApp` was a `StatelessWidget`, the first frame rendered `cameras.isEmpty` as true and locked in the error scaffold permanently (no `setState` to rebuild). | Moved `cameras = await availableCameras()` into `main()` **before** `runApp()`. Removed the dead-end fallback. Added a safety re-fetch inside `CameraScreen._initCamera()`. | `main.dart`, `camera_screen.dart` |
| **Grey screen on Profile after Camera** | `ProfileScreen.initState()` directly accessed `DBService.isar.scanRecords.watchLazy()` without verifying the Isar instance was initialized. If `DBService.initialize()` failed or was still completing, the `late Isar isar` field threw `LateInitializationError`. | Added `DBService.isInitialized` static getter. Wrapped all Isar watcher attachments and analytics methods in `isInitialized` checks and try-catch blocks. | `db_service.dart`, `profile_screen.dart` |

### Detailed Changes

#### `main.dart`
- **Line 1**: Added `import 'dart:io';` for `Platform` class.
- **Lines 62-68**: Moved `cameras = await availableCameras()` from secondary services into `main()`, before `runApp()`. This ensures the camera list is always populated before the first frame renders.
- **Line 144**: Removed conditional `cameras.isEmpty` check — `IllishApp` now always routes to `CameraScreen`.

#### `camera_screen.dart`
- **`_initCamera()`**: Added fallback `availableCameras()` call if the global `cameras` list is somehow still empty when the camera screen initializes.

#### `db_service.dart`
- Added `static bool get isInitialized => Isar.instanceNames.contains(Isar.defaultName);` — allows screens to safely check DB readiness before accessing `isar`.

#### `profile_screen.dart`
- **`initState()`**: Isar `watchLazy()` listeners now conditionally attached only when `DBService.isInitialized` is true, wrapped in try-catch.
- **`_loadAnalytics()`**: Early-returns if `!DBService.isInitialized`. Wrapped in try-catch.
- **`_fetchAndShowDailyScansDialog()`**: Early-returns if DB not ready or widget unmounted. Wrapped in try-catch.

### Decisions Made

| Decision | Rationale |
|:---------|:----------|
| Move camera init before `runApp()` | Adds ~200ms to startup but guarantees cameras are always available on first frame. Eliminates an entire class of race condition bugs. |
| Add `isInitialized` getter instead of making `isar` nullable | Minimal change surface — avoids rewriting every `DBService.isar` call site to handle nullability. |
| Wrap in try-catch instead of showing error UI | Profile screen should degrade gracefully (show empty state) rather than crash. Users can pull-to-refresh once DB is ready. |

---

## 9. v2.3 Session — Auth, Premium, and Payment Prompts

*Completed: August 6, 2026*

### Enhancements

| Feature | Detail | Files Changed |
|:--------|:-------|:--------------|
| **Forced Sign-In on Payment** | Intercepted the "Continue" (UPI Launch) button in the payment screen. If the user is a guest, they are pushed to the `ProfileScreen` with a `returnAfterSignIn` flag. Upon successful sign-in, the UI automatically pops back to the payment screen so checkout can resume smoothly. | `payment_sheet.dart`, `profile_screen.dart` |
| **"Upgrade to Premium" Button** | Replaced the obsolete "MACHI MASTER" header text in the Profile Screen with a sleek, glowing "Upgrade to Premium" button (only visible if the user is not currently premium). Navigates directly to the `PaymentScreen` when tapped. | `profile_screen.dart` |
| **Payment Bypass Counter** | Added a `SharedPreferences` counter (`paymentBypassCount`) that tracks how many times a non-premium user accesses the AI Freshness scanner. Instead of constantly harassing them with the `PaymentScreen`, the app now skips the payment prompt 2 out of every 3 times, directly serving an interstitial ad and unlocking the result. | `recognition_sheet.dart` |

### Decisions Made

| Decision | Rationale |
|:---------|:----------|
| `returnAfterSignIn` flag in `ProfileScreen` | Re-using the existing Profile screen for sign-in is cleaner than building a standalone modal, since it supports all 5 sign-in methods (Google, Apple, Email, Phone, Anon) out of the box. A simple stream listener on `AuthService.authStateChanges` pops the screen automatically once auth completes. |
| Payment Bypass every 3rd time | Dramatically reduces user friction. Non-premium users who simply want to watch ads to unlock scans will not be forced to manually skip the `PaymentScreen` on every single scan. |

---

## 10. v2.4 Session — Razorpay Migration, FCM Campaigns, Debug Cleanup

*Completed: August 7, 2026*

### Payment System Migration (PhonePe → Razorpay)

| Change | Detail | Files Changed |
|:-------|:-------|:--------------|
| **Razorpay SDK Integration** | Replaced PhonePe SDK (`phonepe_payment_sdk` + `crypto`) with `razorpay_flutter` in `pubspec.yaml`. Full Razorpay lifecycle with `clear()` before re-init to prevent listener leaks, `Completer<bool>` for async result handling, and `dispose()` method for cleanup. | `pubspec.yaml`, `payment_service.dart` |
| **Premium Grant on Payment** | `_handlePaymentSuccess` now sets `AppConfig.isPremiumUser`, calls `SyncService.upgradeUserToPremium()`, and calls `DBService.unlockAllScans()` to permanently unlock all previous scans. | `payment_service.dart` |
| **Razorpay Logo URL** | Added `razorpay_logo_url` Remote Config key. When set, it is passed as the `'image'` parameter in Razorpay SDK checkout options so the app logo appears on the Razorpay payment modal. | `remote_config_service.dart`, `payment_service.dart` |
| **Offline Premium State** | Added `AppConfig.initOfflinePremiumState()` to `main()` before `runApp()`. Premium status is cached in `SharedPreferences` and restored on cold boot so the UI renders correctly without waiting for Firestore. | `main.dart`, `app_config.dart` |

### Firebase Cloud Messaging (Campaign Support)

| Change | Detail | Files Changed |
|:-------|:-------|:--------------|
| **Topic Subscription** | Added `messaging.subscribeToTopic('all_users')` in `_initSecondaryServices()`. Firebase Campaigns can now target the `all_users` topic to blast notifications to all app instances. | `main.dart` |
| **Background & Terminated Handlers** | Added `FirebaseMessaging.onMessageOpenedApp` (background tap) and `FirebaseMessaging.instance.getInitialMessage()` (cold-start tap) handlers in `notification_service.dart`. Previously only foreground `onMessage` was handled, meaning notification taps did nothing when the app was backgrounded or killed. | `notification_service.dart` |
| **Refactored Message Processing** | Extracted shared logic into `_handleRemoteMessage()` so all 3 FCM paths (foreground, background tap, cold-start tap) use the same deduplication and processing pipeline. | `notification_service.dart` |

### Debug Print Cleanup

| Change | Detail | Files Changed |
|:-------|:-------|:--------------|
| **Razorpay Verbose Logs Removed** | Removed 8 excessive `debugPrint` calls (`=== [RAZORPAY] INIT OPTIONS ===`, `CALLING open()`, `open() CALLED SUCCESSFULLY`, `FATAL ERROR`, `EVENT_PAYMENT_ERROR` JSON dump). Kept only essential error/success logs. | `payment_service.dart` |
| **Remote Config Dump Removed** | Removed the 20-line `debugPrint` block that logged every single Remote Config value on fetch. | `remote_config_service.dart` |
| **Unused Import Removed** | Removed orphaned `import 'dart:convert'` left over from PhonePe SDK removal. | `payment_service.dart` |

### Configuration Cleanup

| Change | Detail | Files Changed |
|:-------|:-------|:--------------|
| **LLDB Suppression Removed** | Removed `config: enable-lldb-debugging: false` from `pubspec.yaml`. LLDB debugging is now enabled (Flutter default). | `pubspec.yaml` |

### Decisions Made

| Decision | Rationale |
|:---------|:----------|
| `razorpay_logo_url` only for SDK checkout, not payment_sheet UI | The user explicitly wanted the logo only in the Razorpay native checkout modal, not in the app's own payment sheet which retains the shield icon. |
| `subscribeToTopic('all_users')` over user-segment targeting | Simplest approach for campaigns — topic targeting works without any server-side user analytics setup. |
| Remove all verbose debug prints | User requested cleanup of "unnecessary debug prints like the razor pay" from the codebase. Essential error/success logs preserved. |
| Remove LLDB suppression | User explicitly requested bringing back LLDB debugging support. |

