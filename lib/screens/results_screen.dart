import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/db_service.dart';
import '../config/app_config.dart';
import '../services/remote_config_service.dart';
import 'widgets/upi_picker_sheet.dart';
import '../services/admob_service.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/share_card_preview.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../core/models/scan_record.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> aiData;
  const ResultsScreen({super.key, required this.aiData});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;
  List<Map<String, String>> _videos = [];
  bool _isLoadingVideos = true;
  bool _isBookmarked = false;
  bool _showAllTrickeryTips = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
    _shimmerController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _animController.forward();
    });
    _fetchVideos();
    _checkBookmarkStatus();
    _checkAndShowMarketingModal();
  }

  void _checkAndShowMarketingModal() async {
    if (AuthService.currentUser == null || AuthService.currentUser!.isAnonymous) {
      final count = await DBService.isar.scanRecords.count();
      if (count == 1 || (count > 1 && (count - 1) % 4 == 0)) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _buildMarketingModal(context),
            );
          }
        });
      }
    }
  }

  Widget _buildMarketingModal(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync, color: AppTheme.neonCyan, size: 36),
                ),
                const SizedBox(height: 24),
                Text(
                  "Save Your Scans",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sign in to automatically sync your history across devices and unlock all features. Don't lose your fishy discoveries!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the modal
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Go to Profile to Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Maybe Later",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkBookmarkStatus() async {
    final id = widget.aiData['id'] as int?;
    final imagePath = widget.aiData['imagePath'] as String?;
    final bookmarked = await DBService.isBookmarked(id, imagePath);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  Future<void> _fetchVideos() async {
    final species = widget.aiData['englishName'] ?? 'Fish';

    // Extract the local name from format "LocalName (English Name)"
    final localNameRaw = widget.aiData['localName'] as String?;
    String searchKeyword = species;

    if (localNameRaw != null && localNameRaw.contains('(')) {
      // e.g. "Rui (Rohu)" -> "Rui"
      searchKeyword = localNameRaw.split('(')[0].trim();
    } else if (localNameRaw != null && localNameRaw.isNotEmpty) {
      searchKeyword = localNameRaw;
    }

    final query = '$searchKeyword fish recipe'.trim();

    try {
      final cachedStr = await DBService.getCachedRecipes(query);
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        final parsed = decoded
            .map(
              (e) => Map<String, dynamic>.from(
                e,
              ).map((k, v) => MapEntry(k, v?.toString() ?? '')),
            )
            .toList();
        if (parsed.isNotEmpty) {
          _videos = parsed;
          setState(() => _isLoadingVideos = false);
          return;
        }
      }

      final apiKey = RemoteConfigService.youtubeApiKey.value;
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$apiKey&maxResults=10&videoDuration=medium&order=viewCount',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;

        final parsedVideos = items.map<Map<String, String>>((item) {
          final snippet = item['snippet'];
          return {
            'title': snippet['title'],
            'channel': snippet['channelTitle'],
            'videoId': item['id']['videoId'],
            'thumb': snippet['thumbnails']['high']['url'],
          };
        }).toList();

        await DBService.saveCachedRecipes(query, jsonEncode(parsedVideos));

        if (mounted) {
          setState(() {
            _videos = parsedVideos;
            _isLoadingVideos = false;
          });
        }
      } else {
        setState(() {
          _videoError = 'Failed to load recipes';
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      // Fallback to hardcoded mock videos if network fails
      setState(() {
        _videos = [
          {
            'title': 'Rui Macher Kalia',
            'channel': 'Bong Eats',
            'videoId': '6K8R-fK0Y_4',
            'thumb': 'https://img.youtube.com/vi/6K8R-fK0Y_4/hqdefault.jpg',
          },
          {
            'title': 'Doi Mach',
            'channel': 'Bong Eats',
            'videoId': 'h-kKx5F2nK8',
            'thumb': 'https://img.youtube.com/vi/h-kKx5F2nK8/hqdefault.jpg',
          },
          {
            'title': 'Ilish Macher Jhol',
            'channel': 'Bong Eats',
            'videoId': 'X0x925E2v9w',
            'thumb': 'https://img.youtube.com/vi/X0x925E2v9w/hqdefault.jpg',
          },
        ];
        _isLoadingVideos = false;
        _videoError = null;
      });
    }
  }

  void _launchVideo(String? videoId) async {
    if (videoId == null || videoId == 'mock') return;

    final Uri appUrl = Uri.parse('youtube://watch?v=$videoId');
    final Uri webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    try {
      // Force native app check via custom URI scheme
      bool launched = await launchUrl(
        appUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to web browser
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch native YouTube app: $e");
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _openAllRecipes() {
    final species = widget.aiData['englishName'] ?? 'Fish';
    final localNameRaw = widget.aiData['localName'] as String?;
    String searchKeyword = species;

    if (localNameRaw != null && localNameRaw.contains('(')) {
      searchKeyword = localNameRaw.split('(')[0].trim();
    } else if (localNameRaw != null && localNameRaw.isNotEmpty) {
      searchKeyword = localNameRaw;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AllRecipesScreen(query: '$searchKeyword fish recipe'),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double score = 0.0;
    final rawScore = widget.aiData['freshnessScore'];
    if (rawScore is num) {
      score = rawScore.toDouble();
    } else if (rawScore is String) {
      score = double.tryParse(rawScore) ?? 0.0;
    }
    final int scoreInt = (score * 100).toInt();

    final String freshnessStatus =
        widget.aiData['freshnessStatus']?.toString() ?? 'Unknown';
    final String evidence =
        widget.aiData['freshnessEvidence']?.toString() ?? '';
    final List<String> bestCuts = List<String>.from(
      widget.aiData['bestCuts'] ?? [],
    );
    final List<String> idealFor = List<String>.from(
      widget.aiData['idealFor'] ?? [],
    );
    final List<String> trickeryTips = List<String>.from(
      widget.aiData['trickeryTips'] ?? [],
    );
    final String suggestedPrice =
        widget.aiData['suggestedPrice']?.toString() ?? 'N/A';
    final String marketAvgPrice =
        widget.aiData['marketAvgPrice']?.toString() ?? 'N/A';
    final String priceExplanation =
        widget.aiData['priceExplanation']?.toString() ??
        'Price explanation not available.';
    final String marketAvgExplanation =
        widget.aiData['marketAvgExplanation']?.toString() ??
        'Market average calculation not available.';

    final bool isError = widget.aiData['error'] == true;

    // Status word classification
    String statusWord = 'Unknown';
    if (scoreInt >= 85)
      statusWord = 'Excellent';
    else if (scoreInt >= 65)
      statusWord = 'Good';
    else if (scoreInt >= 40)
      statusWord = 'Fair';
    else
      statusWord = 'Poor';

    // Evaluate timestamp and location properly
    final DateTime scanTime = widget.aiData['timestamp'] != null
        ? DateTime.parse(widget.aiData['timestamp']).toLocal()
        : DateTime.now();
    final localScanTime = scanTime.toLocal();
    int hour = localScanTime.hour;
    final minute = localScanTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final timeStr = '$hour:$minute $period';

    // Format date string nicely
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDay = DateTime(scanTime.year, scanTime.month, scanTime.day);
    final difference = today.difference(scanDay).inDays;

    String dateStr;
    if (difference == 0) {
      dateStr = 'today';
    } else if (difference == 1) {
      dateStr = 'yesterday';
    } else if (scanTime.year == now.year) {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      String suffix = 'th';
      if (scanTime.day % 10 == 1 && scanTime.day != 11)
        suffix = 'st';
      else if (scanTime.day % 10 == 2 && scanTime.day != 12)
        suffix = 'nd';
      else if (scanTime.day % 10 == 3 && scanTime.day != 13)
        suffix = 'rd';

      dateStr = '${scanTime.day}$suffix ${months[scanTime.month - 1]}';
    } else {
      dateStr =
          '${scanTime.day.toString().padLeft(2, '0')}/${scanTime.month.toString().padLeft(2, '0')}/${scanTime.year}';
    }

    // Determine ring and dot color based on score
    Color ringColor;
    if (scoreInt >= 75) {
      ringColor = AppTheme.emeraldGreen;
    } else if (scoreInt >= 40) {
      ringColor = AppTheme.amber;
    } else {
      ringColor = AppTheme.crimsonRed;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AdMobService.handleResultsBackButton(
          onProceed: () => Navigator.pop(context),
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: isError || widget.aiData.isEmpty
            ? Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.aiData['errorType'] == 'offline'
                            ? Icons.wifi_off_rounded
                            : Icons
                                  .signal_cellular_connected_no_internet_0_bar_rounded,
                        color: Colors.redAccent.withOpacity(0.8),
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.aiData['errorType'] == 'offline'
                            ? "Seems you are offline"
                            : "Network connection is too slow",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.aiData['errorType'] == 'offline'
                            ? "Please connect to the internet to analyze this fish. Offline models are currently unavailable."
                            : "The server took too long to respond. Please check your connection and try again.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Retry Connection",
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top > 0
                        ? MediaQuery.paddingOf(context).top + 16.0
                        : 48.0,
                    bottom: 16.0,
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Scrolling Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                AdMobService.handleResultsBackButton(
                                  onProceed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.set_meal,
                                    color: AppTheme.neonCyan,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Machi Master",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "AI Freshness Report",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.ios_share, color: Colors.white, size: 24),
                              onPressed: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                  barrierColor: Colors.black.withOpacity(0.5),
                                  transitionDuration: const Duration(milliseconds: 300),
                                  pageBuilder: (context, animation, secondaryAnimation) {
                                    return ShareCardPreview(aiData: widget.aiData);
                                  },
                                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutBack,
                                          ),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 32),

                      // Gauge Area
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _animController,
                                  _shimmerController,
                                ]),
                                builder: (context, child) {
                                  return SizedBox(
                                    width: 250,
                                    height: 250,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      alignment: Alignment.center,
                                      children: [
                                        // Option A: Full circular aura (Commented for A/B testing)
                                        /*
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: ringColor.withOpacity(
                                                _shimmerAnimation.value * 0.4,
                                              ),
                                              blurRadius: 40,
                                              spreadRadius: -10,
                                            ),
                                          ],
                                        ),
                                      ),
                                      */

                                        // Option B: Glow along the ring itself (Performant ImageFiltered)
                                        Opacity(
                                          opacity: _shimmerAnimation.value,
                                          child: ImageFiltered(
                                            imageFilter: ImageFilter.blur(
                                              sigmaX: 8,
                                              sigmaY: 8,
                                            ),
                                            child: CustomPaint(
                                              painter: FreshnessRingPainter(
                                                (score *
                                                        _progressAnimation
                                                            .value)
                                                    .clamp(0.0, 1.0),
                                                ringColor,
                                                1.0,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Foreground crisp ring
                                        CustomPaint(
                                          painter: FreshnessRingPainter(
                                            (score * _progressAnimation.value)
                                                .clamp(0.0, 1.0),
                                            ringColor,
                                            _shimmerAnimation.value,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _animController,
                                        builder: (context, child) {
                                          return Text(
                                            (scoreInt *
                                                    _progressAnimation.value)
                                                .toInt()
                                                .clamp(0, 100)
                                                .toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: 80,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          "%",
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.aiData['isOffline'] == true
                                        ? "Offline Mode"
                                        : (scoreInt >= 85
                                              ? "Very fresh"
                                              : (scoreInt >= 65
                                                    ? "Fresh"
                                                    : (scoreInt >= 40
                                                          ? "Getting old"
                                                          : "Stale"))),
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _shimmerController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: ringColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: ringColor.withOpacity(
                                                  _shimmerAnimation.value,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusWord.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () async {
                                            final scanId = widget.aiData['id'] as int?;
                                            final imgPath = widget.aiData['imagePath'] as String?;

                                            if (_isBookmarked) {
                                              setState(() => _isBookmarked = false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.bookmark_remove,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Removed from Bookmarks',
                                                        style: GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.redAccent,
                                                  duration: const Duration(
                                                      milliseconds: 1500),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              await DBService.setBookmarkStatus(scanId, imgPath, false);
                                            } else {
                                              setState(() => _isBookmarked = true);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.bookmark_added,
                                                        color: Colors.black,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Added to Bookmarks',
                                                        style: GoogleFonts.inter(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.w600),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.neonCyan,
                                                  duration: const Duration(
                                                      milliseconds: 1500),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              await DBService.setBookmarkStatus(scanId, imgPath, true);
                                            }
                                          },
                                          child: Icon(
                                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                            color: _isBookmarked ? AppTheme.neonCyan : Colors.white54,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.aiData['isOffline'] == true
                                  ? "Basic Scan"
                                  : (scoreInt >= 85
                                        ? "Safe to buy and consume."
                                        : (scoreInt >= 65
                                              ? "Good for cooking."
                                              : (scoreInt >= 40
                                                    ? "Use soon."
                                                    : "Not recommended."))),
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Scanned $dateStr, $timeStr",
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // OPTIONAL UI DIVIDER: Uncomment lines below to show faint divider above EVIDENCE section
                      // const Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 5.0),
                      //   child: Divider(color: Colors.white10, height: 1),
                      // ),
                      Center(
                        child: Text(
                          "EVIDENCE",
                          style: GoogleFonts.inter(
                            color: AppTheme.neonCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            children: evidence
                                .split('•')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final list = evidence
                                      .split('•')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                  final isLast = entry.key == list.length - 1;
                                  return TextSpan(
                                    text: isLast
                                        ? entry.value
                                        : '${entry.value}  •  ',
                                    style: isLast
                                        ? null
                                        : const TextStyle(
                                            color: Colors.white38,
                                          ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (trickeryTips.isNotEmpty) ...[
                        _buildVendorTrickeryCard(trickeryTips),
                        const SizedBox(height: 24),
                      ],

                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.cut,
                                title: "BEST CUTS",
                                items: bestCuts,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.restaurant,
                                title: "IDEAL FOR",
                                items: idealFor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (suggestedPrice != 'N/A') ...[
                        _buildPriceCard(
                          context,
                          suggestedPrice,
                          marketAvgPrice,
                          priceExplanation,
                          marketAvgExplanation,
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<bool>(
                          valueListenable: RemoteConfigService.enableVendorPayment,
                          builder: (context, vendorPaymentEnabled, child) {
                            if (!vendorPaymentEnabled) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.35),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 0), // Centered glow
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => UpiPickerSheet.show(context),
                                icon: const Icon(Icons.qr_code_scanner, size: 20),
                                label: Text(
                                  "Pay Vendor via UPI",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "RECIPES FOR YOU",
                            style: GoogleFonts.inter(
                              color: AppTheme.neonCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          GestureDetector(
                            onTap: _openAllRecipes,
                            child: Row(
                              children: [
                                Text(
                                  "See all",
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white54,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 190,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _isLoadingVideos
                              ? const Center(
                                  key: ValueKey('loading'),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.neonCyan,
                                  ),
                                )
                              : _videoError != null
                              ? Center(
                                  key: const ValueKey('error'),
                                  child: Text(
                                    _videoError!,
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('list'),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _videos.length,
                                  itemBuilder: (context, index) {
                                    final vid = _videos[index];
                                    return _buildDynamicVideoCard(
                                      vid['title'] ?? 'Recipe',
                                      vid['channel'] ?? '30 min',
                                      vid['thumb'] ?? '',
                                      vid['videoId'],
                                    );
                                  },
                                ),
                        ),
                      ),
                      if (!AppConfig.isPremiumUser) ...[
                        const SizedBox(height: 16),
                        const Center(child: BannerAdWidget()),
                        const SizedBox(
                          height: 30,
                        ), // Restores the bottom gap that SafeArea used to provide
                      ] else ...[
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Removed _buildEvidenceChip

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        color: AppTheme.neonCyan,
                        size: 4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    String suggestedPrice,
    String marketAvg,
    String explanation,
    String marketAvgExplanation,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Suggested Price Range",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Opacity(
                opacity: 0.0,
                child: Text(" /kg", style: GoogleFonts.inter(fontSize: 14)),
              ),
              Text(
                "₹$suggestedPrice",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                " /kg",
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Market avg: ₹$marketAvg/kg",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        "Market Average",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        marketAvgExplanation,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "OK",
                            style: GoogleFonts.inter(color: AppTheme.neonCyan),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white38,
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendorTrickeryCard(List<String> trickeryTips) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Default View
          InkWell(
            borderRadius: _showAllTrickeryTips
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            onTap: () {
              if (trickeryTips.length > 1) {
                setState(() => _showAllTrickeryTips = !_showAllTrickeryTips);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.amber,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showAllTrickeryTips
                              ? "Vendor Trickery Alerts"
                              : trickeryTips.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trickeryTips.length > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      _showAllTrickeryTips ? "Hide tips" : "View tips",
                      style: GoogleFonts.inter(
                        color: AppTheme.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllTrickeryTips
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_right,
                      color: AppTheme.neonCyan,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded view
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showAllTrickeryTips && trickeryTips.length > 1
                ? Column(
                    children: [
                      const Divider(color: Colors.white10, height: 1),
                      ...trickeryTips
                          .map(
                            (tip) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.circle,
                                      color: AppTheme.amber,
                                      size: 6,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVideoCard(
    String title,
    String subtitle,
    String thumbUrl,
    String? videoId,
  ) {
    return GestureDetector(
      onTap: () => _launchVideo(videoId),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: thumbUrl.isNotEmpty && thumbUrl != 'mock'
                  ? Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.video_collection,
                              color: Colors.white24,
                              size: 32,
                            ),
                          ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class FreshnessRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double shimmerValue;

  FreshnessRingPainter(this.percentage, this.color, this.shimmerValue);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * percentage;

    // Draw foreground arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FreshnessRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.shimmerValue != shimmerValue;
  }
}

class AllRecipesScreen extends StatefulWidget {
  final String query;
  const AllRecipesScreen({super.key, required this.query});

  @override
  State<AllRecipesScreen> createState() => _AllRecipesScreenState();
}

class _AllRecipesScreenState extends State<AllRecipesScreen> {
  final List<Map<String, String>> _videos = [];
  bool _isLoading = false;
  String? _pageToken;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMore();
      }
    });
  }

  Future<void> _fetchMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final apiKey = RemoteConfigService.youtubeApiKey.value;
      var urlStr =
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=${widget.query}&type=video&key=$apiKey&maxResults=10&videoDuration=medium&order=viewCount';
      if (_pageToken != null) urlStr += '&pageToken=$_pageToken';

      final response = await http.get(Uri.parse(urlStr));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pageToken = data['nextPageToken'];
        if (_pageToken == null) _hasMore = false;

        final items = data['items'] as List;
        final newVideos = items.map<Map<String, String>>((item) {
          final snippet = item['snippet'];
          return {
            'title': snippet['title'],
            'channel': snippet['channelTitle'],
            'videoId': item['id']['videoId'],
            'thumb': snippet['thumbnails']['high']['url'],
          };
        }).toList();

        if (mounted) {
          setState(() {
            _videos.addAll(newVideos);
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _launchVideo(String? videoId) async {
    if (videoId == null) return;

    final Uri appUrl = Uri.parse('youtube://watch?v=$videoId');
    final Uri webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    try {
      // Force native app check via custom URI scheme
      bool launched = await launchUrl(
        appUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to web browser
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch native YouTube app: $e");
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "All Recipes",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (!AppConfig.isPremiumUser) ...[
            const BannerAdWidget(),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              itemCount: _videos.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _videos.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.neonCyan,
                      ),
                    ),
                  );
                }
                final vid = _videos[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white10,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: vid['thumb']!.isNotEmpty
                        ? Image.network(
                            vid['thumb']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.video_collection,
                                    color: Colors.white24,
                                    size: 24,
                                  ),
                                ),
                          )
                        : null,
                  ),
                  title: Text(
                    vid['title']!,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    vid['channel'] ?? 'YouTube',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _launchVideo(vid['videoId']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
