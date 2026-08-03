import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

class PhoneAuthSheet extends StatefulWidget {
  const PhoneAuthSheet({Key? key}) : super(key: key);

  @override
  State<PhoneAuthSheet> createState() => _PhoneAuthSheetState();
}

class _PhoneAuthSheetState extends State<PhoneAuthSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _codeSent = false;
  bool _isLoading = false;
  String _verificationId = '';

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      _showError("Please enter a valid phone number");
      return;
    }

    setState(() => _isLoading = true);

    // Standardize to Indian format for now, or assume user adds +91
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+91$phone'; // Defaulting to India, user can modify
    }

    try {
      await AuthService.verifyPhoneNumber(
        phoneNumber: phone,
        codeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            _showError(e.message ?? "Verification failed");
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length < 6) {
      _showError("Please enter the 6-digit code");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.verifyOTP(_verificationId, _otpController.text.trim());
      if (mounted) {
        Navigator.pop(context); // Close sheet on success
      }
    } catch (e) {
      _showError("Invalid OTP. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding for keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _codeSent ? "Enter OTP" : "Phone Verification",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? "Enter the 6-digit code sent to ${_phoneController.text}"
                      : "We'll send you an SMS to verify your number",
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                
                if (!_codeSent) ...[
                  _buildTextField(
                    controller: _phoneController,
                    hintText: "Phone Number (e.g. 9876543210)",
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _otpController,
                    hintText: "6-digit code",
                    icon: Icons.message_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_codeSent ? _verifyOTP : _sendCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _codeSent ? "Verify" : "Send Code",
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _otpController.clear();
                        });
                      },
                      child: Text(
                        "Change phone number",
                        style: GoogleFonts.inter(
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.neonCyan),
        ),
      ),
    );
  }
}
