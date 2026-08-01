import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'db_service.dart';
import '../core/models/scan_record.dart';
import '../config/app_config.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static StreamSubscription? _syncSubscription;
  static StreamSubscription? _userSubscription;

  static String? get _uid => _auth.currentUser?.uid;

  /// Call this when a new scan is created or updated locally
  static Future<void> upsertScanRecord(ScanRecord record) async {
    if (_uid == null) return;
    
    try {
      final docRef = _firestore.collection('users').doc(_uid).collection('scans').doc(record.id.toString());
      
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
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint("Error syncing to Firestore: $e");
    }
  }

  /// Call this when a scan is deleted locally
  static Future<void> deleteScanRecord(int id) async {
    if (_uid == null) return;
    
    try {
      await _firestore.collection('users').doc(_uid).collection('scans').doc(id.toString()).delete();
    } catch (e) {
      debugPrint("Error deleting from Firestore: $e");
    }
  }

  /// Call this after logging in on a new device to fetch history
  static Future<void> syncFromCloudToLocal() async {
    if (_uid == null) return;
    
    try {
      final snapshot = await _firestore.collection('users').doc(_uid).collection('scans').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        final record = ScanRecord()
          ..id = data['id'] ?? Isar.autoIncrement
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
          ..isBookmark = data['isBookmark'] ?? false;

        // Save to local Isar database
        await DBService.isar.writeTxn(() async {
          await DBService.isar.scanRecords.put(record);
        });
      }
    } catch (e) {
      debugPrint("Error syncing from cloud: $e");
    }
  }

  /// Pushes existing local scans (e.g. taken as a guest) up to Firestore upon login
  static Future<void> syncLocalToCloud() async {
    if (_uid == null) return;
    try {
      final localScans = await DBService.isar.scanRecords.where().findAll();
      for (var scan in localScans) {
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
    _userSubscription = _firestore.collection('users').doc(_uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('isPremium')) {
          AppConfig.isPremiumUser = data['isPremium'] == true;
        }
      }
    });

    _syncSubscription = _firestore.collection('users').doc(_uid).collection('scans').snapshots().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          
          final record = ScanRecord()
            ..id = data['id'] ?? Isar.autoIncrement
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
            ..isBookmark = data['isBookmark'] ?? false;

          // Save to local Isar database (upsert)
          await DBService.isar.writeTxn(() async {
            await DBService.isar.scanRecords.put(record);
          });
        } else if (change.type == DocumentChangeType.removed) {
          final data = change.doc.data();
          if (data != null && data['id'] != null) {
            // Delete locally if deleted from cloud
            await DBService.isar.writeTxn(() async {
              await DBService.isar.scanRecords.delete(data['id']);
            });
          }
        }
      }
    });
  }

  /// Stop the listener (e.g. on sign out)
  static void stopRealtimeSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
    _userSubscription?.cancel();
    _userSubscription = null;
    AppConfig.isPremiumUser = false;
  }
}
