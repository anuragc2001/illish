import 'dart:convert';
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

class _ResultsScreenState extends State<ResultsScreen> {
  List<Map<String, String>> _videos = [];
  bool _isLoadingVideos = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
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
          {'title': 'Rohu Fish Curry', 'duration': '30 min', 'url': 'mock', 'thumb': ''},
          {'title': 'Paturi (Bengali)', 'duration': '45 min', 'url': 'mock', 'thumb': ''},
          {'title': 'Rohu Fish Fry', 'duration': '20 min', 'url': 'mock', 'thumb': ''},
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
      final url = Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$apiKey&maxResults=10');
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
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openAllRecipes() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("All Recipes", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            final vid = _videos[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: vid['thumb']!.isNotEmpty && vid['thumb'] != 'mock' ? DecorationImage(
                    image: NetworkImage(vid['thumb']!),
                    fit: BoxFit.cover,
                  ) : null,
                  color: Colors.white10,
                ),
                child: vid['thumb'] == 'mock' || vid['thumb']!.isEmpty 
                  ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white54))
                  : null,
              ),
              title: Text(vid['title']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(vid['channel'] ?? '30 min', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              onTap: () => _launchVideo(vid['videoId']),
            );
          },
        ),
      )
    ));
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
    
    final String freshnessStatus = widget.aiData['freshnessStatus']?.toString() ?? 'Unknown';
    final String evidence = widget.aiData['freshnessEvidence']?.toString() ?? '';
    final List<String> bestCuts = List<String>.from(widget.aiData['bestCuts'] ?? []);
    final List<String> idealFor = List<String>.from(widget.aiData['idealFor'] ?? []);
    final bool isError = widget.aiData['error'] == true;
    
    // Evaluate timestamp properly
    final timeStr = TimeOfDay.now().format(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.set_meal, color: AppTheme.neonCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              "Machi Master",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () async {
              if (isError) return;
              await DBService.saveScan(widget.aiData);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scan saved to history!', style: GoogleFonts.inter(color: Colors.black)),
                    backgroundColor: AppTheme.neonCyan,
                  )
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Text(
            "AI Freshness Report",
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
        ),
      ),
      body: isError || widget.aiData.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text("Couldn't identify this fish.", style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan, foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Try Again"),
                )
              ],
            ),
          )
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gauge Area
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppTheme.background, // Prevents inner shadow bleeding
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonCyan, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scoreInt.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                "%",
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              freshnessStatus,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppTheme.neonCyan,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppTheme.emeraldGreen, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(freshnessStatus, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(widget.aiData['isOffline'] == true ? "Offline Mode: Basic Scan" : "Very fresh. Safe to buy.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Scanned today, $timeStr", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                "EVIDENCE",
                style: GoogleFonts.inter(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: evidence.split('•').map((e) => _buildEvidenceChip(e.trim())).toList(),
              ),
              const SizedBox(height: 32),
              
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.cut,
                        title: "BEST CUTS",
                        items: bestCuts,
                        imageUrl: 'https://loremflickr.com/200/200/fish,steak',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.restaurant,
                        title: "IDEAL FOR",
                        items: idealFor,
                        imageUrl: 'https://loremflickr.com/200/200/fish,curry',
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
                    style: GoogleFonts.inter(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  GestureDetector(
                    onTap: _openAllRecipes,
                    child: Row(
                      children: [
                        Text("See all", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        const Icon(Icons.arrow_forward, color: Colors.white54, size: 14),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 180,
                child: _isLoadingVideos 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
                  : _videoError != null
                      ? Center(child: Text(_videoError!, style: const TextStyle(color: Colors.white54)))
                      : ListView.builder(
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceChip(String text) {
    if (text.isEmpty) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13), overflow: TextOverflow.visible)),
        const SizedBox(width: 8),
        const Text("•", style: TextStyle(color: Colors.white38)),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<String> items, required String imageUrl}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background Image at bottom right
          Positioned(
            right: -20,
            bottom: -20,
            width: 100,
            height: 100,
            child: Opacity(
              opacity: 0.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: Colors.white10, size: 80),
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, color: AppTheme.neonCyan, size: 4),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 40), // Push past the image
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicVideoCard(String title, String subtitle, String thumbUrl, String? videoId) {
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: thumbUrl.isNotEmpty && thumbUrl != 'mock' ? DecorationImage(
                  image: NetworkImage(thumbUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: thumbUrl == 'mock' || thumbUrl.isEmpty 
                ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32)) 
                : null,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white54, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), overflow: TextOverflow.ellipsis),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
