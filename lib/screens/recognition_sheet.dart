import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'results_screen.dart';
import 'payment_sheet.dart';
import '../config/app_config.dart';
import 'widgets/banner_ad_widget.dart';
import '../services/admob_service.dart';

class RecognitionSheet extends StatefulWidget {
  final Map<String, dynamic> aiData;
  final int? scanId;
  const RecognitionSheet({super.key, required this.aiData, this.scanId});

  @override
  State<RecognitionSheet> createState() => _RecognitionSheetState();
}

class _RecognitionSheetState extends State<RecognitionSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    if (widget.scanId != null) {
      widget.aiData['id'] = widget.scanId;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleAction() async {
    if (AppConfig.isPremiumUser) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultsScreen(aiData: widget.aiData),
      ));
      return;
    }

    setState(() => _isUnlocking = true);
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => PaymentScreen(aiData: widget.aiData, scanId: widget.scanId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (widget.aiData['error'] != true && details.primaryVelocity != null && details.primaryVelocity! < -300) {
          _handleAction();
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
                Icon(
                  widget.aiData['error'] == true 
                      ? (widget.aiData['errorType'] == 'invalid_image' 
                          ? Icons.image_not_supported 
                          : (widget.aiData['errorType'] == 'offline' ? Icons.wifi_off : Icons.error_outline)) 
                      : Icons.blur_on, 
                  color: widget.aiData['error'] == true ? Colors.redAccent.withOpacity(0.8) : AppTheme.neonCyan.withOpacity(0.8), 
                  size: 28
                ),
                const SizedBox(height: 4),
                Text(
                  widget.aiData['error'] == true 
                      ? (widget.aiData['errorType'] == 'invalid_image' 
                          ? 'INVALID IMAGE' 
                          : (widget.aiData['errorType'] == 'offline' ? 'OFFLINE' : 'SCAN FAILED')) 
                      : 'SCAN COMPLETE',
                  style: GoogleFonts.inter(
                    color: widget.aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan,
                    letterSpacing: 2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.aiData['error'] == true ? (widget.aiData['errorType'] == 'invalid_image' ? 'NOT AQUATIC LIFE' : 'NETWORK ERROR') : (widget.aiData['englishName']?.toUpperCase() ?? 'UNKNOWN'),
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
                    color: widget.aiData['error'] == true ? Colors.redAccent.withOpacity(0.1) : AppTheme.neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: widget.aiData['error'] == true ? Colors.redAccent.withOpacity(0.3) : AppTheme.neonCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.aiData['error'] == true ? Icons.warning_amber : Icons.location_on, color: widget.aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.aiData['error'] == true ? (widget.aiData['errorType'] == 'offline' ? 'Offline' : (widget.aiData['errorType'] == 'invalid_image' ? 'Try Again' : 'High Latency')) : (widget.aiData['localName'] ?? 'Unknown'),
                        style: GoogleFonts.inter(
                          color: widget.aiData['error'] == true ? Colors.redAccent : AppTheme.neonCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                  
                  if (widget.aiData['error'] == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        widget.aiData['errorType'] == 'invalid_image' 
                            ? (widget.aiData['errorReason'] ?? 'The image doesn\'t appear to be aquatic life. Please make sure the subject is clear.')
                            : (widget.aiData['errorType'] == 'offline' 
                                ? 'No internet connection. Please check your network and try again.' 
                                : 'The server took too long to respond. Please try again.'),
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _handleAction,
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
                            if (AppConfig.isPremiumUser)
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.greenAccent.withOpacity(0.4 + 0.6 * _animController.value),
                                        width: 1.5
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0.3 * _animController.value),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.check, color: Colors.greenAccent, size: 14),
                                  );
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return ScaleTransition(scale: animation, child: child);
                                  },
                                  child: Icon(
                                    _isUnlocking ? Icons.lock_open : Icons.lock_outline,
                                    key: ValueKey<bool>(_isUnlocking),
                                    color: AppTheme.neonCyan,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),


                  const Spacer(flex: 2),
                  
                  if (widget.aiData['error'] != true) ...[
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
                  ],
                  if (!AppConfig.isPremiumUser)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: BannerAdWidget(),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            Positioned(
              top: (MediaQuery.paddingOf(context).top > 0 
                  ? MediaQuery.paddingOf(context).top 
                  : 47.0) + 16.0,
              left: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () {
                    if (widget.aiData['error'] == true) {
                      Navigator.pop(context);
                    } else {
                      AdMobService.handleResultsBackButton(onProceed: () => Navigator.pop(context));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
    );
  }
}
