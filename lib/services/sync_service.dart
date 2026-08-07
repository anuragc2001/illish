import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_service.dart';
import '../core/models/scan_record.dart';
import '../core/models/daily_scan_aggregate.dart';
import '../config/app_config.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static StreamSubscription? _syncSubscription;
  static StreamSubscription? _userSubscription;
  static StreamSubscription? _connectivitySubscription;
  static StreamSubscription? _aggSubscription;

  static String? get _uid => _auth.currentUser?.uid;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    if (ts is Timestamp) return ts.toDate();
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    try {
      if (ts.runtimeType.toString().contains('Timestamp')) {
        return (ts as dynamic).toDate();
      }
    } catch (_) {}
    return DateTime.now();
  }

  static Future<void> upgradeUserToPremium(String planId) async {
    if (_uid == null) return;
    try {
      DateTime expiry;
      switch (planId) {
        case 'weekly':
          expiry = DateTime.now().add(const Duration(days: 7));
          break;
        case 'monthly':
          expiry = DateTime.now().add(const Duration(days: 30));
          break;
        case 'annual':
          expiry = DateTime.now().add(const Duration(days: 365));
          break;
        default:
          expiry = DateTime.now().add(const Duration(days: 7));
      }

      // Update Firestore
      await _firestore.collection('users').doc(_uid).set({
        'isPremium': true,
        'premiumPlan': planId,
        'premiumExpiry': Timestamp.fromDate(expiry),
      }, SetOptions(merge: true));

      // Update local memory and cache
      AppConfig.isPremiumNotifier.value = true;
      AppConfig.premiumPlanNotifier.value = planId;
      AppConfig.premiumExpiryNotifier.value = expiry;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);
      await prefs.setString('premiumPlan', planId);
      await prefs.setString('premiumExpiry', expiry.toIso8601String());

    } catch (e) {
      debugPrint("Error upgrading user to premium in Firestore: $e");
    }
  }

  /// Call this when a new scan is created or updated locally
  static Future<void> upsertScanRecord(ScanRecord record) async {
    if (_uid == null) return;
    
    try {
      final docRef = _firestore.collection('users').doc(_uid).collection('scans').doc(record.id.toString());
      
      // Upload image to Firebase Storage if enabled and not already uploaded
      if (AppConfig.kSyncImagesToCloud && record.imagePath != null && !record.imagePath!.startsWith('http')) {
        try {
          final resolvedPath = DBService.getImagePath(record.imagePath);
          if (resolvedPath != null && File(resolvedPath).existsSync()) {
            final storageRef = _storage.ref().child('users/$_uid/scans/${record.id}.jpg');
            await storageRef.putFile(File(resolvedPath));
          }
        } catch (e) {
          debugPrint("Storage upload error: $e");
        }
      }

      await docRef.set({
        'id': record.id,
        'imagePath': record.imagePath,
        'englishName': record.englishName,
        'localName': record.localName,
        'region': record.region,
        'freshnessScore': record.freshnessScore,
        'freshnessStatus': record.freshnessStatus,
        'freshnessEvidence': record.freshnessEvidence,
        'bestCuts': record.bestCuts,
        'idealFor': record.idealFor,
        'trickeryTips': record.trickeryTips,
        'suggestedPrice': record.suggestedPrice,
        'marketAvgPrice': record.marketAvgPrice,
        'timestamp': record.timestamp.toIso8601String(),
        'isBookmark': record.isBookmark,
        'isUnlocked': record.isUnlocked,
        'isHidden': record.isHidden,
      }, SetOptions(merge: true));
      
      // Update local record as synced
      await DBService.isar.writeTxn(() async {
        final localRecord = await DBService.isar.scanRecords.get(record.id);
        if (localRecord != null) {
          localRecord.isSynced = true;
          await DBService.isar.scanRecords.put(localRecord);
        }
      });
      
    } catch (e) {
      debugPrint("Error syncing to Firestore: $e");
    }
  }

  /// Syncs the aggregate data to Firebase
  static Future<void> upsertDailyAggregate(DailyScanAggregate aggregate) async {
    if (_uid == null) return;
    try {
      final dateStr = aggregate.date.toIso8601String().split('T').first;
      final docRef = _firestore.collection('users').doc(_uid).collection('aggregates').doc(dateStr);
      
      await docRef.set({
        'date': aggregate.date.toIso8601String(),
        'totalScans': aggregate.totalScans,
        'topFishName': aggregate.topFishName,
        'fishCounts': aggregate.fishCounts,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error syncing aggregate to Firestore: $e");
    }
  }

  /// Marks a scan as permanently unlocked in Firestore
  static Future<void> unlockScanInCloud(int id) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('scans').doc(id.toString()).set({
        'isUnlocked': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error unlocking scan in Firestore: $e");
    }
  }

  /// Archives the scan by deleting cloud image and setting isArchived in Firestore
  static Future<void> archiveScanRecord(int id) async {
    if (_uid == null) return;
    try {
      if (AppConfig.kSyncImagesToCloud) {
        try {
          await _storage.ref().child('users/$_uid/scans/$id.jpg').delete();
        } catch (e) {
          debugPrint("Storage delete error (likely doesn't exist): $e");
        }
      }
      
      await _firestore.collection('users').doc(_uid).collection('scans').doc(id.toString()).update({
        'imagePath': null,
        'isArchived': true,
      });
    } catch (e) {
      debugPrint("Error archiving image from Firestore: $e");
    }
  }

  /// Call this when a scan is deleted locally
  static Future<void> deleteScanRecord(int id) async {
    if (_uid == null) return;
    
    try {
      await _firestore.collection('users').doc(_uid).collection('scans').doc(id.toString()).delete();
      
      if (AppConfig.kSyncImagesToCloud) {
        try {
          await _storage.ref().child('users/$_uid/scans/$id.jpg').delete();
        } catch (e) {
          debugPrint("Storage delete error (likely doesn't exist): $e");
        }
      }
    } catch (e) {
      debugPrint("Error deleting from Firestore: $e");
    }
  }

  static Future<void> _downloadImageIfNeeded(int id, String? imagePath) async {
    if (!AppConfig.kSyncImagesToCloud || _uid == null || imagePath == null) return;
    try {
      final localPath = '${AppConfig.documentsPath}/$imagePath';
      if (!File(localPath).existsSync()) {
        final storageRef = _storage.ref().child('users/$_uid/scans/$id.jpg');
        await storageRef.writeToFile(File(localPath));
      }
    } catch (e) {
      debugPrint("Error downloading image from storage: $e");
    }
  }

  /// Fetches archived scans on-demand from Firebase for a specific date
  static Future<List<ScanRecord>> fetchArchivedScansForDate(DateTime date) async {
    if (_uid == null) return [];
    
    try {
      // Find the start and end of the day in local time
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('scans')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ScanRecord()
          ..id = data['id'] ?? 0
          ..imagePath = data['imagePath']
          ..englishName = data['englishName']
          ..localName = data['localName']
          ..region = data['region']
          ..freshnessScore = data['freshnessScore']
          ..freshnessStatus = data['freshnessStatus']
          ..freshnessEvidence = data['freshnessEvidence']
          ..bestCuts = List<String>.from(data['bestCuts'] ?? [])
          ..idealFor = List<String>.from(data['idealFor'] ?? [])
          ..trickeryTips = List<String>.from(data['trickeryTips'] ?? [])
          ..suggestedPrice = data['suggestedPrice']
          ..marketAvgPrice = data['marketAvgPrice']
          ..timestamp = data['timestamp'] != null ? DateTime.parse(data['timestamp']) : DateTime.now()
          ..isBookmark = data['isBookmark'] ?? false
          ..isUnlocked = data['isUnlocked'] ?? false;
      }).toList();
    } catch (e) {
      debugPrint("Error fetching archived scans: $e");
      return [];
    }
  }

  /// Call this after logging in on a new device to fetch history
  static Future<void> syncFromCloudToLocal() async {
    if (_uid == null) {
      return;
    }
    
    bool hasCloudAggregates = false;
    
    // 1. Sync Aggregates from Firestore if available
    try {
      final aggSnapshot = await _firestore.collection('users').doc(_uid).collection('aggregates').get();
      if (aggSnapshot.docs.isNotEmpty) {
        hasCloudAggregates = true;
        for (var doc in aggSnapshot.docs) {
          final data = doc.data();
          final date = data['date'] != null ? DateTime.parse(data['date']) : null;
          if (date == null) continue;
          
          final agg = DailyScanAggregate()
            ..date = date
            ..totalScans = data['totalScans'] ?? 0
            ..topFishName = data['topFishName']
            ..fishCounts = List<String>.from(data['fishCounts'] ?? []);
            
          await DBService.isar.writeTxn(() async {
            await DBService.isar.dailyScanAggregates.put(agg);
          });
        }
      }
    } catch (e) {
      debugPrint("Error syncing aggregates from cloud: $e");
    }

    // 2. Sync Scans from Firestore
    try {
      final snapshot = await _firestore.collection('users').doc(_uid).collection('scans').get();
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          int? parsedId;
          if (data['id'] is int && data['id'] != 0) {
            parsedId = data['id'];
          } else if (int.tryParse(doc.id) != null) {
            parsedId = int.tryParse(doc.id);
          } else if (data['id'] is String && int.tryParse(data['id']) != null) {
            parsedId = int.tryParse(data['id']);
          }
          
          final record = ScanRecord()
            ..imagePath = data['imagePath']
            ..englishName = data['englishName']
            ..localName = data['localName']
            ..region = data['region']
            ..freshnessScore = _parseDouble(data['freshnessScore'])
            ..freshnessStatus = data['freshnessStatus']?.toString()
            ..freshnessEvidence = data['freshnessEvidence']?.toString()
            ..bestCuts = _parseStringList(data['bestCuts'])
            ..idealFor = _parseStringList(data['idealFor'])
            ..trickeryTips = _parseStringList(data['trickeryTips'])
            ..suggestedPrice = data['suggestedPrice']?.toString()
            ..marketAvgPrice = data['marketAvgPrice']?.toString()
            ..timestamp = _parseTimestamp(data['timestamp'])
            ..isBookmark = data['isBookmark'] ?? false
            ..isUnlocked = data['isUnlocked'] ?? false
            ..isHidden = data['isHidden'] ?? false
            ..isSynced = true;
            
          if (parsedId != null) {
            record.id = parsedId;
          }

          // Skip unknown or null scans
          final eName = record.englishName?.trim().toLowerCase() ?? '';
          if (eName.isEmpty || eName == 'unknown' || eName == 'unknown fish') {
            continue;
          }

          // If cloud aggregates did not exist, compute aggregates on the fly from scan history
          if (!hasCloudAggregates) {
            await DBService.isar.writeTxn(() async {
              await DBService.updateDailyAggregate(record);
            });
          }

          // Un-archive in Firebase if it was marked as archived
          if (data['isArchived'] == true) {
            await doc.reference.update({'isArchived': false});
          }

          // Save active scan to local Isar database
          await DBService.isar.writeTxn(() async {
            await DBService.isar.scanRecords.put(record);
          });
          
          // Download image if enabled
          await _downloadImageIfNeeded(record.id, record.imagePath);
        } catch (innerErr, stackTrace) {
          debugPrint("SYNC ERROR parsing/syncing doc ${doc.id}: $innerErr");
          debugPrint("SYNC ERROR STACKTRACE: $stackTrace");
        }
      }
    } catch (e) {
      debugPrint("Error syncing scans from cloud: $e");
    }
  }

  /// Forces a complete rebuild of all DailyScanAggregates by fetching all historical scans from Cloud.
  /// Populates local Isar DB with ALL scans and pushes rebuilt aggregates back to Firebase.
  static Future<void> forceRebuildAggregatesFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("forceRebuildAggregatesFromCloud: No current user logged in.");
      return;
    }
    final uid = user.uid;

    try {
      debugPrint("Starting full rebuild from Firestore for user $uid...");

      // 1. Fetch all scans ever made by the user from Firestore
      final snapshot = await _firestore.collection('users').doc(uid).collection('scans').get();
      debugPrint("Found ${snapshot.docs.length} scan records in Firestore.");

      if (snapshot.docs.isEmpty) {
        debugPrint("No cloud scans found for user $uid.");
        return;
      }

      // 2. Clear current local aggregates and scans
      await DBService.isar.writeTxn(() async {
        await DBService.isar.dailyScanAggregates.clear();
        await DBService.isar.scanRecords.clear();
      });

      final List<ScanRecord> recordsToSave = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Parse ID carefully: try data['id'], then doc.id, fallback to autoIncrement
          int? parsedId;
          if (data['id'] is int && data['id'] != 0) {
            parsedId = data['id'];
          } else if (int.tryParse(doc.id) != null) {
            parsedId = int.tryParse(doc.id);
          }

          final record = ScanRecord()
            ..imagePath = data['imagePath']
            ..englishName = data['englishName']
            ..localName = data['localName']
            ..region = data['region']
            ..freshnessScore = _parseDouble(data['freshnessScore'])
            ..freshnessStatus = data['freshnessStatus']?.toString()
            ..freshnessEvidence = data['freshnessEvidence']?.toString()
            ..bestCuts = _parseStringList(data['bestCuts'])
            ..idealFor = _parseStringList(data['idealFor'])
            ..trickeryTips = _parseStringList(data['trickeryTips'])
            ..suggestedPrice = data['suggestedPrice']?.toString()
            ..marketAvgPrice = data['marketAvgPrice']?.toString()
            ..timestamp = _parseTimestamp(data['timestamp'])
            ..isBookmark = data['isBookmark'] ?? false
            ..isUnlocked = data['isUnlocked'] ?? false;

          // Skip unknown or null scans
          final eName = record.englishName?.trim().toLowerCase() ?? '';
          if (eName.isEmpty || eName == 'unknown' || eName == 'unknown fish') continue;

          if (parsedId != null) {
            record.id = parsedId;
          }

          recordsToSave.add(record);
        } catch (innerErr) {
          debugPrint("Error parsing/rebuilding doc ${doc.id}: $innerErr");
        }
      }

      // 3. Save all scan records to local Isar & update aggregates
      await DBService.isar.writeTxn(() async {
        await DBService.isar.scanRecords.putAll(recordsToSave);
        for (var record in recordsToSave) {
          await DBService.updateDailyAggregate(record);
        }
      });

      // 4. Download images for records if needed
      for (var record in recordsToSave) {
        if (record.imagePath != null) {
          await _downloadImageIfNeeded(record.id, record.imagePath);
        }
      }

      // 5. Push freshly built aggregates back to Firebase
      final localAggs = await DBService.isar.dailyScanAggregates.where().findAll();
      for (var agg in localAggs) {
        await upsertDailyAggregate(agg);
      }

      debugPrint("Successfully restored ${recordsToSave.length} records and ${localAggs.length} aggregates to local Isar and pushed to cloud.");
    } catch (e, stack) {
      debugPrint("Error force rebuilding aggregates: $e\n$stack");
    }
  }

  /// Pushes existing local scans (e.g. taken as a guest) up to Firestore upon login
  static Future<void> syncLocalToCloud() async {
    if (_uid == null) return;
    try {
      final unsyncedScans = await DBService.isar.scanRecords.filter().isSyncedEqualTo(false).findAll();
      if (unsyncedScans.isNotEmpty) {
        debugPrint("Syncing ${unsyncedScans.length} offline scans to cloud...");
      }
      for (var scan in unsyncedScans) {
        await upsertScanRecord(scan);
      }
    } catch (e) {
      debugPrint("Error syncing local to cloud: $e");
    }
  }

  /// Starts a real-time listener so that if Phone A uploads a scan, Phone B downloads it instantly.
  static void startRealtimeSync() async {
    if (_uid == null) return;
    
    // Cancel any existing subscription
    _syncSubscription?.cancel();
    _userSubscription?.cancel();
    _connectivitySubscription?.cancel();
    
    // Auto-sync local scans if network becomes available
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncLocalToCloud(); // Push any offline scans taken while disconnected
      }
    });
    
    // Perform an immediate check on boot just in case the app was opened while already online
    Connectivity().checkConnectivity().then((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncLocalToCloud();
      }
    });
    
    // Ensure the user document exists in Firestore
    try {
      final userDocRef = _firestore.collection('users').doc(_uid);
      final docSnapshot = await userDocRef.get();
      if (!docSnapshot.exists) {
        await userDocRef.set({
          'isPremium': false,
          'createdAt': FieldValue.serverTimestamp(),
          'email': _auth.currentUser?.email,
          'displayName': _auth.currentUser?.displayName,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error creating user profile document: $e");
    }
    
    // Listen to user document for premium status
    _userSubscription = _firestore.collection('users').doc(_uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('isPremium')) {
          bool isPremium = data['isPremium'] == true;
          
          if (isPremium && data.containsKey('premiumExpiry')) {
            final expiryTs = data['premiumExpiry'];
            final expiry = _parseTimestamp(expiryTs);
            if (expiry.isBefore(DateTime.now())) {
              // Subscription expired!
              isPremium = false;
              // Silently downgrade in Firestore so it propagates everywhere
              _firestore.collection('users').doc(_uid).set({
                'isPremium': false,
              }, SetOptions(merge: true));
            } else {
              AppConfig.premiumPlanNotifier.value = data['premiumPlan'] ?? '';
              AppConfig.premiumExpiryNotifier.value = expiry;
            }
          }

          AppConfig.isPremiumUser = isPremium;

          // Sync to offline cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isPremium', isPremium);
          if (isPremium) {
            await prefs.setString('premiumPlan', AppConfig.premiumPlanNotifier.value);
            if (AppConfig.premiumExpiryNotifier.value != null) {
              await prefs.setString('premiumExpiry', AppConfig.premiumExpiryNotifier.value!.toIso8601String());
            }
          }
        }
      }
    });

    _aggSubscription?.cancel();

    // Listen to aggregates in real-time
    bool isInitialAggSnapshot = true;
    _aggSubscription = _firestore.collection('users').doc(_uid).collection('aggregates').snapshots().listen((snapshot) async {
      if (isInitialAggSnapshot) {
        isInitialAggSnapshot = false;
        final cloudAggDates = snapshot.docs.map((doc) => DateTime.tryParse(doc.id)).whereType<DateTime>().toSet();
        await DBService.isar.writeTxn(() async {
          final localAggs = await DBService.isar.dailyScanAggregates.where().findAll();
          for (var local in localAggs) {
            final dateOnly = DateTime(local.date.year, local.date.month, local.date.day);
            if (!cloudAggDates.any((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day)) {
              await DBService.isar.dailyScanAggregates.delete(local.id);
            }
          }
        });
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null && data['date'] != null) {
            final date = DateTime.tryParse(data['date']);
            if (date != null) {
              final agg = DailyScanAggregate()
                ..date = date
                ..totalScans = data['totalScans'] ?? 0
                ..topFishName = data['topFishName']
                ..fishCounts = List<String>.from(data['fishCounts'] ?? []);

              await DBService.isar.writeTxn(() async {
                await DBService.isar.dailyScanAggregates.put(agg);
              });
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
          final dateStr = change.doc.id;
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            await DBService.isar.writeTxn(() async {
              final existing = await DBService.isar.dailyScanAggregates.filter().dateEqualTo(date).findFirst();
              if (existing != null) {
                await DBService.isar.dailyScanAggregates.delete(existing.id);
              }
            });
          }
        }
      }
    });

    bool isInitialSnapshot = true;
    _syncSubscription = _firestore.collection('users').doc(_uid).collection('scans').snapshots().listen((snapshot) async {
      
      // Cold Boot Offline Deletion Sync
      if (isInitialSnapshot) {
        isInitialSnapshot = false;
        final cloudIds = snapshot.docs.map((doc) => int.tryParse(doc.id)).whereType<int>().toSet();
        
        await DBService.isar.writeTxn(() async {
          final localSyncedScans = await DBService.isar.scanRecords.filter().isSyncedEqualTo(true).findAll();
          for (var local in localSyncedScans) {
            if (!cloudIds.contains(local.id)) {
              // This record was synced before, but is now missing from the cloud (deleted offline).
              await DBService.isar.scanRecords.delete(local.id);
              if (local.imagePath != null) {
                final localFile = File('${AppConfig.documentsPath}/${local.imagePath}');
                if (localFile.existsSync()) localFile.deleteSync();
              }
            }
          }
        });
      }

      for (var change in snapshot.docChanges) {
        if (change.doc.metadata.hasPendingWrites) continue;
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          
          if (data['isArchived'] == true) {
            // Delete locally to maintain the limit if another device archived it
            final id = data['id'];
            if (id != null) {
              await DBService.isar.writeTxn(() async {
                final localRecord = await DBService.isar.scanRecords.get(id);
                if (localRecord != null) {
                  await DBService.isar.scanRecords.delete(id);
                  if (localRecord.imagePath != null) {
                    final localFile = File('${AppConfig.documentsPath}/${localRecord.imagePath}');
                    if (localFile.existsSync()) localFile.deleteSync();
                  }
                }
              });
            }
            continue;
          }
          
          try {
            final record = ScanRecord()
              ..id = data['id'] ?? Isar.autoIncrement
              ..imagePath = data['imagePath']
              ..englishName = data['englishName']
              ..localName = data['localName']
              ..region = data['region']
              ..freshnessScore = _parseDouble(data['freshnessScore'])
              ..freshnessStatus = data['freshnessStatus']?.toString()
              ..freshnessEvidence = data['freshnessEvidence']?.toString()
              ..bestCuts = _parseStringList(data['bestCuts'])
              ..idealFor = _parseStringList(data['idealFor'])
              ..trickeryTips = _parseStringList(data['trickeryTips'])
              ..suggestedPrice = data['suggestedPrice']?.toString()
              ..marketAvgPrice = data['marketAvgPrice']?.toString()
              ..timestamp = _parseTimestamp(data['timestamp'])
              ..isBookmark = data['isBookmark'] ?? false
              ..isUnlocked = data['isUnlocked'] ?? false
              ..isHidden = data['isHidden'] ?? false
              ..isSynced = true;

            // Skip unknown scans
            final eName = record.englishName?.toLowerCase() ?? '';
            if (eName == 'unknown' || eName == 'unknown fish') continue;

            // Save to local Isar database (upsert)
            await DBService.isar.writeTxn(() async {
              await DBService.isar.scanRecords.put(record);
            });
            
            // Download image if enabled
            await _downloadImageIfNeeded(record.id, record.imagePath);
          } catch (innerErr) {
            debugPrint("Error parsing/syncing doc in realtime listener: $innerErr");
          }
        } else if (change.type == DocumentChangeType.removed) {
          final docId = int.tryParse(change.doc.id);
          if (docId != null) {
            // Delete locally if deleted from cloud
            await DBService.isar.writeTxn(() async {
              final localRecord = await DBService.isar.scanRecords.get(docId);
              if (localRecord != null) {
                await DBService.isar.scanRecords.delete(docId);
                // Clean up the image file too
                if (localRecord.imagePath != null) {
                  final localFile = File('${AppConfig.documentsPath}/${localRecord.imagePath}');
                  if (localFile.existsSync()) localFile.deleteSync();
                }
              }
            });
          }
        }
      }
    });
  }

  static void stopRealtimeSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
    _userSubscription?.cancel();
    _userSubscription = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _aggSubscription?.cancel();
    _aggSubscription = null;
    AppConfig.isPremiumUser = false;
  }
}
