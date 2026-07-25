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
