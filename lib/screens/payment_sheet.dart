import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../config/app_config.dart';
import 'results_screen.dart';

class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const PaymentScreen({super.key, required this.aiData});

  Future<void> _launchUPI(BuildContext context) async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
    );
    
    // Bypass payment logic as requested
    await Future.delayed(const Duration(seconds: 1));
    
    if (context.mounted) {
      Navigator.pop(context); // pop dialog
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultsScreen(aiData: aiData)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B0F), // Very dark background matching mockup
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // Shield Icon with glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ]
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.neonCyan, size: 56),
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
              _buildFeatureRow(Icons.all_inclusive, "Unlimited scans", "All weekend"),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.auto_awesome, "AI freshness score", "With evidence"),
              const SizedBox(height: 16),
              _buildFeatureRow(Icons.restaurant, "Cuts, recipes & more", "Expert curated"),
              
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
                    ]
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
                      const Icon(Icons.double_arrow, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Footer tags
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text("Secure payment", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 24),
                  const Icon(Icons.check_circle_outline, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text("Cancel anytime", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatarPile(),
                  const SizedBox(width: 12),
                  Text("Trusted by 50K+ fish lovers", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
            ],
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
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
            child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[800], child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
          Positioned(
            left: 16,
            child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[700], child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
          Positioned(
            left: 32,
            child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[600], child: const Icon(Icons.person, size: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
