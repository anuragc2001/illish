# Future Enhancements & Feature Backlog

## 1. Real-Time Camera Target Detection (Fish / Non-Fish Classifier)

### Status: NOT STARTED (High Priority)
### Concept
When the user opens Screen 1 (Bazaar Viewfinder), the camera feed should continuously check the target in real time before a picture is taken:
- 🔴 **Red Border / Reticle**: When pointed at non-fish or non-aquatic objects (e.g. table, shoes, text, person), with a hint message: *"Point camera at a fish or aquatic species"*.
- 🟢 **Neon Green Border / Reticle**: When a fish, gills, or aquatic species is detected, with a hint message: *"Fish detected — Tap to scan"*.

### Technical Approach (On-Device ML)
- **Package**: Add `google_mlkit_image_labeling` or `tflite_flutter`.
- **Implementation**: 
  1. Hook into `CameraController.startImageStream((CameraImage image) => ...)`.
  2. Pass frames through a lightweight, zero-latency on-device classifier model.
  3. Dynamically update state (`_isTargetFish`) to change `_buildBracket` color and reticle text.
  4. Perform high-accuracy freshness and species analysis via Gemini API only when shutter is tapped.

---

## 2. [CANCELLED] On-Device Offline ML Model (Full Offline Species & Freshness Recognition)

### Concept
Currently, when the user has no internet connection, `AIService` falls back to simulated offline data. Adding a custom embedded TensorFlow Lite (`.tflite`) model will allow full offline identification of common regional fish (e.g., Rohu, Catla, Hilsa/Ilish, Pomfret) and basic freshness estimations directly on the device.

### Technical Approach
- **Packages**: `tflite_flutter` (or `tflite_v2`) + `image`.
- **Model File**: Package a fine-tuned MobileNetV3 / EfficientNet `.tflite` model in `assets/models/fish_classifier.tflite` alongside `assets/models/labels.txt`.
- **Implementation**:
  1. In `lib/services/ai_service.dart`, check connectivity using `Connectivity().checkConnectivity()`.
  2. If offline, load tensor interpreter using `Interpreter.fromAsset('models/fish_classifier.tflite')`.
  3. Preprocess captured image (resize to 224x224, normalize RGB values).
  4. Run tensor inference to get species confidence score and freshness index offline.
  5. Return result structured identically to Gemini's cloud response so the rest of the app renders seamlessly.

---

## 3. [COMPLETED] Sleek Apple-Style Cancelable AI Processing Overlay

### Concept
Replace the basic `CircularProgressIndicator` full-screen dialog with an ultra-sleek, frosted-glass Apple HUD overlay during AI processing. If the user accidentally takes a photo or wants to retake it immediately, they can tap a subtle, intuitive "Retake" / "Cancel" button to abort the network request and return instantly to the camera viewfinder.

### UI & UX Design (Apple Design Language)
- **Visuals**: A floating glassmorphic pill/card (`BackdropFilter` + `sf_pro` styling) centered on screen with a soft ambient neon glow.
- **Micro-Animations**: Shimmering scanning beam or pulsing radial halo around a thumbnail of the captured photo.
- **Controls**: A subtle, pill-shaped `"Cancel & Retake"` button at the bottom of the card (`CupertinoButton` style with a soft `X` icon).

### Technical Approach
- **Cancelable Async Request**: Use a `CancelableOperation` from `package:async/async` (or an `http.Client` with `CancelToken` / `AbortController`) inside `AIService`.
- **State Handling**: 
  1. Tapping `"Cancel & Retake"` immediately cancels the active Gemini API call.
  3. Resets camera state so the user can immediately re-align and take a new photo without delay.

---

## 4. Handle Background Camera Navigation Streams

### Status: NOT STARTED
### Concept
When pushing new screens (like the `ResultsScreen`), the camera feed currently continues streaming frames beneath the new route. While the OS backgrounding is handled, navigating within the app leaves the camera running.

### Technical Approach
- Pause `CameraController` on `push()` and resume on `pop()`.

---

## 5. [COMPLETED] Graceful Network & Offline Failures

### Concept
If the Gemini API fails entirely, the app currently falls back to a simulated scan instead of explicitly alerting the user that the network request failed.

### Technical Approach
- Update `ResultsScreen` UI to cleanly handle and display network failure states, giving the user a clear "Retry Connection" or "Offline Mode" option instead of spoofing a result.

