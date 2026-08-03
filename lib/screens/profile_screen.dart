import 'dart:ui';
import 'dart:async';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  int _totalScans = 0;
  String _topFish = "--";
  Map<DateTime, int> _scanHeatmap = {};
  Map<String, int> _fishCounts = {};
  Map<DateTime, DailyScanAggregate> _dailyAggregates = {};
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDate;
  late DateTime _baseMonth;
  late PageController _pageController;
  StreamSubscription? _isarSub;

  @override
  void initState() {
    super.initState();
    _baseMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _pageController = PageController(initialPage: 1200);
    _loadAnalytics();
    
    // Listen to changes in Isar to auto-update when SyncService pulls down cloud data
    _isarSub = DBService.isar.scanRecords.watchLazy().listen((_) {
      if (mounted) _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _isarSub?.cancel();
    super.dispose();
  }

  void _previousMonth() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextMonth() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _loadAnalytics() async {
    var aggregates = await DBService.isar.dailyScanAggregates.where().findAll();
    
    if (aggregates.isEmpty) {
      // Pull cloud records to populate local aggregate history
      await SyncService.syncFromCloudToLocal();
      aggregates = await DBService.isar.dailyScanAggregates.where().findAll();
    }
    
    int total = 0;
    Map<String, int> fishCounts = {};
    Map<DateTime, int> heatmap = {};
    Map<DateTime, DailyScanAggregate> dailyMap = {};

    for (var agg in aggregates) {
      total += agg.totalScans;
      heatmap[agg.date] = agg.totalScans;
      dailyMap[agg.date] = agg;
      
      for (var fc in agg.fishCounts) {
        final parts = fc.split(':');
        if (parts.length == 2) {
          final name = parts[0];
          final count = int.tryParse(parts[1]) ?? 0;
          fishCounts[name] = (fishCounts[name] ?? 0) + count;
        }
      }
    }
    
    String top = "--";
    if (fishCounts.isNotEmpty) {
      var sorted = fishCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      top = sorted.first.key;
    }

    if (mounted) {
      setState(() {
        _totalScans = total;
        _topFish = top;
        _scanHeatmap = heatmap;
        _fishCounts = fishCounts;
        _dailyAggregates = dailyMap;
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    _setLoading(true);
    await AuthService.signInWithApple();
    _setLoading(false);
  }

  void _showEmailAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmailAuthSheet(),
    );
  }

  void _showPhoneAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PhoneAuthSheet(),
    );
  }

  void _setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    await AuthService.signInWithGoogle();
    _setLoading(false);
  }

  Future<void> _handleAnonSignIn() async {
    _setLoading(true);
    await AuthService.signInAnonymously();
    _setLoading(false);
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
              // Header Area with Back Button
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
                    Expanded(
                      child: Text(
                        "Your Profile",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // Balance the back button
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // User Info Card (Glassmorphism)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<User?>(
                  stream: AuthService.authStateChanges,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final isLoggedIn = user != null;
                    final displayName = user?.displayName ?? "Guest Fisher";
                    final email = user?.email ?? "";

                    return _buildGlassCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: AppTheme.neonCyan.withOpacity(0.5),
                                    width: 2,
                                  ),
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
                                        size: 32,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    ValueListenableBuilder<bool>(
                                      valueListenable:
                                          AppConfig.isPremiumNotifier,
                                      builder: (context, isPremium, child) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPremium
                                                ? AppTheme.neonCyan.withOpacity(
                                                    0.2,
                                                  )
                                                : Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            border: Border.all(
                                              color: isPremium
                                                  ? AppTheme.neonCyan
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Text(
                                            isPremium
                                                ? "PRO MEMBER"
                                                : "FREE TIER",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isPremium
                                                  ? AppTheme.neonCyan
                                                  : Colors.white70,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const CircularProgressIndicator(
                              color: AppTheme.neonCyan,
                            )
                          else if (isLoggedIn)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _handleSignOut,
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Sign Out",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            )
                          else
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
                                        color: AppTheme.neonCyan.withOpacity(
                                          0.5,
                                        ),
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
                                    onPressed: _handleAppleSignIn,
                                    icon: const Icon(Icons.apple, color: Colors.white),
                                    label: const Text("Sign in with Apple", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showEmailAuthSheet,
                                    icon: const Icon(Icons.email_outlined, color: Colors.white70),
                                    label: const Text("Custom Email & Password", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showPhoneAuthSheet,
                                    icon: const Icon(Icons.phone_android, color: Colors.white70),
                                    label: const Text("Sign in with Phone Number", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

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
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.water,
                                color: AppTheme.neonCyan,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Monsoon Catch",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Hilsa (Ilish) and Pabda are currently peaking in freshness and availability. Prices might be slightly higher but quality is prime.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Scan History
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildScanHistory(),
              ),

              if (_fishCounts.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSpeciesBreakdown(),
                ),
              ],

              const SizedBox(height: 60), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanHistory() {
    const List<String> monthNames = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    
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
        // Custom non-clipping glass card for calendar so glow shadows are not cut off
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
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: () {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  children: ["S", "M", "T", "W", "T", "F", "S"].map((d) => 
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(d, style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold))
                      )
                    )
                  ).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Grid of days wrapped in PageView for perfect swipe interaction
              SizedBox(
                height: 300, // Safe height tight to 6-row grid
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      int offset = index - 1200;
                      _currentMonth = DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
                    });
                  },
                  itemBuilder: (context, index) {
                    int offset = index - 1200;
                    DateTime pageMonth = DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
                    
                    int daysInMonth = DateTime(pageMonth.year, pageMonth.month + 1, 0).day;
                    int firstWeekday = DateTime(pageMonth.year, pageMonth.month, 1).weekday;
                    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20), // gap between months during swipe + edge padding
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        clipBehavior: Clip.none, // Prevent clipping inside GridView
                        itemCount: 42,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, i) {
                          if (i < firstWeekday || i >= firstWeekday + daysInMonth) {
                            return const SizedBox.shrink(); // Empty space outside of month bounds
                          }

                          int day = i - firstWeekday + 1;
                          DateTime cellDate = DateTime(pageMonth.year, pageMonth.month, day);
                          
                          DailyScanAggregate? agg = _dailyAggregates[cellDate];
                          bool hasScan = agg != null && agg.totalScans > 0;
                          double density = hasScan ? (agg.totalScans / 10).clamp(0.2, 1.0) : 0.0;
                          bool isSelected = _selectedDate == cellDate;

                          return GestureDetector(
                            onTap: hasScan ? () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedDate = isSelected ? null : cellDate;
                              });
                            } : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonCyan.withOpacity(0.15 + (0.4 * density))
                                    : (hasScan 
                                        ? AppTheme.neonCyan.withOpacity(0.15 + (0.7 * density)) 
                                        : Colors.transparent),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.neonCyan
                                      : (hasScan 
                                          ? AppTheme.neonCyan.withOpacity(0.3 + (0.5 * density)) 
                                          : Colors.white.withOpacity(0.05)),
                                  width: isSelected ? 2.5 : (hasScan ? 0 : 1),
                                ),
                                boxShadow: isSelected ? [
                                  // Inner tight cyan glow
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                  // Outer soft bloom
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.25),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  ),
                                ] : (hasScan && density > 0.4 ? [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.15 * density),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                  )
                                ] : null),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "$day",
                                style: TextStyle(
                                  color: hasScan 
                                      ? (density > 0.5 ? Colors.black : Colors.white) 
                                      : Colors.white54,
                                  fontSize: 16,
                                  fontWeight: hasScan ? FontWeight.bold : FontWeight.normal,
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
              if (_selectedDate != null && _dailyAggregates[_selectedDate] != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: GestureDetector(
                    onTap: () => _fetchAndShowDailyScansDialog(_selectedDate!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, color: AppTheme.neonCyan, size: 16),
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
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
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
    // 1. Check local DB
    List<ScanRecord> scans = await DBService.isar.scanRecords
      .filter()
      .timestampBetween(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59)
      )
      .findAll();

    // 2. If not local, must be archived -> fetch from Firebase
    if (scans.isEmpty) {
      setState(() => _isLoading = true);
      scans = await SyncService.fetchArchivedScansForDate(date);
      setState(() => _isLoading = false);
    }

    if (scans.isNotEmpty) {
      _showDailyScansDialog(date, scans);
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
                        final isLocked = !AppConfig.isPremiumUser && !scan.isUnlocked;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // close the list before navigating to prevent stack issues
                            
                            Map<String, dynamic> aiData = {
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
                                builder: (context) => RecognitionSheet(aiData: aiData, scanId: scan.id),
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
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.set_meal, color: AppTheme.neonCyan),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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

  Widget _buildSpeciesBreakdown() {
    var sortedFishes = _fishCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Species Breakdown",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassCard(
          child: Column(
            children: sortedFishes.map((entry) {
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
            }).toList(),
          ),
        ),
      ],
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
}
