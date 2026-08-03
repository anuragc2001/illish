# Illish — Engineering Walkthrough
> Last Updated: August 2026

This document summarizes all changes made during the calendar UI revamp and analytics architecture overhaul.

---

## 1. New File: `lib/core/models/daily_scan_aggregate.dart`
A new lightweight Isar collection model to store per-day analytics.

**Fields:**
- `date` — Indexed unique date key
- `totalScans` — Total fish scans for that day
- `topFishName` — Most frequently scanned fish (normalized)
- `fishCounts` — List of `"FishName:Count"` strings

---

## 2. `lib/services/db_service.dart` — Major Changes

### New Methods:
- `formatAmPm(DateTime dt)` — Explicit 12-hour AM/PM formatter (bypasses system locale issues)
- `normalizeFishName(String? name)` — Strips parenthetical scientific names, standardizes casing
- `updateDailyAggregate(ScanRecord record)` — Populates or updates the `DailyScanAggregate` for a given scan
- `_migrateLegacyScansToAggregates()` — One-time migration on app init to build aggregate data from existing scans

### Modified:
- `initialize()` — Opens `DailyScanAggregateSchema` alongside existing schemas; triggers migration
- `saveScan()` — Calls `updateDailyAggregate()` after saving; changed retention from **15-item limit** to **30-day rolling window**
- `unlockScan(int id)` — Always calls `SyncService.unlockScanInCloud(id)` regardless of whether the scan is in local Isar
- `clearAll()` — Now also clears `dailyScanAggregates` on sign-out

---

## 3. `lib/services/sync_service.dart` — Major Changes

### New Methods:
- `upsertDailyAggregate(DailyScanAggregate aggregate)` — Syncs aggregate to Firestore `aggregates/` collection
- `fetchArchivedScansForDate(DateTime date)` — Fetches archived scan text records from Firestore for a specific date (in-memory, not re-saved to local DB)
- `unlockScanInCloud(int id)` — Permanently sets `isUnlocked: true` in Firestore

### Modified `syncFromCloudToLocal()`:
- Now uses a **two-phase strategy**:
  1. Sync `aggregates/` from Firestore first (preferred source)
  2. Then sync `scans/` — if no cloud aggregates existed, compute them on the fly from scan data
- Archived scans (`isArchived: true`) are skipped for local Isar but still used for aggregate computation (legacy mode)

---

## 4. `lib/screens/profile_screen.dart` — Calendar UI Revamp

### State Changes:
- Replaced `Map<DateTime, List<ScanRecord>> _dailyScans` with `Map<DateTime, DailyScanAggregate> _dailyAggregates`
- Added `DateTime? _selectedDate` for two-step pill interaction

### UI Changes:
- `_loadAnalytics()` now queries `dailyScanAggregates` instead of raw `scanRecords`
- Calendar heatmap uses `DailyScanAggregate.totalScans` for density calculation
- Tapping a date now **selects** the date (showing a white ring border) rather than immediately opening the bottom sheet
- **Floating Glassmorphic Pill** appears when a date is selected, showing `totalScans` and `topFishName`
- Tapping the pill opens the detailed bottom sheet

### New Methods:
- `_fetchAndShowDailyScansDialog(DateTime date)` — Checks local Isar first; falls back to `SyncService.fetchArchivedScansForDate()` for older dates
- All list items in the daily detail bottom sheet enforce the **paywall lock**:
  - Unlocked scans → navigate to `ResultsScreen`
  - Locked scans → open `RecognitionSheet` (ad/premium gate)
  - After ad is watched, modal auto-refreshes with the new unlock state

### AM/PM Fix:
- Replaced `TimeOfDay.format(context)` with `DBService.formatAmPm()` everywhere to guarantee correct 12-hour display regardless of device locale settings

---

## 5. `lib/screens/results_screen.dart`
- Added `.toLocal()` to `DateTime.parse(timestamp)` call
- Added explicit AM/PM computation instead of `TimeOfDay.format()`

---

## 6. `lib/screens/camera_screen.dart`
- Updated recent scan list item subtitle to display `DBService.formatAmPm()` timestamp