---

## 6. Architecture & State Management Refactoring

### Status: NOT STARTED (Medium Priority)
### Concept
`_CameraScreenState` currently manages complex camera initializations, animations, file picking, and API integration in one monolithic file (~61KB / ~1600 lines).

### Technical Approach
- Abstract the Camera lifecycle and state into a dedicated Service or use a state management solution (like Riverpod or Bloc) to decouple UI from hardware/API logic.

---

## 7. [COMPLETED] Local Database Pagination (Isar)

### Concept
Fetching all bookmarks at once via `db_service.dart` works fine for a pilot, but could drop frames if hundreds of items are saved over time.

### Technical Approach
- Implement lazy loading or pagination queries in Isar for the `SavedItemsSheet` to ensure it scales flawlessly regardless of user history size.

---

## 8. Full Automatic UPI Return Handshake (Android Intent Contract)

### Status: NOT STARTED
### Concept
Currently, clicking "Pay Vendor" launches the selected payment app's launcher activity directly, so the user manually switches back to Illish after paying the vendor. 

In a future release, if we want an automatic auto-redirect back into Illish right after payment completion:
- Re-introduce the `upi://pay` deep link intent.
- Pass a dynamic transaction payload (`pa`, `pn`, `am`, `tn`, `tr`).
- Parse `onActivityResult` on Android to receive explicit transaction confirmation status (`SUCCESS`, `FAILURE`, `SUBMITTED`) and automatically auto-pop back to Illish.

---

## 9. [COMPLETED] Google AdMob Monetization

### Concept
Integrate Google AdMob with both Banner and Interstitial ad formats to monetize non-premium users.

### What Was Built
- `AdMobService` with initialization, interstitial preloading, and a smart "every 3rd click" back-button trigger.
- `BannerAdWidget` reusable widget with loading states.
- Production Ad Unit IDs for both iOS and Android stored in `.env`.
- Real App IDs configured in `AndroidManifest.xml` and `Info.plist`.
- Premium user bypass logic (`kIsPremiumUser`).
- Developer test keys preserved as `_DEV` comments in `.env` for safe local testing.

---

## 10. Share Card UI (WIP — Paused)

### Status: IN PROGRESS — Paused for design review
### Concept
Allow users to share a beautifully designed, branded scan card via WhatsApp, Instagram, etc. to drive organic installs.

### What Was Built So Far
- `RepaintBoundary` + `dart:ui` screenshot capture at 3x resolution.
- `share_plus` integration for native OS share sheet.
- `gal` integration for gallery saving.
- Multiple aesthetic directions prototyped (Instagram Story, Trading Card/RPG).

### What Needs to Be Done
- Finalize the visual aesthetic and card layout.
- Ensure corners clip perfectly without border bleeding.
- Ensure action buttons align flush with the card edges.
- Add "Scanned with Illish" watermark + App Store deep link.

---

## 11. [COMPLETED] Image Compression Before API Call

### Status: COMPLETED
### Concept
Phone cameras capture 12-48MP images. Sending a raw 8MB photo to Gemini wastes bandwidth (critical in wet markets with poor signal) and increases latency.

### Implemented Solution
- `FlutterImageCompress.compressAndGetFile` resizes all photos (camera captures & gallery imports) to max **1080x1080 JPEG at 80% quality** before sending to Gemini API.
- Files are saved to local `documentsPath` and clean compressed paths are passed to `AIService`.

---

## 12. [COMPLETED] Locked Scan History Paywall State

### Status: COMPLETED
### Concept
Prevent users from bypassing the ad/paywall gate by accessing full scan results from Recent Scans history.

### Implemented Solution
- Added `isUnlocked: bool` to `ScanRecord` schema (Isar + Firestore).
- New scans default to `isUnlocked = false` (unless user is premium).
- Lock icon badge renders on Recent Scans list thumbnails for locked items.
- Tapping a locked scan forces the `RecognitionSheet` ad/upgrade gate.
- Successful ad completion or premium upgrade calls `DBService.unlockScan(id)`, permanently unlocking the scan across local Isar and cloud Firestore.

---

## 13. [COMPLETED] Multi-Device Real-Time Sync & Live UI Refresh

