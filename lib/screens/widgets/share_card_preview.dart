import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../services/db_service.dart';

class ShareCardPreview extends StatefulWidget {
  final Map<String, dynamic> aiData;

  const ShareCardPreview({super.key, required this.aiData});

  @override
  State<ShareCardPreview> createState() => _ShareCardPreviewState();
}

class _ShareCardPreviewState extends State<ShareCardPreview> {
  bool _isCapturing = false;
  bool _showSavedSuccessHUD = false;
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _captureAndShare(bool isSaveOnly) async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      // Give UI just enough time to hide buttons (1-2 frames)
      await Future.delayed(const Duration(milliseconds: 50));

      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 3.0 ratio was the original setting
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/illish_postcard_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      if (isSaveOnly) {
        await Gal.putImage(imagePath);
        if (mounted) {
          setState(() => _showSavedSuccessHUD = true);
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (mounted) {
              setState(() => _showSavedSuccessHUD = false);
              Navigator.pop(context); // Auto dismiss card
            }
          });
        }
      } else {
        final size = MediaQuery.of(context).size;
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Whoa! Check out this fish I scanned on Illish! 🐟',
          sharePositionOrigin: Rect.fromLTWH(
            0,
            size.height / 2,
            size.width,
            size.height / 2,
          ),
        );
        if (mounted) {
          // Slight delay for visual pleasure after share sheet closes
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.pop(context); // Auto dismiss after sharing
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppTheme.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  double _getScore() {
    final rawScore = widget.aiData['freshnessScore'];
    if (rawScore is num) return rawScore.toDouble();
    if (rawScore is String) return double.tryParse(rawScore) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    double fixedWidth = MediaQuery.of(context).size.width * 0.85;
    if (fixedWidth > 360) fixedWidth = 360; // Max width cap

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4), // Reduced blur
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.25), // More transparent
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.of(context).size.height * 0.04 +
                      MediaQuery.paddingOf(context).top,
                ),
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from dismissing dialog
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildRepaintWrapper(fixedWidth, _buildPolaroidCard()),
                  ),
                ),
              ),

              // Sleek Bottom Pill Toast Overlay
              if (_showSavedSuccessHUD)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.12, // Lower half positioning
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 30.0, end: 0.0), // Smooth slide up
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, dy, child) {
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.9), // Dark slate
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.emeraldGreen,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Saved to Gallery',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
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
  }

  Widget _buildRepaintWrapper(double fixedWidth, Widget childCard) {
    return Center(
      child: SizedBox(
        width: fixedWidth,
        child: FittedBox(
          fit: BoxFit.contain,
          child: RepaintBoundary(key: _cardKey, child: childCard),
        ),
      ),
    );
  }

  Widget _buildPolaroidCard() {
    // Correctly resolve the absolute image path using DBService
    final rawPath = widget.aiData['imagePath'] as String?;
    final imagePath = DBService.getImagePath(rawPath);
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final title = widget.aiData['localName'] ?? 'Unknown Fish';
    final score = _getScore();
    final price = widget.aiData['suggestedPrice'] ?? 'N/A';

    final date = DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}';

    final location = widget.aiData['location'] ?? 'Local Market';

    return Container(
      width: 420, // High-res base width for the capture
      decoration: BoxDecoration(
        color: const Color(
          0xFFFDFDFD,
        ), // Slightly warm white for vintage paper feel
        borderRadius: BorderRadius.circular(
          2,
        ), // Polaroid prints have very sharp corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        16,
      ), // Classic Polaroid proportions
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area with a physical inner border
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(
                  0.06,
                ), // Subtle border where photo meets paper
                width: 1.5,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1.0, // Strict Polaroid square format
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFE5E7EB),
                    child: hasImage
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.black26,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.cyanAccent,
                                size: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified by Illish',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Polaroid Bottom Margin (Typewriter details)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fish Name (Typewriter stamp)
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.specialElite(
                    color: const Color(0xFF1E293B),
                    fontSize: 28, // Increased for legibility
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Freshness & Price details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FRESHNESS: ${(score * 100).toInt()}%',
                      style: GoogleFonts.specialElite(
                        color: const Color(0xFF475569),
                        fontSize: 16, // Increased
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹$price/kg',
                      style: GoogleFonts.specialElite(
                        color: const Color(0xFF0F766E),
                        fontSize: 18, // Increased
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Date and Location note
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DATE: $dateStr',
                      style: GoogleFonts.specialElite(
                        color: const Color(0xFF64748B),
                        fontSize: 14, // Increased
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      location.toUpperCase(),
                      style: GoogleFonts.specialElite(
                        color: const Color(0xFF64748B),
                        fontSize: 14, // Increased
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions / Watermark Divider
          if (!_isCapturing)
            Container(
              height: 1,
              color: Colors.black.withOpacity(
                0.04,
              ), // Very faint line separating buttons
            ),

          const SizedBox(height: 8),

          // Bottom area: Buttons (if preview) or Watermark (if capturing)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isCapturing
                ? Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      'ILLISH AI • SCAN REPORT',
                      style: GoogleFonts.spaceMono(
                        color: Colors.black.withOpacity(
                          0.65,
                        ), // Prominent stamp watermark
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _captureAndShare(true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.black.withOpacity(0.08),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _captureAndShare(false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.ios_share_rounded, size: 20),
                            label: Text(
                              'Share',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
