import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';

class UcbPaymentSelector extends StatelessWidget {
  final String planId;
  final double amount;
  final String displayPrice;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentError;

  const UcbPaymentSelector({
    super.key,
    required this.planId,
    required this.amount,
    required this.displayPrice,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  static void show(
    BuildContext context, {
    required String planId,
    required double amount,
    required String displayPrice,
    required VoidCallback onPaymentSuccess,
    required VoidCallback onPaymentError,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UcbPaymentSelector(
        planId: planId,
        amount: amount,
        displayPrice: displayPrice,
        onPaymentSuccess: () {
          Navigator.pop(ctx); // Close sheet
          onPaymentSuccess();
        },
        onPaymentError: () {
          Navigator.pop(ctx); // Close sheet
          onPaymentError();
        },
      ),
    );
  }

  void _processPayment(BuildContext context, String provider) async {
    // Show a loading overlay within the sheet if needed, or rely on native UI.
    bool success = false;
    
    if (provider == 'google_play') {
      success = await PaymentService.startGooglePlayCheckout(
        planId: planId,
        amount: amount,
      );
    } else if (provider == 'apple_app_store') {
      success = await PaymentService.startAppleAppStoreCheckout(
        planId: planId,
        amount: amount,
      );
    } else if (provider == 'razorpay') {
      success = await PaymentService.startRazorpayCheckout(
        planId: planId,
        amount: amount,
      );
    }

    if (success) {
      onPaymentSuccess();
    } else {
      onPaymentError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151921),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choose Payment Method',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Securely complete your purchase of $displayPrice',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            // Native Option (Google Play or Apple App Store)
            _buildOption(
              context: context,
              title: isIOS ? 'Apple App Store' : 'Google Play',
              subtitle: isIOS ? 'Apple Pay, Saved Cards' : 'UPI, Play Balance, Saved Cards',
              imageUrl: isIOS 
                  ? 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/App_Store_%28iOS%29.svg/1024px-App_Store_%28iOS%29.svg.png'
                  : 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Google_Play_Arrow_logo.svg/1024px-Google_Play_Arrow_logo.svg.png',
              provider: isIOS ? 'apple_app_store' : 'google_play',
            ),
            
            const SizedBox(height: 16),
            
            // Razorpay Option
            _buildOption(
              context: context,
              title: 'Razorpay',
              subtitle: 'Direct UPI, Cards, Netbanking, Wallets',
              imageUrl: 'https://avatars.githubusercontent.com/u/7713209?s=200&v=4',
              provider: 'razorpay',
            ),
            
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String provider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _processPayment(context, provider),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, color: Colors.black),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
