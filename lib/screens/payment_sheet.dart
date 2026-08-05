import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'results_screen.dart';
import '../services/admob_service.dart';
import '../services/db_service.dart';
import '../services/remote_config_service.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> aiData;
  final int? scanId;

  const PaymentScreen({super.key, required this.aiData, this.scanId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI Switch: dynamically fetched
  bool get _showSinglePrice => RemoteConfigService.showSinglePrice;
  String _selectedPlan = 'weekly';

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

    bool success = false;
    try {
      double amount = 0;
      if (_showSinglePrice) {
        amount = double.tryParse(RemoteConfigService.priceWeekly.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 29.0;
      } else {
        if (_selectedPlan == 'weekly') {
          amount = double.tryParse(RemoteConfigService.priceWeekly.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 29.0;
        } else if (_selectedPlan == 'monthly') {
          amount = double.tryParse(RemoteConfigService.priceMonthly.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99.0;
        } else {
          amount = double.tryParse(RemoteConfigService.priceAnnual.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 499.0;
        }
      }

      success = await PaymentService.startPhonePeCheckout(planId: _selectedPlan, amount: amount);
    } catch (e) {
      print("Error in _launchUPI: $e");
      success = false;
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // guaranteed to pop loading dialog
      }
    }

    if (context.mounted) {
      if (success) {
        if (widget.scanId != null) {
          await DBService.unlockScan(widget.scanId!);
          if (!mounted) return;
          Navigator.pop(context); // pop payment sheet
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
        } else {
          // If no scanId, it was called directly from Profile settings
          Navigator.pop(context); // pop payment sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome to Illish Pro!")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed or cancelled.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: RemoteConfigService.configUpdateNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF090B0F),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Custom Header and Shield overlapping to save vertical space
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Shield Icon with glow
                          Padding(
                            padding: const EdgeInsets.only(top: 28),
                            child: ScaleTransition(
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
                          ),
                          // Back and Skip Buttons
                          Positioned(
                            top: 12,
                            left: 8,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                  onPressed: () {
                                    AdMobService.handleResultsBackButton(onProceed: () => Navigator.pop(context));
                                  },
                                ),
                                TextButton(
                                  onPressed: () {
                                    AdMobService.showInterstitialAd(onAdDismissed: () async {
                                      if (widget.scanId != null) {
                                        await DBService.unlockScan(widget.scanId!);
                                      }
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Main Content Body with its original 24px padding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

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
                            _showSinglePrice 
                                ? "Unlock the AI Freshness\nScanner for the weekend."
                                : "Unlock unlimited AI freshness scans & expert\ncuts.",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          if (_showSinglePrice) ...[
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
                                  RemoteConfigService.priceWeekly.replaceAll(RegExp(r'[^0-9.]'), ''),
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
                            const SizedBox(height: 20),
                            _buildFeatureRow(Icons.auto_awesome, "AI freshness score",
                                "With evidence"),
                            const SizedBox(height: 20),
                            _buildFeatureRow(Icons.restaurant, "Cuts, recipes & more",
                                "Expert curated"),

                            // Guaranteed mathematical gap replacing Spacer() so it never overlaps
                            SizedBox(height: MediaQuery.sizeOf(context).height * 0.04),
                          ] else ...[
                            // Features List
                            _buildFeatureRow(Icons.all_inclusive, "Unlimited scans",
                                "No daily limits"),
                            const SizedBox(height: 16),
                            _buildFeatureRow(Icons.auto_awesome, "AI freshness score",
                                "With evidence"),
                            const SizedBox(height: 16),
                            _buildFeatureRow(Icons.restaurant, "Cuts, recipes & more",
                                "Expert curated"),
                            const SizedBox(height: 20),

                            // Plans
                            _buildPlanCard('weekly', 'Weekly Pass', RemoteConfigService.priceWeekly, 'Perfect for casual buyers'),
                            _buildPlanCard('monthly', 'Illish Pro', RemoteConfigService.priceMonthly, 'Cancel anytime'),
                            _buildPlanCard('annual', 'Pro Annual', RemoteConfigService.priceAnnual, 'Save 58%', bestValue: true),
                            const SizedBox(height: 16),
                          ],

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
                                    "Continue",
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

                          if (!_showSinglePrice) ...[
                            const SizedBox(height: 16),
                            /* --- COMMENTED OUT FOR FUTURE BUSINESS DECISION ---
                            // Trust Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people, color: Colors.white54, size: 14),
                                const SizedBox(width: 8),
                                Text("Trusted by 50K+ fish lovers",
                                    style: GoogleFonts.inter(
                                        color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            -------------------------------------------------- */
                          ],

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildPlanCard(String id, String title, String price, String subtitle, {bool bestValue = false}) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonCyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.neonCyan : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Check box
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.neonCyan : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.neonCyan : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (bestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "BEST VALUE",
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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


}
