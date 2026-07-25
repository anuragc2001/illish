# illish — Agent Context

## Product Overview

**Mission:** Eliminate "bazaar anxiety" for Indian consumers by helping them avoid being cheated on price, quality, or variety by wet-market fish vendors.

**Target users:**
- Everyday households.
- Tech-savvy youths buying groceries for parents.
- Domestic migrants living in new Indian states who do not know regional fish names.

**Market strategy:**
- Free tier for virality and daily use.
- Impulse micro-transactions via UPI, priced around ₹19 to ₹29, for high-stakes freshness checks on weekends.

## Core Features

### Phase 1: MVP
1. **Multilingual Identity Engine**
   - Uses device location to translate a scanned fish's global name into the hyper-local name used in that market.
   - Example: Seer Fish → Surmai in Mumbai, Anjal in Mangalore.

2. **Haggling & Cut Guide**
   - Analyzes the fish size.
   - Breaks down premium parts.
   - Explains what should be excluded from the weight calculation.
   - Helps users negotiate fairly.

3. **Curated Culinary Hub**
   - Auto-matches identified fish species to localized recipes.
   - Embeds top-rated YouTube video tutorials in the UI.

### Phase 2: Premium Layer
4. **Traffic-Light AI Freshness Scanner**
   - Uses vision processing to inspect eye cloudiness, gill color, and skin texture.
   - Returns Green / Yellow / Red freshness status.

## End-User Flow

1. **Stall Scan**
   - User opens camera at a wet market stall.
   - UI overlays an orientation frame so eyes and gills are visible.

2. **Instant Translation**
   - App identifies the fish variety and checks GPS.
   - Displays the local regional name for the vendor.

3. **Freshness Assessment**
   - Vision-logic checks run.
   - Premium tier reveals the freshness rating.

4. **Buying Optimization**
   - App shows ideal culinary cuts for that fish weight.
   - Flags vendor tricks that can cause overcharging.

## Technical Architecture

### Hybrid Offline-First Stack
The app must work inside crowded markets with weak connectivity. Use a hybrid routing architecture where the phone is the primary engine and the cloud is optional.

| Layer | Technology | Responsibility |
|---|---|---|
| Cross-Platform UI | Flutter SDK | Camera plugins, animations, single codebase for Android and iOS. |
| Local Device Cache | Drift (SQLite) or Isar | Source of truth. All scans write locally first. |
| Cloud AI Engine | Gemini Flash API | Deep multi-turn vision reasoning when online. |
| On-Device AI Engine | Quantized TFLite / Local VLM | Fallback object tracking and basic classification offline. |
| Network Router | connectivity_plus | Detect connectivity and route between cloud and offline paths. |
| Sync Manager | workmanager | Background sync uploads offline history to Supabase or Firebase when connection returns. |

### Build Order for Engineering
1. System blueprinting.
2. API integration.
3. Connectivity layer.
4. UI/UX wrap.

### Implementation Notes
- Prefer local-first storage and UI updates with zero lag.
- Use structured JSON output prompts for fish identification and language mapping.
- Add wrappers for swapping between cloud parsing and offline placeholders.
- UPI gateway should support micro-purchases.
- Video player integration should be card-based and visually clean.

## Product Positioning

The app should feel less like a dense utility tool and more like **Apple Camera + a high-end food magazine**.

Because the app is used in bright, sunny, chaotic wet markets:
- Use high-contrast dark mode.
- Use massive typography.
- Use bottom-sheet swipes for one-handed operation.

## Implemented Features (v1.0 Journey)
During the initial build phase, several advanced features and UX refinements were added to strictly follow the Apple-style design philosophy:
- **Bookmarks & History**: Introduced a robust Isar schema separating transient `ScanHistory` from saved `Bookmarks`.
- **Apple-Style Scanning HUD**: Replaced basic loading spinners with a translucent frosted-glass HUD featuring a sweeping shimmer laser animation over the captured thumbnail.
- **Hardware-Aware Camera UX (Macro Mode)**: Since mobile cameras cannot physically focus closer than 10-15cm, `1x` and `2x` digital zoom pills were added above the shutter button. This allows users to capture crisp macro-style shots of gills and eyes from a focal-safe distance. Pinch-to-zoom is also fully supported.
- **Tap-to-Focus Reticle**: A yellow animated focus reticle appears on tap, pushing explicit auto-focus and auto-exposure coordinates to the camera lens.
- **Dynamic Freshness Ring**: The Results screen features a custom painter that draws a blurred cyan neon glow underneath the foreground arc, with dynamic status grading (Excellent/Good/Fair/Poor).
- **Inline Evidence Formatting**: Freshness logic results are parsed from AI and displayed as a clean, continuous line of dots (e.g., `Clear eyes • Bright gills`).
- **Strictly Localized AI Prompting**: The Gemini prompt explicitly forces the output format `LocalName (EnglishName)` for both Cuts and Recipes based strictly on the user's localized GPS coordinates.
- **Native Video Launching**: YouTube recipe links bypass the webview and open directly in the native YouTube app using `LaunchMode.externalNonBrowserApplication` or `externalApplication`.
- **Frictionless Onboarding**: The Payment Screen (`Screen 3`) was temporarily hidden from the active user flow to reduce friction during early adoption, jumping straight to the Results Screen.
- **Mock Mode & Offline Resilience**: `AppConfig.kMockMode` provides a fallback test mode for development. The `AIService` checks network connectivity using `connectivity_plus` to fall back to a basic localized scan offline.
- **Reverse Geocoding**: Uses `geolocator` and `geocoding` to pull the precise `locality` and `administrativeArea` for the user's location, ensuring highly accurate regional translation.
- **Intelligent Caching**: YouTube API results are cached in the `RecipeCache` Isar database for up to 7 days to conserve API quotas and improve speed.
- **Gallery Import & Torch**: Features a flash toggle (Torch mode) for low-light wet markets, and `ImagePicker` integration so users can upload photos from their gallery instead of strictly scanning live.

