# Illish UI/UX and Engineering Guidelines

These rules were learned during the initial phase of the Illish app and must be strictly followed by all AI agents.

## 1. Camera UX (Macro Focus Constraints)
- **Do NOT** assume `setFocusMode(FocusMode.auto)` solves blurry close-up issues on smartphones. Hardware lenses have physical minimum focus distances (~10cm).
- **Rule**: If a user complains about blurry macro shots, remind them to use the **`2x` digital zoom pill** (or pinch-to-zoom) from a safer distance (15-20cm), rather than holding the phone physically closer.

## 2. Flutter Transparent AppBars & Scrolling Overlap
- **Do NOT** use a transparent `AppBar` inside a `Scaffold` if the `body` is scrollable (e.g., `SingleChildScrollView` or `ListView`) and contains text that might scroll under the notch.
- **Rule**: Place custom headers (e.g., Back buttons, titles) *directly inside* the scrollable widget so they scroll out of view gracefully.

## 3. Isar Database Regeneration
- **Do NOT** change any file containing `@Collection` (e.g., `lib/core/models/scan_record.dart`) without immediately re-running code generation.
- **Rule**: Always run `flutter pub run build_runner build --delete-conflicting-outputs` after altering database models.

## 4. Launching Native Apps (YouTube)
- **Do NOT** use `LaunchMode.externalApplication` blindly if you want to avoid in-app browsers.
- **Rule**: Prefer `LaunchMode.externalNonBrowserApplication` to force opening YouTube links directly in the native YouTube application.

## 5. Localized AI Prompting
- **Do NOT** ask Gemini for generic "fish cuts" or "recipes".
- **Rule**: Explicitly instruct Gemini to provide hyper-local terminology based on the provided GPS location variable, and strictly enforce the output format `LocalName (English Name)` for consistency.

## 6. Offline Fallbacks & Mock Mode
- **Do NOT** assume the app will always have a stable internet connection. Wet markets often have poor reception.
- **Rule**: Any changes to `AIService` must gracefully handle offline scenarios via `connectivity_plus`, and `AppConfig.kMockMode` must remain functional as a zero-latency testing fallback.

## 7. Camera Lifecycle & Permissions
- **Do NOT** trigger camera controls (Zoom, Flash) without verifying the controller state.
- **Rule**: Always wrap camera interactions in a check for `_controller != null && _controller!.value.isInitialized`.

## 8. Gallery vs Camera Inputs
- **Do NOT** assume all fish scans come from the live camera (`takePicture`). 
- **Rule**: The app supports gallery imports via `ImagePicker`. Ensure the downstream AI logic (`_processImage`) always accepts arbitrary local file paths and does not strictly depend on live camera context.

## 9. Flutter Environment Path
- **Context**: The agent runs in a non-interactive shell that skips loading `~/.zprofile` by default.
- **Rule**: Whenever you need to execute `flutter` or `dart` commands in the terminal, you MUST prefix it with `source ~/.zprofile && ` (e.g., `source ~/.zprofile && flutter pub get`).

## 10. ADB Command Execution
- **Context**: The `adb` command might not be available in the default system PATH for the agent.
- **Rule**: To run `adb`, you must create an alias with the absolute file path and chain it with `&&`. For example: `alias adb='~/Library/Android/sdk/platform-tools/adb' && adb <command>`.
