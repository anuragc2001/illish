import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/theme.dart';
import '../services/db_service.dart';
import '../config/app_config.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> aiData;
  const ResultsScreen({super.key, required this.aiData});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  List<Map<String, String>> _videos = [];
  bool _isLoadingVideos = true;
  bool _isBookmarked = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _animController.forward();
    });
    _fetchVideos();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final imagePath = widget.aiData['imagePath'] as String?;
    final bookmarked = await DBService.isBookmarked(imagePath);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  Future<void> _fetchVideos() async {
    final species = widget.aiData['englishName'] ?? 'Fish';
    final query = '$species fish recipe';

    if (AppConfig.kMockMode || widget.aiData['isOffline'] == true) {
      // Use cached videos if offline
      final cachedStr = await DBService.getCachedRecipes(query);
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        _videos = decoded.map((e) => Map<String, String>.from(e)).toList();
        setState(() => _isLoadingVideos = false);
        return;
      }

      setState(() {
        _videos = [
          {
            'title': 'Rohu Fish Curry',
            'duration': '30 min',
            'url': 'mock',
            'thumb': '',
          },
          {
            'title': 'Paturi (Bengali)',
            'duration': '45 min',
            'url': 'mock',
            'thumb': '',
          },
          {
            'title': 'Rohu Fish Fry',
            'duration': '20 min',
            'url': 'mock',
            'thumb': '',
          },
        ];
        _isLoadingVideos = false;
      });
      return;
    }

    try {
      final cachedStr = await DBService.getCachedRecipes(query);
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        _videos = decoded.map((e) => Map<String, String>.from(e)).toList();
        setState(() => _isLoadingVideos = false);
        return;
      }

      final apiKey = dotenv.env['YOUTUBE_API_KEY'];
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$apiKey&maxResults=10',
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
      setState(() {
        _videoError = 'Network error';
        _isLoadingVideos = false;
      });
    }
  }

  void _launchVideo(String? videoId) async {
    if (videoId == null || videoId == 'mock') return;
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch $url: $e");
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  void _openAllRecipes() {
    final species = widget.aiData['englishName'] ?? 'Fish';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllRecipesScreen(query: '$species fish recipe'),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
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

    // Evaluate timestamp properly
    final timeStr = TimeOfDay.now().format(context);

    return Scaffold(
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
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
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
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isBookmarked
                                  ? AppTheme.neonCyan
                                  : Colors.white,
                            ),
                            onPressed: () async {
                              final imagePath =
                                  widget.aiData['imagePath'] as String?;
                              if (_isBookmarked) {
                                setState(() => _isBookmarked = false);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Removed from Bookmarks',
                                          style: GoogleFonts.inter(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.neonCyan,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                  ),
                                );
                                await DBService.removeBookmark(imagePath);
                              } else {
                                setState(() => _isBookmarked = true);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Added to Bookmarks',
                                          style: GoogleFonts.inter(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppTheme.neonCyan,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                  ),
                                );
                                await DBService.saveScan(
                                  widget.aiData,
                                  isBookmark: true,
                                );
                              }
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
                              animation: _animController,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: CustomPaint(
                                    painter: FreshnessRingPainter(
                                      (score * _progressAnimation.value).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      AppTheme.neonCyan,
                                    ),
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
                                          (scoreInt * _progressAnimation.value)
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scoreInt >= 65
                                      ? AppTheme.emeraldGreen
                                      : (scoreInt >= 40
                                            ? Colors.orange
                                            : Colors.red),
                                  shape: BoxShape.circle,
                                ),
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
                            "Scanned today, $timeStr",
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
                                      : const TextStyle(color: Colors.white38),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 40),

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
                      height: 180,
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
                    const SizedBox(height: 40),
                  ],
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

  Widget _buildDynamicVideoCard(
    String title,
    String subtitle,
    String thumbUrl,
    String? videoId,
  ) {
    return GestureDetector(
      onTap: () => _launchVideo(videoId),
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

  FreshnessRingPainter(this.percentage, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * percentage;

    // Draw glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );

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
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
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
      final apiKey = dotenv.env['YOUTUBE_API_KEY'];
      var urlStr =
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=${widget.query}&type=video&key=$apiKey&maxResults=10';
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
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch $url: $e");
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
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
      body: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _videos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _videos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
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
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
            onTap: () => _launchVideo(vid['videoId']),
          );
        },
      ),
    );
  }
}