## Design System & Vibe

**Theme:** Pure dark mode, true black background `#000000`.

**Typography:**
- Clean geometric sans-serif like Inter or Clash Display.
- Huge bold headers.
- Muted grey subtext.

**Accent colors:**
- Neon Cyan for primary actions.
- Emerald Green, Amber, and Crimson Red reserved for freshness UI.

**Components:**
- Frosted glass overlays.
- Pill-shaped buttons.
- Borderless cards.

## Screen Breakdown

### Screen 1: The Bazaar Viewfinder
**Goal:** Zero friction, ready to scan immediately.

**Layout:**
- Full-bleed live camera feed.
- Top floating bar with location pill on the left and profile/history icon on the right.
- Center reticle with thin white brackets and pulsing text: "Align head and gills here".
- Bottom action area with a massive translucent circular shutter button.
- Upward chevron above the button hints at swipe-up for Recent Scans.

### Screen 2: The Identification Card
**Goal:** Show identity and regional translation instantly.

**Transition:** Camera blurs and a sleek black bottom sheet covers the bottom 40% of the screen.

**Content:**
- Massive English fish name.
- Local name underneath in neon cyan.
- Large pill button with padlock icon for "AI Freshness Check".
- Swipe prompt to expand for recipes and cuts.

### Screen 3: The UPI Micro-Transaction Sheet
**Goal:** Fast, native-feeling payment.

**Content:**
- Copy: "Don't buy stale fish. Unlock the AI Freshness Scanner for the weekend."
- Large price tag: ₹19.
- High-contrast CTA with UPI logo or GPay/PhonePe icons.
- Tapping opens the user's UPI app via deep link.

### Screen 4: The Machi Master Results View
**Goal:** Full dashboard after payment or full expansion.

**Sections:**
1. **Freshness gauge**
   - Minimal horizontal traffic light or circular gauge.
   - Example state: glowing green.
   - Supporting text: "98% Fresh. Clear eyes, bright red gills. Caught within 24 hours."

2. **Haggling & cut guide**
   - Two clean side-by-side squares.
   - Box 1: Best cut, e.g. Peti (Belly) & Gada (Back).
   - Box 2: Vendor alert, e.g. ask them to weigh before adding ice.

3. **Culinary hub**
   - Horizontal scrolling carousel of video cards.
   - YouTube thumbnails, heavily rounded corners.
   - Black play button overlay.
   - Recipe title beneath.

## UI/UX Handoff Summary

Tell designers:
- Design this like a high-end fintech app, not a crowded grocery app.
- Use pure black backgrounds and frosted glass UI.
- Let typography do the talking.
- The user should be able to scan, read the local name, and pay ₹19 with one thumb while holding a shopping bag.

## Image Generation Prompts

### Screen 1 Prompt
> UI/UX design of a minimalist mobile app camera screen, dark mode. The background is a heavily blurred live camera feed of a wet fish market. Floating at the top is a frosted glass pill containing a location pin. In the center of the screen, thin minimalist white focus brackets. At the bottom, a massive translucent frosted glass circular shutter button. Sleek, premium, high contrast, Dribbble style, 8k resolution --ar 9:16

### Screen 2 Prompt
> UI/UX design of a mobile app, pure true-black dark mode. A sleek bottom-sheet slides up over a blurred camera background. Inside the bottom sheet, massive geometric sans-serif typography reading "ROHU", and underneath in glowing neon cyan text "Local Name: Rui". Below the text is a wide pill-shaped button with a frosted glass texture, a padlock icon, and a subtle glowing gradient border. Minimalist, premium iOS aesthetic, Figma mockup --ar 9:16

### Screen 3 Prompt
> UI/UX design of a minimalist fintech payment mobile app screen, dark mode. A sleek overlay sheet with the text "Unlock the AI Freshness Scanner". Below it, massive bold typography displaying the price "₹19". At the bottom, a prominent, high-contrast action button featuring a generic payment logo. Clean typography, no clutter, glassmorphism UI elements, premium startup aesthetic --ar 9:16

### Screen 4 Prompt
> UI/UX design of a dark mode mobile app dashboard for food quality. Top section features a sleek, glowing green circular gauge indicating "98% Fresh". Middle section features a clean grid with two muted grey cards displaying text. Bottom section features a horizontal scrolling carousel of video thumbnails with heavily rounded corners and a play button overlay. Sans-serif typography, highly organized, Dribbble trending, iOS design --ar 9:16

## Notes for Agent Ingestion

- Keep the tone premium, minimalist, and dark.
- Preserve the hybrid architecture and offline-first emphasis.
- Preserve the monetization model with small UPI paywalls.
- Preserve the screen-by-screen product flow.
- This context should be treated as the master PRD blueprint for DesiCatch / Machi Master.

## Tip for Design Team

Run these prompts in Midjourney using the --ar 9:16 aspect ratio tag for phone screens, or drop them into ChatGPT Plus (DALL-E 3). Either tool will generate 4 variations per screen, giving the design team a visual baseline to start building the actual Figma components.