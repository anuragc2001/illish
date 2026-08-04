import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class FreshnessMeter extends StatefulWidget {
  final int score;
  final int maxScore;

  const FreshnessMeter({
    Key? key,
    required this.score,
    this.maxScore = 100,
  }) : super(key: key);

  @override
  State<FreshnessMeter> createState() => _FreshnessMeterState();
}

class _FreshnessMeterState extends State<FreshnessMeter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _setupAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FreshnessMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score || oldWidget.maxScore != widget.maxScore) {
      _setupAnimation();
      _controller.forward(from: 0);
    }
  }

  void _setupAnimation() {
    double targetRatio = (widget.score / widget.maxScore).clamp(0.0, 1.0);
    _animation = Tween<double>(begin: 0.0, end: targetRatio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "YOUR FRESHNESS METER",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, color: Colors.white54, size: 14),
                ],
              ),
              Text(
                "This Month",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _MeterPainter(ratio: _animation.value),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.set_meal, color: Colors.white54, size: 32),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${(_animation.value * widget.maxScore).toInt()}",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                " /${widget.maxScore}",
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTierLabel(widget.score),
                            style: GoogleFonts.inter(
                              color: _getTierColor(widget.score),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up, color: AppTheme.emeraldGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                "Keep scanning to level up!",
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTierLabel(int score) {
    if (score >= 85) return "EXCELLENT SELECTION";
    if (score >= 70) return "GOOD QUALITY";
    if (score >= 50) return "AVERAGE SELECTION";
    return "BE CAREFUL";
  }

  Color _getTierColor(int score) {
    if (score >= 85) return AppTheme.emeraldGreen;
    if (score >= 70) return AppTheme.neonCyan;
    if (score >= 50) return Colors.amber;
    return Colors.redAccent;
  }
}

class _MeterPainter extends CustomPainter {
  final double ratio;

  _MeterPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20); // shift center down a bit
    final radius = min(size.width / 2.5, size.height - 20);

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = pi;
    const sweepAngle = pi; // semi-circle

    // Background track arc
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Active track arc with gradient
    const gradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [
        Colors.deepOrange,
        Colors.amber,
        Colors.greenAccent,
        Colors.tealAccent,
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final currentSweepAngle = sweepAngle * ratio;
    
    if (currentSweepAngle > 0) {
      canvas.drawArc(rect, startAngle, currentSweepAngle, false, activePaint);

      // Draw dot at the end
      final dotAngle = startAngle + currentSweepAngle;
      final dotCenter = Offset(
        center.dx + radius * cos(dotAngle),
        center.dy + radius * sin(dotAngle),
      );

      final dotPaint = Paint()..color = Colors.tealAccent; // Match end of gradient somewhat
      canvas.drawCircle(dotCenter, 10, dotPaint);
      
      final innerDotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotCenter, 4, innerDotPaint);
      
      // Glow effect for dot
      final glowPaint = Paint()
        ..color = Colors.tealAccent.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotCenter, 12, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) {
    return oldDelegate.ratio != ratio;
  }
}