### Status: COMPLETED
### Concept
Scans taken on Phone A were not appearing on Phone B's Recent Scans list without manual sign-out/sign-in.

### Implemented Solution
- `SyncService.startRealtimeSync()` starts at app launch in `main.dart` if a user session exists.
- `SavedItemsSheet` subscribes to `DBService.isar.scanRecords.watchLazy()` so background Firestore syncs automatically trigger a live UI refresh without restarting or swiping.

---

## 14. [COMPLETED] Persistent Ad Counter (Force-Close Bypass Fix)

### Status: COMPLETED
### Concept
The interstitial ad counter (`_resultsBackClickCount`) was stored in memory, resetting to 0 on force-close.

### Implemented Solution
- `AdMobService` now persists `_resultsBackClickCount` in `SharedPreferences`.
- Accumulates across app restarts so users cannot bypass ads by force-closing the app.

---

## 15. [COMPLETED] Anonymous-to-Signed-In Conversion Modal

### Status: COMPLETED
### Concept
Encourage anonymous users to sign in to save scan history.

### Implemented Solution
- Premium glassmorphic "Save Your Scans" modal appears on 1st scan and every 4th scan thereafter (1st, 5th, 9th...).
- Appears 2 seconds after `ResultsScreen` loads.
- "Go to Profile to Sign In" button pushes `ProfileScreen` without discarding current result context. User returns to `ResultsScreen` after sign-in.

---

## 16. [COMPLETED] Soft Delete / Cloud Archiving for Heatmaps

### Status: COMPLETED
### Concept
Hard-deleting Firestore scan documents destroys valuable geospatial fish distribution analytics.

### Implemented Solution
- Deleting a scan (swipe or "Clear All") calls `SyncService.archiveScanRecord(id)`.
- Image is deleted from Firebase Storage (saves storage cost).
- Firestore document remains flagged with `isArchived: true` for heatmap data retention.
- Local Isar record and image file are fully removed.

---

## 17. Haptic Feedback & Sound Design

### Status: NOT STARTED (Quick Win)
### Concept
The app feels "silent". Premium apps use subtle haptics and sounds to provide tactile feedback.

### What to Add
- Light haptic on shutter tap (`HapticFeedback.mediumImpact()`).
- Subtle "scan complete" haptic when AI results arrive.
- Optional shutter sound effect.

---

## 18. Onboarding Carousel

### Status: NOT STARTED (Quick Win)
### Concept
First-time users may not understand the app's purpose or flow. A simple 3-slide carousel on first launch would reduce confusion and set expectations.

### What to Build
- 3 slides: "Scan any fish" → "Get local name + freshness" → "Find fair prices & recipes".
- Store `hasSeenOnboarding` in `SharedPreferences`.
- Skip button + auto-dismiss after last slide.

---

## 19. Phone OTP Authentication

### Status: PENDING / IN PROGRESS (High Priority)
### Concept
SMS-based sign-in via Firebase Phone Auth as a secondary sign-in method for users who do not have a Google account on their device.

---

## 20. Legacy Scan Migration

### Status: PENDING (Medium Priority)
### Concept
Pre-existing scans created before `isUnlocked` was added to `ScanRecord` default to `false`. Add a one-time migration in `DBService.initialize()` to set `isUnlocked = true` on historical records.

---

## 21. Multi-Fish Stall Scanning

### Status: NOT STARTED (Premium Feature)
### Concept
Capture one wide photo of an entire wet market stall with 5-10 fish laid out. Use Gemini vision to return a scrollable list of all detected species, local names, freshness ratings, and price ranges.

---

## 22. Scan History Timeline with Stats

### Status: NOT STARTED
### Concept
Full-screen scan statistics, GitHub-style calendar heatmap, species breakdown, and shareable stat cards.

---

## 23. Seasonal Fish Calendar

### Status: NOT STARTED
### Concept
Monthly regional calendar showing in-season fish and regional market notifications.

---

## 24. Vendor Trust Score / Profiles

### Status: NOT STARTED
### Concept
Track vendor stall locations, freshness averages over time, and community vendor trust ratings.

---

## 25. kMockMode Should Be Set to `false` for Production (IMPORTANT)

### Status: ACTION REQUIRED before release
### Concept
`AppConfig.kMockMode` is currently set to `true` in `lib/config/app_config.dart`. Must be set to `false` before real testing or App Store submission.

