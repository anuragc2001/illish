import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'results_screen.dart';
import '../services/admob_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> aiData;

  const PaymentScreen({super.key, required this.aiData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchUPI(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.neonCyan)),
    );

    // Bypass payment logic as requested
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.pop(context); // pop dialog
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResultsScreen(aiData: widget.aiData),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            return SlideTransition(
                position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF090B0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              AdMobService.handleResultsBackButton(onProceed: () => Navigator.pop(context));
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                AdMobService.showInterstitialAd(onAdDismissed: () {
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ResultsScreen(aiData: widget.aiData),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                              position: animation.drive(tween), child: child);
                        },
                      ),
                    );
                  }
                });
              },
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Shield Icon with glow
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppTheme.neonCyan, size: 56),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Headlines
                  Text(
                    "Don't buy stale fish.",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Unlock the AI Freshness\nScanner for the weekend.",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 4.0),
                        child: Text(
                          "₹",
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        "19",
                        style: GoogleFonts.inter(
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Features List
                  _buildFeatureRow(Icons.all_inclusive, "Unlimited scans",
                      "All weekend"),
                  const SizedBox(height: 24),
                  _buildFeatureRow(Icons.auto_awesome, "AI freshness score",
                      "With evidence"),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.restaurant, "Cuts, recipes & more",
                      "Expert curated"),

                  const Spacer(),

                  // Pay Button with Glow
                  GestureDetector(
                    onTap: () => _launchUPI(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pay with UPI",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.double_arrow,
                              color: Colors.black, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Colors.white54, size: 14),
                      const SizedBox(width: 6),
                      Text("Secure payment",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 24),
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white54, size: 14),
                      const SizedBox(width: 6),
                      Text("Cancel anytime",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatarPile(),
                      const SizedBox(width: 12),
                      Text("Trusted by 50K+ fish lovers",
                          style: GoogleFonts.inter(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: AppTheme.neonCyan, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAvatarPile() {
    return SizedBox(
      width: 60,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[800],
                child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
          Positioned(
            left: 16,
            child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[700],
                child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
          Positioned(
            left: 32,
            child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[600],
                child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
