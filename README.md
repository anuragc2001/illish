# Illish 🐟

> Eliminate bazaar anxiety. Know what you're buying before you buy it.

**Illish** is a premium, AI-powered fish scanning app for Indian wet-market shoppers. Point your camera at a fish, and Illish instantly identifies the species, translates it to your hyper-local regional name, grades its freshness, suggests fair pricing, and recommends authentic local recipes — all in under 5 seconds.

---

## Screenshots

| Bazaar Viewfinder | Recognition Card | Machi Master Results |
|:---:|:---:|:---:|
| Full-bleed camera with zoom pills, flash toggle, tap-to-focus | Frosted-glass bottom sheet with local name translation | Freshness ring, price card, cut guide, recipe carousel |

---

## Key Features

### 🔍 Multilingual Fish Identification
- Uses **Gemini 3.6 Flash** vision AI to identify fish species from a photo.
- Automatically translates the scientific/English name to the **hyper-local market name** using GPS-based reverse geocoding.
- Example: `Seer Fish → Surmai (Mumbai)` or `Rohu → Rui / রুই (Kolkata)`.

### 🚦 AI Freshness Scanner
- Analyzes eye cloudiness, gill color, and skin texture from the image.
- Returns a **traffic-light freshness score** (0–100%) with evidence bullets.
- Dynamic neon ring with status grading: Excellent / Good / Fair / Poor.

### 💰 Price Intelligence
- Estimates a **fair retail price range** based on species, location, freshness, season, and time of day.
- Displays a market average for comparison to help users negotiate fairly.

### 🔪 Cut Guide & Vendor Trickery Alerts
- Recommends **hyper-local butchering cuts** (e.g., Peti, Gada, Mura for Bengal).
- Warns about common vendor tricks (ice weight padding, artificial coloring, etc.).

### 🍳 Curated Recipe Hub
- Auto-matches identified species to **localized recipes** (format: `LocalName (EnglishName)`).
- Fetches top YouTube video tutorials via the YouTube Data API v3.
- Results are cached in Isar for 7 days to conserve API quota.
- Videos launch natively in the YouTube app (not a webview).

### 📸 Camera UX
- **1x / 2x digital zoom pills** for macro-safe close-up scanning.
- **Pinch-to-zoom** gesture support.
- **Tap-to-focus** with animated yellow reticle pushing explicit AF/AE coordinates.
- **Flash / Torch toggle** for low-light wet markets.
- **Gallery import** via `ImagePicker` — scan photos from camera roll.

### 💳 UPI Payment Integration
- Native Android UPI app detection via platform channel (`MethodChannel`).
- iOS support for GPay, PhonePe, Paytm, CRED, BHIM via URL scheme detection.
- Launches the selected payment app directly (no webview).

### 📊 Monetization (Google AdMob)
- **Banner Ads** on the Results screen (non-premium users).
- **Interstitial Ads** triggered every 3rd back-button press from Results.
- Premium users (`kIsPremiumUser`) bypass all ad logic entirely.
- All Ad Unit IDs are environment-driven via `.env` + `flutter_dotenv`.
- Production IDs for both iOS and Android are configured and ready.

### 🔖 Bookmarks & History
- Scan results are auto-saved to **Isar** local database.
- Users can bookmark favorite scans for persistent storage.
- Recent scans are capped at 10 (FIFO eviction with image cleanup).
- Paginated queries for smooth scrolling.

### 🌐 Offline Resilience
- Network connectivity check via `connectivity_plus` before every API call.
- Graceful error states: offline, timeout, low network, invalid image.
- `AppConfig.kMockMode` provides zero-latency simulated responses for development.
- Mock mode cycles through 6 states: 3 freshness levels + invalid image + offline + timeout.

---

## Architecture

```
lib/
├── config/
│   └── app_config.dart          # Feature flags (mockMode, premium, UPI)
├── core/
│   ├── models/
│   │   ├── scan_record.dart     # Isar schema for scans & bookmarks
│   │   ├── recipe_cache.dart    # Isar schema for YouTube API cache
│   │   └── upi_app.dart         # UPI app model + response parser
│   └── theme.dart               # AppTheme: colors, typography, buttons
├── screens/
│   ├── camera_screen.dart       # Screen 1: Bazaar Viewfinder
│   ├── recognition_sheet.dart   # Screen 2: Fish ID bottom sheet
│   ├── payment_sheet.dart       # Screen 3: UPI micro-transaction sheet
│   ├── results_screen.dart      # Screen 4: Machi Master dashboard
│   └── widgets/
│       ├── banner_ad_widget.dart # AdMob banner wrapper
│       ├── share_card_preview.dart # Share card UI (WIP)
│       └── upi_picker_sheet.dart   # UPI app selection bottom sheet
├── services/
│   ├── admob_service.dart       # AdMob initialization, interstitial logic
│   ├── ai_service.dart          # AI orchestrator (mock + cloud routing)
│   ├── ai/
│   │   ├── ai_provider.dart     # Abstract AIProvider interface
│   │   └── gemini_provider.dart # Gemini Flash implementation
│   ├── db_service.dart          # Isar CRUD operations
│   └── payment_service.dart     # UPI app detection & launching
└── main.dart                    # App entry point
```

### Native Code
- **Android**: `MainActivity.kt` — Platform channel for UPI app discovery and launching.
- **iOS**: `Info.plist` — Camera, microphone, location permissions + AdMob GADApplicationIdentifier.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter SDK (Dart 3.12+) |
| AI Engine | Google Gemini 3.6 Flash (multimodal vision) |
| Local Database | Isar (NoSQL, on-device) |
| Monetization | Google AdMob (Banner + Interstitial) |
| Payments | UPI deep links + Platform Channels |
| Location | Geolocator + Geocoding (reverse geocode) |
| Video | YouTube Data API v3 + native app launching |
| Networking | connectivity_plus, http, async (CancelableOperation) |
| Environment | flutter_dotenv (.env) |
| Background | Workmanager (future Isar → Cloud sync) |
| Sharing | share_plus + gal (gallery save) |

---

## Environment Setup

### Prerequisites
- Flutter SDK ≥ 3.12.2
- Xcode (for iOS builds)
- Android Studio (for Android builds)

### Configuration
1. Create a `.env` file in the project root:
```env
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-3.6-flash
YOUTUBE_API_KEY=your_youtube_api_key

# Production AdMob Unit IDs
ADMOB_BANNER_ID_ANDROID=your_android_banner_id
ADMOB_BANNER_ID_IOS=your_ios_banner_id
ADMOB_INTERSTITIAL_ID_ANDROID=your_android_interstitial_id
ADMOB_INTERSTITIAL_ID_IOS=your_ios_interstitial_id
```

2. Run:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Build Flavors
- `prod` — Production build.
- `exp` — Experimental features.

---

## Version
**v2.0.0** — Full AI-powered scanning, AdMob monetization, UPI payments, and offline resilience.

---

## License
Private. Not published to pub.dev.
