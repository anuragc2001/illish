# Illish — Session Context & Architecture Notes
> Last Updated: August 2026

## Overview
This document captures the architectural decisions, data flow, and engineering context from the major calendar/analytics overhaul session.

---

## Data Architecture

### 1. Local Isar Database (On-Device)
Two primary collections:

| Collection | Purpose | Retention |
|---|---|---|
| `ScanRecord` | Full AI scan result + image path | 30-day rolling window |
| `DailyScanAggregate` | Lightweight heatmap data (counts, top fish per day) | Forever (never deleted) |
| `RecipeCache` | Cached AI recipe responses | 7 days |

### 2. Firebase Cloud
| Collection | Purpose |
|---|---|
| `users/{uid}/scans/{scanId}` | Full scan text data. Active scans have image links; archived scans have `imagePath: null, isArchived: true` |
| `users/{uid}/aggregates/{dateStr}` | DailyScanAggregate mirror. Permanently backed up. |

### 3. Firebase Storage
| Path | Purpose | Retention |
|---|---|---|
| `users/{uid}/scans/{scanId}.jpg` | Full resolution scan image | Deleted when scan is archived (>30 days old) |

---

## Data Lifecycle (30-Day Rolling Window)

```
Day 0: User scans a fish
  → Image saved to phone Documents folder
  → ScanRecord saved to local Isar
  → ScanRecord synced to Firestore
  → Image uploaded to Firebase Storage
  → DailyScanAggregate updated locally + Firestore

Day 1–30: Data fully available
  → Image on phone + Firebase Storage
  → Full text data in local Isar + Firestore
  → Aggregate heatmap data locally + Firestore

Day 31+: Automatic archiving (triggered on next scan)
  → Local image file DELETED from phone Documents
  → Local ScanRecord DELETED from Isar
  → Firebase Storage image DELETED
  → Firestore record updated: isArchived=true, imagePath=null
  → DailyScanAggregate KEPT FOREVER (local + cloud)
```

---

## Sign In / Sign Out Flow

### On Sign In:
1. Check Firestore `aggregates/` collection first.
2. If aggregates exist → download them directly to local Isar.
3. Download active (non-archived) `scans/` → save to local Isar + download images.
4. If no cloud aggregates existed → compute from scan history on-the-fly.

### On Sign Out:
- `DBService.clearAll()` wipes both `scanRecords` AND `dailyScanAggregates` from the phone.
- All local image files are deleted.
- Firebase cloud data is preserved.

---

## Fish Name Normalization

AI sometimes returns inconsistent names like:
- `"Rui (Labeo Rohita)"`
- `"Rui (Rohu)"`
- `"ROHU"`

These are all the same fish. The `DBService.normalizeFishName()` method:
1. Strips anything inside parentheses.
2. Trims whitespace.
3. Capitalizes the first letter, lowercases the rest.

Result: All variants become → `"Rui"`

This normalization is applied to all `DailyScanAggregate` calculations, `Top Fish` stat, and `Species Breakdown`.

---

## Unlock / Paywall Logic

- Each `ScanRecord` has `isUnlocked: bool`.
- When a user watches an ad via `PaymentSheet`:
  1. `DBService.unlockScan(id)` sets `isUnlocked = true` in local Isar (if record exists).
  2. `SyncService.unlockScanInCloud(id)` always updates Firestore, even if the scan is archived.
- The unlock is **permanent and cross-device** (stored in Firestore).
- On next cloud sync, `isUnlocked: true` is restored from Firestore.
