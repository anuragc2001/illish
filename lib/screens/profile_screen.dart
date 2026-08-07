import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import '../services/db_service.dart';
import '../core/theme.dart';
import '../config/app_config.dart';
import '../core/models/scan_record.dart';
import '../services/auth_service.dart';
import 'camera_screen.dart';
import 'widgets/email_auth_sheet.dart';
import 'widgets/phone_auth_sheet.dart';
import 'results_screen.dart';
import 'recognition_sheet.dart';
import '../core/models/daily_scan_aggregate.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import 'widgets/freshness_meter.dart';
import 'payment_sheet.dart';
import '../services/remote_config_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool returnAfterSignIn;
  const ProfileScreen({Key? key, this.returnAfterSignIn = false})
    : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isAnalyticsLoading = true;
  int _totalScans = 0;
  int _monthTotalScans = 0;
  String _topFish = "--";
  Map<DateTime, int> _scanHeatmap = {};
  Map<String, int> _fishCounts = {};
  Map<DateTime, DailyScanAggregate> _dailyAggregates = {};
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _selectedDate;
  late DateTime _baseMonth;
  late PageController _pageController;
  StreamSubscription? _isarSub;
  StreamSubscription? _aggSub;
  StreamSubscription? _authSub;
  Timer? _debounceTimer;

  void _debouncedLoadAnalytics() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _loadAnalytics();
    });
  }

  @override
  void initState() {
    super.initState();
    _baseMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _pageController = PageController(initialPage: 1200);

    _syncAndLoadAnalytics();

    // Listen to changes in Isar to auto-update when SyncService pulls down cloud data
    if (DBService.isInitialized) {
      try {
        _isarSub = DBService.isar.scanRecords.watchLazy().listen((_) {
          if (mounted) _debouncedLoadAnalytics();
        });
        _aggSub = DBService.isar.dailyScanAggregates.watchLazy().listen((_) {
          if (mounted) _debouncedLoadAnalytics();
        });
      } catch (e) {
        debugPrint("Error setting up Isar listeners in ProfileScreen: $e");
      }
    }

    if (widget.returnAfterSignIn) {
      _authSub = AuthService.authStateChanges.listen((user) {
        if (user != null && mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isarSub?.cancel();
    _aggSub?.cancel();
    _authSub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int _avgFreshnessScore = 0;

  Future<void> _syncAndLoadAnalytics() async {
    if (mounted) setState(() => _isAnalyticsLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Only trigger explicit cloud sync once per explicit load
        await SyncService.syncFromCloudToLocal();
      } else {
        // Fallback for guests if local DB is completely empty
        var aggregates = await DBService.isar.dailyScanAggregates
            .where()
            .findAll();
        var allScanRecords = await DBService.isar.scanRecords.where().findAll();
        if (aggregates.isEmpty && allScanRecords.isEmpty) {
          await SyncService.syncFromCloudToLocal();
        }
      }
    } catch (e) {
      debugPrint("Error syncing analytics: $e");
    }

    await _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!DBService.isInitialized) return;

    try {
      var aggregates = await DBService.isar.dailyScanAggregates
          .where()
          .findAll();
      var allScanRecords = await DBService.isar.scanRecords.where().findAll();

      // Filter clean scan records for monthly calculations
      final cleanScanRecords = allScanRecords.where((s) {
        final eName = s.englishName?.trim().toLowerCase() ?? '';
        return eName.isNotEmpty &&
            eName != 'unknown' &&
            eName != 'unknown fish';
      }).toList();

      final targetMonth = DateTime.now(); // Current real-world month

      // --- 1. ALL-TIME METRICS (from Aggregate DB) ---
      int allTimeTotalScans = 0;
      Map<String, int> allTimeFishCounts = {};
      Map<DateTime, int> heatmap = {};
      Map<DateTime, DailyScanAggregate> dailyMap = {};

      for (var agg in aggregates) {
        allTimeTotalScans += agg.totalScans;
        heatmap[agg.date] = agg.totalScans;
        dailyMap[agg.date] = agg;

        for (var fc in agg.fishCounts) {
          final parts = fc.split(':');
          if (parts.length == 2) {
            final name = parts[0].trim();
            final lowerName = name.toLowerCase();
            if (lowerName != 'unknown' &&
                lowerName != 'unknown fish' &&
                lowerName.isNotEmpty) {
              final count = int.tryParse(parts[1]) ?? 0;
              allTimeFishCounts[name] = (allTimeFishCounts[name] ?? 0) + count;
            }
          }
        }
      }

      // Fallbacks if aggregates DB was empty/new
      if (aggregates.isEmpty && cleanScanRecords.isNotEmpty) {
        allTimeTotalScans = cleanScanRecords.length;
      }

      if (allTimeFishCounts.isEmpty && cleanScanRecords.isNotEmpty) {
        for (var s in cleanScanRecords) {
          final name = DBService.normalizeFishName(s.englishName);
          if (name != 'Unknown') {
            allTimeFishCounts[name] = (allTimeFishCounts[name] ?? 0) + 1;
          }
        }
      }

      String topFish = "--";
      if (allTimeFishCounts.isNotEmpty) {
        var sorted = allTimeFishCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topFish = sorted.first.key;
      }

      // --- 2. MONTHLY METRICS (from Scan DB) ---
      final currentMonthRecords = cleanScanRecords.where((s) {
        final localDate = s.timestamp.toLocal();
        return localDate.year == targetMonth.year &&
            localDate.month == targetMonth.month;
      }).toList();

      int monthTotalScans = currentMonthRecords.length;

      double totalFreshnessSum = 0;
      int freshnessCount = 0;

      for (var scan in currentMonthRecords) {
        if (scan.freshnessScore != null && scan.freshnessScore! > 0.0) {
          double score = scan.freshnessScore!;
          if (score <= 1.0) score = score * 100; // normalize 0-1.0 to 0-100
          totalFreshnessSum += score;
          freshnessCount++;
        }
      }

      int avgFreshness = freshnessCount > 0
          ? (totalFreshnessSum / freshnessCount).round()
          : 0;

      if (mounted) {
        setState(() {
          _totalScans = allTimeTotalScans;
          _monthTotalScans = monthTotalScans;
          _avgFreshnessScore = avgFreshness;
          _topFish = topFish;
          _scanHeatmap = heatmap;
          _fishCounts = allTimeFishCounts;
          _dailyAggregates = dailyMap;
        });
      }
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyticsLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    _setLoading(true);
    await AuthService.signInWithApple();
    _setLoading(false);
    _syncAndLoadAnalytics();
  }

  void _showEmailAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmailAuthSheet(),
    ).then((_) => _syncAndLoadAnalytics());
  }

  void _showPhoneAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneAuthSheet(),
    ).then((_) => _syncAndLoadAnalytics());
  }

  void _setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    await AuthService.signInWithGoogle();
    _setLoading(false);
    _syncAndLoadAnalytics();
  }

  Future<void> _handleAnonSignIn() async {
    _setLoading(true);
    await AuthService.signInAnonymously();
    _setLoading(false);
    _loadAnalytics();
  }

  Future<void> _handleSignOut() async {
    _setLoading(true);
    await AuthService.signOut();
    _setLoading(false);
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      }
    }
  }

  Widget _buildNotificationBell() {
    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: NotificationService().notifications,
      builder: (context, notificationsList, child) {
        final count = notificationsList.length;
        return GestureDetector(
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) =>
                  const NotificationDialog(),
              transitionBuilder: (context, anim1, anim2, child) {
                return Transform.scale(
                  scale: Curves.easeOutBack.transform(anim1.value),
                  alignment: Alignment.topRight,
                  child: Opacity(opacity: anim1.value, child: child),
                );
              },
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 28,
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Mode First
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "illish",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.neonCyan,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Spacer(),
                    _buildNotificationBell(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!DBService.isInitialized && DBService.lastError != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    border: Border.all(color: Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DATABASE ERROR (PLEASE SCREENSHOT):",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DBService.lastError!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // User Info & Freshness Meter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<User?>(
                  stream: AuthService.authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isLoggedIn = user != null;
                    final displayName = user?.displayName ?? "Guest";
                    // Only take first name for the greeting
                    final firstName = displayName.split(' ').first;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Header
                        ValueListenableBuilder<bool>(
                          valueListenable: AppConfig.isPremiumNotifier,
                          builder: (context, isPremium, child) {
                            final showPremium = isLoggedIn && isPremium;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!showPremium)
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            RemoteConfigService.enablePayment,
                                        builder: (context, paymentEnabled, child) {
                                          return paymentEnabled
                                              ? ShimmeringPremiumButton(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const PaymentScreen(
                                                              aiData: {},
                                                              scanId: null,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const SizedBox.shrink();
                                        },
                                      )
                                    else
                                      Text(
                                        "ILLISH PRO",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    Text(
                                      "Hi, $firstName!",
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                // Profile Avatar with Subtle Premium Ring & PRO Badge
                                GestureDetector(
                                  onTap: () => _showUserMenu(context),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          showPremium ? 2 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: showPremium
                                              ? const LinearGradient(
                                                  colors: [
                                                    Colors.amber,
                                                    Colors.orangeAccent,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                        ),
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: user?.photoURL != null
                                              ? Image.network(
                                                  user!.photoURL!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                        ),
                                      ),
                                      if (showPremium)
                                        Positioned(
                                          bottom: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.amber,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 10,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  "PRO",
                                                  style: GoogleFonts.inter(
                                                    color: Colors.amber,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Freshness Meter (Average Freshness Rating %)
                        if (isLoggedIn && _totalScans > 0) ...[
                          if (_isAnalyticsLoading)
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppTheme.neonCyan,
                                    strokeWidth: 2.5,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Syncing freshness data...",
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            FreshnessMeter(
                              score: _avgFreshnessScore,
                              maxScore: 100,
                            ),
                          if (_fishCounts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showSpeciesBreakdownSheet(),
                                icon: const Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  "View Species Breakdown (Option 1)",
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.neonCyan,
                                  side: BorderSide(
                                    color: AppTheme.neonCyan.withOpacity(0.5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],

                        // Auth Actions
                        if (_isLoading) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.neonCyan,
                            ),
                          ),
                        ] else if (!isLoggedIn) ...[
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _handleGoogleSignIn,
                                  icon: const Icon(
                                    Icons.login,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Sign in with Google",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.neonCyan
                                        .withOpacity(0.2),
                                    side: BorderSide(
                                      color: AppTheme.neonCyan.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showEmailAuthSheet,
                                  icon: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white70,
                                  ),
                                  label: const Text(
                                    "Custom Email & Password",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Stats / Gamified Metrics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Scans",
                        value: _totalScans.toString(),
                        icon: Icons.camera_alt_outlined,
                        color: AppTheme.neonCyan,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: "Top Fish",
                        value: _topFish,
                        icon: Icons.set_meal_outlined,
                        color: AppTheme.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Fish Best Season (Placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "In Season Right Now",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const InSeasonCarouselWidget(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Scan History
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildScanHistory(),
              ),

              // Species Breakdown old list is removed from here
              const SizedBox(height: 60), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistory() {
    const List<String> monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Scan History",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    Text(
                      "${monthNames[_currentMonth.month]} ${_currentMonth.year}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Days of week header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["S", "M", "T", "W", "T", "F", "S"]
                      .map(
                        (d) => SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Grid of days wrapped in PageView for perfect swipe interaction
              SizedBox(
                height:
                    255, // Reduced gap from 300 to 255 to perfectly fit 6 rows
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      int offset = index - 1200;
                      _currentMonth = DateTime(
                        _baseMonth.year,
                        _baseMonth.month + offset,
                        1,
                      );
                    });
                  },
                  itemBuilder: (context, index) {
                    int offset = index - 1200;
                    DateTime pageMonth = DateTime(
                      _baseMonth.year,
                      _baseMonth.month + offset,
                      1,
                    );

                    int daysInMonth = DateTime(
                      pageMonth.year,
                      pageMonth.month + 1,
                      0,
                    ).day;
                    int firstWeekday = DateTime(
                      pageMonth.year,
                      pageMonth.month,
                      1,
                    ).weekday;
                    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ), // gap between months during swipe + edge padding
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        clipBehavior:
                            Clip.none, // Prevent clipping inside GridView
                        itemCount: 42,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                        itemBuilder: (context, i) {
                          if (i < firstWeekday ||
                              i >= firstWeekday + daysInMonth) {
                            return const SizedBox.shrink(); // Empty space outside of month bounds
                          }

                          int day = i - firstWeekday + 1;
                          DateTime cellDate = DateTime(
                            pageMonth.year,
                            pageMonth.month,
                            day,
                          );

                          DailyScanAggregate? agg = _dailyAggregates[cellDate];
                          bool hasScan = agg != null && agg.totalScans > 0;
                          double density = hasScan
                              ? (agg.totalScans / 10).clamp(0.2, 1.0)
                              : 0.0;
                          bool isSelected = _selectedDate == cellDate;

                          return GestureDetector(
                            onTap: hasScan
                                ? () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedDate = isSelected
                                          ? null
                                          : cellDate;
                                    });
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonCyan.withOpacity(
                                        0.15 + (0.4 * density),
                                      )
                                    : (hasScan
                                          ? AppTheme.neonCyan.withOpacity(
                                              0.15 + (0.7 * density),
                                            )
                                          : Colors.transparent),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.neonCyan
                                      : (hasScan
                                            ? AppTheme.neonCyan.withOpacity(
                                                0.3 + (0.5 * density),
                                              )
                                            : Colors.white.withOpacity(0.05)),
                                  width: isSelected ? 2.5 : (hasScan ? 0 : 1),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        // Inner tight cyan glow
                                        BoxShadow(
                                          color: AppTheme.neonCyan.withOpacity(
                                            0.6,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                        // Outer soft bloom
                                        BoxShadow(
                                          color: AppTheme.neonCyan.withOpacity(
                                            0.25,
                                          ),
                                          blurRadius: 18,
                                          spreadRadius: 4,
                                        ),
                                      ]
                                    : (hasScan && density > 0.4
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.neonCyan
                                                    .withOpacity(
                                                      0.15 * density,
                                                    ),
                                                blurRadius: 10,
                                                spreadRadius: -2,
                                              ),
                                            ]
                                          : null),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "$day",
                                style: TextStyle(
                                  color: hasScan
                                      ? (density > 0.5
                                            ? Colors.black
                                            : Colors.white)
                                      : Colors.white54,
                                  fontSize: 16,
                                  fontWeight: hasScan
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Floating Pill for selected date
              if (_selectedDate != null &&
                  _dailyAggregates[_selectedDate] != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: GestureDetector(
                    onTap: () => _fetchAndShowDailyScansDialog(_selectedDate!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: AppTheme.neonCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${_dailyAggregates[_selectedDate!]!.totalScans} Scans • Top: ${_dailyAggregates[_selectedDate!]!.topFishName ?? 'Unknown'}",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _fetchAndShowDailyScansDialog(DateTime date) async {
    if (!DBService.isInitialized) return;
    try {
      // 1. Check local DB
      List<ScanRecord> scans = await DBService.isar.scanRecords
          .filter()
          .timestampBetween(
            DateTime(date.year, date.month, date.day),
            DateTime(date.year, date.month, date.day, 23, 59, 59),
          )
          .findAll();

      // 2. If not local, must be archived -> fetch from Firebase
      if (scans.isEmpty) {
        setState(() => _isLoading = true);
        scans = await SyncService.fetchArchivedScansForDate(date);
        setState(() => _isLoading = false);
      }

      if (scans.isNotEmpty && mounted) {
        _showDailyScansDialog(date, scans);
      }
    } catch (e) {
      debugPrint("Error fetching daily scans: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDailyScansDialog(DateTime date, List<ScanRecord> scans) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Scans for ${date.day}/${date.month}/${date.year}",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: scans.length,
                      itemBuilder: (context, index) {
                        final scan = scans[index];
                        final isLocked =
                            !AppConfig.isPremiumUser && !scan.isUnlocked;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(
                              context,
                            ); // close the list before navigating to prevent stack issues

                            Map<String, dynamic> aiData = {
                              'id': scan.id,
                              'englishName': scan.englishName,
                              'localName': scan.localName,
                              'freshnessScore': scan.freshnessScore,
                              'freshnessStatus': scan.freshnessStatus,
                              'freshnessEvidence': scan.freshnessEvidence,
                              'bestCuts': scan.bestCuts,
                              'idealFor': scan.idealFor,
                              'trickeryTips': scan.trickeryTips,
                              'suggestedPrice': scan.suggestedPrice,
                              'marketAvgPrice': scan.marketAvgPrice,
                              'imagePath': scan.imagePath,
                              'isOffline': false,
                              'timestamp': scan.timestamp.toIso8601String(),
                              'location': scan.region,
                            };

                            if (isLocked) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: false,
                                backgroundColor: Colors.transparent,
                                builder: (context) => RecognitionSheet(
                                  aiData: aiData,
                                  scanId: scan.id,
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultsScreen(aiData: aiData),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final bool isLocked =
                                            !AppConfig.isPremiumUser &&
                                            !scan.isUnlocked;
                                        Widget imageWidget;
                                        if (scan.imagePath != null) {
                                          imageWidget = Image.file(
                                            File(
                                              DBService.getImagePath(
                                                    scan.imagePath!,
                                                  ) ??
                                                  '',
                                            ),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                          );
                                        } else {
                                          imageWidget = Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.white54,
                                            ),
                                          );
                                        }
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: isLocked
                                                  ? ImageFiltered(
                                                      imageFilter:
                                                          ImageFilter.blur(
                                                            sigmaX: 3,
                                                            sigmaY: 3,
                                                          ),
                                                      child: imageWidget,
                                                    )
                                                  : imageWidget,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            scan.englishName ?? "Unknown Fish",
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${DBService.formatAmPm(scan.timestamp)}${scan.region != null && scan.region!.isNotEmpty ? " • ${scan.region}" : ""}',
                                            style: GoogleFonts.inter(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isLocked)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 5,
                                          sigmaY: 5,
                                        ),
                                        child: Container(
                                          color: Colors.black.withOpacity(0.3),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.lock,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeciesBreakdownList() {
    var sortedFishes = _fishCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedFishes.isEmpty) return const SizedBox();

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: sortedFishes.length,
      itemBuilder: (context, index) {
        final entry = sortedFishes[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.set_meal, color: Colors.white70, size: 20),
          ),
          title: Text(
            entry.key,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${entry.value}",
              style: GoogleFonts.inter(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSpeciesBreakdownSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Species Breakdown",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildSpeciesBreakdownList()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Reusable Glassmorphism Card
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  // Reusable Stat Card
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 80, right: 24),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implement support/donate functionality later
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.pinkAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Show Support",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.white.withOpacity(0.1),
                              height: 1,
                            ),
                            if (FirebaseAuth.instance.currentUser != null)
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _handleSignOut();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.logout_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Sign Out",
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  bool _isClearing = false;
  late List<AppNotification> _localNotifications;

  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(NotificationService().notifications.value);
    NotificationService().notifications.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    NotificationService().notifications.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (!_isClearing && mounted) {
      setState(() {
        _localNotifications = List.from(
          NotificationService().notifications.value,
        );
      });
    }
  }

  void _handleClearAll() async {
    if (_isClearing || _localNotifications.isEmpty) return;
    setState(() {
      _isClearing = true;
    });

    // Staggered delay is e.g. 100ms * items.length + 300ms duration
    final totalTimeMs = 300 + (_localNotifications.length * 100);
    await Future.delayed(Duration(milliseconds: totalTimeMs));

    NotificationService().clearAll();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topRight,
      insetPadding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 60,
        right: 16,
        left: 16,
      ),
      child: Container(
        width: 320,
        clipBehavior: Clip.antiAlias, // PREVENTS OVERFLOW
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_localNotifications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No new notifications',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: _localNotifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final notif = _localNotifications[index];
                    return Dismissible(
                      key: Key(notif.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent.withOpacity(0.2),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                      onDismissed: (direction) {
                        NotificationService().remove(notif.id);
                        setState(() {
                          _localNotifications.removeAt(index);
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeInCubic,
                        transform: Matrix4.translationValues(
                          _isClearing ? -MediaQuery.sizeOf(context).width : 0,
                          0,
                          0,
                        ),
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 200 + (index * 100)),
                          opacity: _isClearing ? 0.0 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  notif.icon,
                                  color: AppTheme.neonCyan,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            notif.time,
                                            style: GoogleFonts.inter(
                                              color: Colors.white38,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        notif.subtitle,
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_localNotifications.isNotEmpty)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(color: Colors.white10, height: 1),
                  InkWell(
                    onTap: _handleClearAll,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.clear_all,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Clear all notifications',
                            style: GoogleFonts.inter(
                              color: AppTheme.neonCyan,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class InSeasonCarouselWidget extends StatefulWidget {
  const InSeasonCarouselWidget({Key? key}) : super(key: key);

  @override
  State<InSeasonCarouselWidget> createState() => _InSeasonCarouselWidgetState();
}

class _InSeasonCarouselWidgetState extends State<InSeasonCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  Timer? _hideDotsTimer;
  bool _showDots = false;

  List<Widget> get _pages => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: AppTheme.neonCyan, size: 26),
              const SizedBox(width: 12),
              Text(
                "Monsoon Catch",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Hilsa (Ilish) and Pabda are currently peaking in freshness and availability. Prices might be slightly higher but quality is prime.",
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upcoming, color: AppTheme.neonCyan, size: 32),
          const SizedBox(height: 14),
          Text(
            "More Integrations Coming Soon",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleNextRotation(const Duration(seconds: 5));
  }

  void _scheduleNextRotation(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!mounted) return;
      if (_currentPage < _pages.length - 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _triggerDotsVisibility() {
    if (!_showDots) {
      setState(() => _showDots = true);
    }
    _hideDotsTimer?.cancel();
    _hideDotsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showDots = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideDotsTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 16,
      ),
      child: Column(
        children: [
          SizedBox(
            height:
                140, // Greatly increased height to fix Android overflow and fit larger text
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is ScrollStartNotification &&
                    scrollInfo.dragDetails != null) {
                  _triggerDotsVisibility();
                } else if (scrollInfo is ScrollUpdateNotification &&
                    scrollInfo.dragDetails != null) {
                  _triggerDotsVisibility();
                }
                return false;
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                  if (page == 0) {
                    _scheduleNextRotation(const Duration(minutes: 3));
                  } else {
                    _scheduleNextRotation(const Duration(seconds: 5));
                  }
                },
                children: _pages,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: _showDots ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmeringPremiumButton extends StatefulWidget {
  final VoidCallback onTap;

  const ShimmeringPremiumButton({Key? key, required this.onTap})
    : super(key: key);

  @override
  State<ShimmeringPremiumButton> createState() =>
      _ShimmeringPremiumButtonState();
}

class _ShimmeringPremiumButtonState extends State<ShimmeringPremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(2), // Border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
              gradient: SweepGradient(
                colors: [
                  AppTheme.neonCyan.withOpacity(0.1),
                  AppTheme.neonCyan,
                  Colors.white,
                  AppTheme.neonCyan,
                  AppTheme.neonCyan.withOpacity(0.1),
                ],
                stops: const [0.0, 0.75, 0.85, 0.95, 1.0],
                transform: GradientRotation(_controller.value * 2 * pi),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppTheme.neonCyan,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Unlock PRO",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.neonCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
