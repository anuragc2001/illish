# Illish — Future Enhancements Roadmap
> Last Updated: August 2026

This document lists all planned, discussed, and visionary future features for Illish.

---

## 🏗️ Near-Term (In Progress / Approved)

### 1. One-Time Migration: Set `isUnlocked = true` on All Pre-Existing Scans
- **Where:** `DBService.initialize()`
- **Why:** Scans taken before the paywall was introduced should all be unlocked by default.
- **Status:** Not yet implemented. Add a one-time flag check to migrate legacy scans.

### 2. Final Auth Sheet Verification
- Verify the full Email / Phone / Google authentication flows work end-to-end with the new sync logic.
- Test sign-out → sign-in on a fresh device to confirm calendar heatmap repopulates correctly.

---

## 🗓️ Calendar & Analytics

### 3. Animated Month-to-Month Swipe Transitions
- Add visible gap / padding between months during swipe so months don't overlap edge-to-edge.
- Consider adding a `SlideTransition` or `PageView` viewport fraction tweak (e.g., `viewportFraction: 0.95`) for a subtle peek effect.

### 4. Year View
- Add a pinch-to-zoom gesture on the calendar to switch from Monthly view → Yearly view.
- Yearly view shows a compact 12-month heatmap grid (GitHub contribution graph style).

### 5. Export / Share Stats
- Add a "Share My Stats" button to the Profile screen.
- Generate a shareable card image showing: Total Scans, Top Fish, Most Active Month, and a sample heatmap.

---

## 📷 Camera & Scanning

### 6. Meta Ray-Ban Smart Glasses Integration
- **Phase 1 (MVP):** Use the Meta Wearables Companion SDK to connect Illish's Flutter app to Ray-Ban glasses via Bluetooth.
- **Flow:** User says *"Hey Meta, scan this fish"* → glasses captures photo → sends to Flutter app → Gemini AI processes it → audio feedback through glasses speakers.
- **Tech:** Flutter (phone) + Meta Wearables SDK + Gemini API
- **Status:** Concept stage. Awaiting Meta Wearables Developer Program access.

### 7. Apple Vision Pro / Apple Glasses Integration
- Build a spatial SwiftUI companion app for visionOS.
- Display a floating holographic HUD with the freshness score, fish name badge, and market price when pointing at a fish.
- **Tech:** SwiftUI + RealityKit + ARKit + shared Firebase backend.
- **Status:** Concept stage. Pending Apple Vision Pro hardware.

### 8. Continuous Scan Mode (Live Feed)
- Instead of a single tap, allow a "stream mode" that continuously analyses frames every 2 seconds when pointed at a fish stall.
- Display a live freshness overlay on the camera preview in real-time.

---

## 🐟 AI & Intelligence

### 9. Price Negotiation Coach
- After scanning a fish and getting the market price, add an AI-powered negotiation tip: *"Vendors in Kolkata often accept 10–15% below asking price in the afternoon."*

### 10. Vendor Trickery Detection Improvements
- Expand the AI prompt to specifically detect ice injection (weight fraud), artificial coloring on gills, and formaldehyde preservation.
- Add a confidence score for each trickery flag.

### 11. Cross-Species Freshness Benchmarking
- Show a user's personal freshness trend: *"Your average Hilsa freshness this month is 92%, up from 78% last month. You're getting better at picking!"*

---

## 🔒 Monetization & Premium

### 12. Premium Scan History Archive
- Premium users get full image access for all historical scans (images stored in Firebase Storage indefinitely, not deleted after 30 days).
- Free users get text-only access to archived scans.

### 13. Family / Group Plans
- Allow multiple users to share a single premium subscription.
- Useful for households or wet market vendors who scan fish frequently.

---

## 🛡️ Infrastructure

### 14. Offline-First Mode Improvements
- Expand mock mode to include a richer set of mock fish data with varied freshness scores.
- Detect poor network quality proactively and offer offline mode before the scan fails.

### 15. Firebase Quota Monitoring
- Add internal analytics to track Firestore read/write counts per user per day.
- Alert the developer (via Firebase Alert) if read costs spike unexpectedly.
