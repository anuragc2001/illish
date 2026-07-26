import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'results_screen.dart';
import 'payment_sheet.dart';

class RecognitionSheet extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const RecognitionSheet({super.key, required this.aiData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          Navigator.pop(context);
          Navigator.push(context, PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: aiData),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ));
        }
      },
      child: Stack(
        children: [
            // Full screen frosted glass with fade
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.95), // Deep black at top
                        Colors.black.withOpacity(0.6),
                        Colors.transparent, // Frosted but clear in the middle
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.95), // Deep black at bottom
                      ],
                      stops: const [0.0, 0.2, 0.45, 0.55, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Icon(aiData['error'] == true ? Icons.error_outline : Icons.blur_on, color: aiData['error'] == true ? Colors.redAccent.withOpacity(0.8) : AppTheme.neonCyan.withOpacity(0.8), size: 28),
                const SizedBox(height: 4),
                Text(
                  aiData['error'] == true ? 'SCAN FAILED' : 'SCAN COMPLETE',
                  style: GoogleFonts.inter(
                    color: aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan,
                    letterSpacing: 2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    aiData['error'] == true ? 'NETWORK ERROR' : (aiData['englishName']?.toUpperCase() ?? 'UNKNOWN'),
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: aiData['error'] == true ? Colors.redAccent.withOpacity(0.1) : AppTheme.neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: aiData['error'] == true ? Colors.redAccent.withOpacity(0.3) : AppTheme.neonCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(aiData['error'] == true ? Icons.warning_amber : Icons.location_on, color: aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        aiData['error'] == true ? (aiData['errorType'] == 'offline' ? 'Offline' : 'High Latency') : (aiData['localName'] ?? 'Unknown'),
                        style: GoogleFonts.inter(
                          color: aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                  
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: aiData),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(position: animation.drive(tween), child: child);
                        },
                      ));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Freshness Check',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Analyzing gills, eyes, skin...',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                              ),
                              child: const Icon(Icons.lock_outline, color: AppTheme.neonCyan, size: 14),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  
                  // Bottom Swipe Area
                  const Icon(Icons.keyboard_double_arrow_up, color: Colors.white54),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe up for cuts & recipes',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            Positioned(
              top: (MediaQuery.paddingOf(context).top > 0 
                  ? MediaQuery.paddingOf(context).top 
                  : 47.0) + 16.0,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.ios_share, color: Colors.white, size: 24),
                      onPressed: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Freshness report link copied to clipboard!',
                              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppTheme.neonCyan,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
