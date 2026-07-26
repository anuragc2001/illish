# Illish — Feature Roadmap & Monetization Strategy

Based on a deep review of [CONTEXT.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/CONTEXT.md), [FUTURE_ENHANCEMENTS.md](file:///Users/anuragchakraborty/Code/ios%20Projects/illish/FUTURE_ENHANCEMENTS.md), and your full codebase.

---

## Part 1: Features & Enhancements

### 🔴 High Impact — Build These First

#### 1. Real-Time Fish Detection (Live Viewfinder Feedback)
**Status:** Listed in FUTURE_ENHANCEMENTS but not started.  
**Why it matters:** Right now, users can photograph literally anything (their shoe, a table) and the app will happily send it to Gemini. This wastes API credits, annoys users with nonsense results, and feels unpolished.

**What to build:**
- Use `google_mlkit_image_labeling` or a lightweight custom TFLite model
- Hook into `CameraController.startImageStream()` 
- Show a **red reticle** when no fish is detected: *"Point camera at a fish"*
- Show a **green reticle** when fish is detected: *"Fish detected — Tap to scan"*
- Optionally **disable the shutter button** until a fish is detected

**Difficulty:** Medium. The ML Kit labeling API works on-device with zero latency.

---

#### 2. Multi-Fish Scanning (Stall Overview Mode)
**Why it matters:** At a wet market, a vendor's stall has 5-10 different fish laid out. Right now the user must scan each one individually. A "stall scan" mode would be a massive differentiator.

**What to build:**
- A "Stall Mode" toggle on the camera screen
- Capture one wide photo of the entire stall
- Use Gemini's vision to identify *all* visible species in the frame
- Return a scrollable card list: each fish with its local name, estimated freshness, and price range
- This is a **premium feature** (see monetization below)

---

#### 3. Price Intelligence ("Is this price fair?")
**Why it matters:** Your CONTEXT.md says the mission is to help users *"avoid being cheated on price"*. But the app currently has zero pricing data. This is the single biggest unbuilt feature from your original PRD.

**What to build:**
- After identifying a fish species + location, query Gemini for: *"What is the typical retail price range for [fish] in [city] in [month]?"*
- Display a price range bar: ₹300-₹450/kg with the market average highlighted
- Seasonal pricing context: *"Hilsa prices peak during monsoon (July-Aug)"*
- Let users **report** the price they paid (crowdsource data over time)

---

#### 4. Scan History Timeline (with Stats)
**Why it matters:** You already have Isar storing scans, but there is no way for users to see their scanning patterns over time. A timeline view transforms a utility into a habit.

**What to build:**
- A full-screen "My Scans" page (not just the bottom sheet)
- Calendar heatmap showing scan frequency (like GitHub contributions)
- Stats: "You've scanned 47 fish this month", "Most scanned: Rohu (12 times)"
- Filter by: species, freshness rating, date range
- Share stats as an image (social virality)

---

### 🟡 Medium Impact — Build After Core Features

#### 5. Vendor Trust Score / Vendor Profiles
**Why it matters:** Users go to the same vendors repeatedly. If they could rate and track vendors, it adds massive stickiness.

**What to build:**
- After a scan, prompt: *"Which vendor sold this?"* (optional text input or GPS-tagged stall)
- Track freshness scores per vendor over time
- "Your fishmonger's average freshness: 87% 🟢"
- Anonymous, aggregated vendor ratings visible to nearby users

---

#### 6. Social Sharing & Scan Cards
**Why it matters:** Fish buying is inherently social — *"Mom, look what I got at the market!"*. Shareable scan cards drive organic installs.

**What to build:**
- A beautiful, branded "Scan Card" image generated from results
- Contains: fish photo, species name, freshness score ring, location
- One-tap share to WhatsApp, Instagram Stories
- Include a subtle "Scanned with Illish" watermark + App Store link

---

#### 7. Seasonal Fish Calendar
**Why it matters:** Different fish are in season at different times. A calendar helps users know what to expect at the market *before* they go.

**What to build:**
- A monthly calendar view showing which species are in season for the user's region
- "Best fish to buy this week in Kolkata: Hilsa, Pabda, Chingri"
- Push notifications: *"Hilsa season starts next week! 🐟"*

---

#### 8. Recipe Bookmarking & Cooking Mode
**Why it matters:** You already show YouTube recipe links, but users can't save them or access them while cooking (when their hands are wet/busy).

**What to build:**
- "Save Recipe" button on each YouTube card
- A dedicated "My Recipes" tab
- "Cooking Mode": large text, step-by-step view, screen stays awake
- Voice-controlled navigation: *"Next step"* (using speech recognition)

---

### 🟢 Polish & Optimization

#### 9. Camera Lifecycle Optimization
**Status:** Listed in FUTURE_ENHANCEMENTS (#4).  
Your `camera_screen.dart` is **56KB / 1421 lines** — it's doing too much.

**What to fix:**
- Pause camera stream when navigating to Results/Recognition screens
- Resume on pop without black screen flicker
- Extract camera logic into a `CameraService` class

---

#### 10. Architecture Refactoring (Riverpod)
**Status:** Listed in FUTURE_ENHANCEMENTS (#6).

**What to fix:**
- Migrate from `setState()` to Riverpod providers
- Separate concerns: `CameraNotifier`, `ScanNotifier`, `LocationNotifier`
- Makes testing, state management, and feature additions dramatically easier

---

#### 11. Image Compression Before API Call
**Why:** Phone cameras capture 12-48MP images. Sending a raw 8MB photo to Gemini wastes bandwidth (critical in wet markets with poor signal) and increases latency.

**What to fix:**
- Compress images to ~1MB before sending to Gemini
- Use `image` package or `flutter_image_compress`
- Target 1024x1024 resolution — more than enough for fish identification

---

#### 12. Haptic Feedback & Sound Design
**Why:** The app feels "silent". Premium apps use subtle haptics and sounds.

**What to add:**
- Light haptic on shutter tap (`HapticFeedback.mediumImpact()`)
- Subtle "scan complete" haptic when AI results arrive
- Optional shutter sound effect

---

## Part 2: Monetization Strategy

### Current State
Your CONTEXT.md mentions a ₹19-₹29 UPI micro-transaction model. You have a `payment_sheet.dart` that's currently hidden from the flow. Let's build a real monetization engine.

---

### Model A: Freemium with Daily Scan Limits (Recommended)

| Tier | Price | What You Get |
|------|-------|-------------|
| **Free** | ₹0 | 3 scans/day. Species ID + local name + cuts & recipes. No freshness score. |
| **Weekend Pass** | ₹19 | Unlimited scans for 48 hours. Full freshness AI. Price intelligence. |
| **Monthly Pro** | ₹99/month | Unlimited everything. Multi-fish stall scan. Vendor tracking. Priority API. |
| **Annual Pro** | ₹499/year | Same as Monthly but ~58% cheaper. Best value. |

**Why this works:**
- Free tier gives enough value to hook daily users (species ID alone is useful)
- ₹19 weekend pass captures the "Saturday morning market run" impulse buy
- The freshness score is the perfect paywall gate — users *need* it when spending ₹500+ on fish

**Implementation:**
- Store subscription state in `SharedPreferences` (you already have it as a dependency)
- For server-verified purchases, use `in_app_purchase` package (handles both App Store & Play Store)
- Gate the freshness score section in `ResultsScreen` behind a blur + unlock button

---

### Model B: Per-Scan Credits (Simpler)

| Credits | Price |
|---------|-------|
| 5 scans | ₹29 |
| 15 scans | ₹69 |
| 50 scans | ₹149 |

- Simpler to implement (just a counter in Isar)
- Works well with UPI deep links (no App Store/Play Store cut)
- But users hate "running out" of credits — higher churn risk

---

### Model C: Affiliate Revenue (Passive, Long-Term)

- Partner with online fish delivery services (FreshToHome, Licious, BigBasket)
- After a scan, show: *"Get fresh [Rohu] delivered to your door — Order on FreshToHome"*
- Earn affiliate commission per order (typically 5-15%)
- Zero friction for users, and it actually adds value

---

### Model D: B2B / Enterprise (Scale Play)

- License the AI scanning engine to:
  - **Restaurants & Hotels** (quality control on incoming fish deliveries)
  - **Fish export companies** (automated freshness grading at scale)
  - **Government food safety inspectors**
- Charge ₹5,000-₹25,000/month per business
- This is the long-term play if the AI model proves accurate enough

---

## Part 3: Quick Wins (Can Build This Weekend)

These require minimal code changes but significantly improve the app:

| Quick Win | Effort | Impact |
|-----------|--------|--------|
| Add haptic feedback on shutter tap | 1 line | Feels premium |
| Compress images before API call | ~20 lines | 2-3x faster scans on slow networks |
| Add "Share Scan" button on Results | ~50 lines | Organic growth |
| Show scan count on home screen | ~10 lines | Gamification / engagement |
| Add a simple onboarding carousel (3 slides) | ~100 lines | Reduces first-use confusion |
| Animate the location pill on camera screen | ~15 lines | Polish |

---

## Recommended Priority Order

1. **Image compression** (quick win, huge UX impact at markets)
2. **Share scan cards** (organic growth engine)
3. **Real-time fish detection** (core differentiator)
4. **Price intelligence** (fulfills original PRD promise)
5. **Freemium paywall** (revenue)
6. **Multi-fish stall scan** (premium feature)
7. **Architecture refactor** (enables everything else faster)
