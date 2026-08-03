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

