import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'payment_sheet.dart';

class RecognitionSheet extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const RecognitionSheet({super.key, required this.aiData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) {
            Navigator.pop(context);
            Navigator.push(context, PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PaymentScreen(aiData: aiData),
            ));
          }
        },
        child: Stack(
          children: [
            // Full screen frosted glass
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
            
            // Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Center Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Column(
                    children: [
                      Icon(Icons.blur_on, color: AppTheme.neonCyan.withOpacity(0.8), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'BAZAAR AI',
                        style: GoogleFonts.inter(
                          color: AppTheme.neonCyan,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    aiData['englishName']?.toUpperCase() ?? 'UNKNOWN',
                    style: GoogleFonts.inter(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiData['localName'] ?? '', 
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => PaymentScreen(aiData: aiData),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
