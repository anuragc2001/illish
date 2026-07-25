# Future Enhancements & Feature Backlog

## 1. Real-Time Camera Target Detection (Fish / Non-Fish Classifier)

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

## 2. On-Device Offline ML Model (Full Offline Species & Freshness Recognition)

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

### Concept
When pushing new screens (like the `ResultsScreen`), the camera feed currently continues streaming frames beneath the new route. While the OS backgrounding is handled, navigating within the app leaves the camera running.

### Technical Approach
- Safely pause `CameraController` image streams upon route push, and resume them on pop, without causing black screens or initialization race conditions during transition animations.

---

## 5. Graceful Network & Offline Failures

### Concept
If the Gemini API fails entirely, the app currently falls back to a simulated scan instead of explicitly alerting the user that the network request failed.

### Technical Approach
- Update `ResultsScreen` UI to cleanly handle and display network failure states, giving the user a clear "Retry Connection" or "Offline Mode" option instead of spoofing a result.

---

## 6. Architecture & State Management Refactoring

### Concept
`_CameraScreenState` currently manages complex camera initializations, animations, file picking, and API integration in one monolithic file.

### Technical Approach
- Abstract the Camera lifecycle and state into a dedicated Service or use a state management solution (like Riverpod or Bloc) to decouple UI from hardware/API logic.

---

## 7. Local Database Pagination (Isar)

### Concept
Fetching all bookmarks at once via `db_service.dart` works fine for a pilot, but could drop frames if hundreds of items are saved over time.

### Technical Approach
- Implement lazy loading or pagination queries in Isar for the `SavedItemsSheet` to ensure it scales flawlessly regardless of user history size.
