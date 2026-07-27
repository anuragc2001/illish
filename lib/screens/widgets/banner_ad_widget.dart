import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/app_config.dart';
import '../../core/theme.dart';
import '../../services/admob_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize size;
  
  const BannerAdWidget({super.key, this.size = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdWidget? _adWidget;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (AppConfig.kIsPremiumUser) return; // No ads for premium users

    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      request: const AdRequest(),
      size: widget.size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _adWidget = AdWidget(ad: _bannerAd!);
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.kIsPremiumUser) {
      return const SizedBox.shrink(); // Hide instantly for premium
    }

    if (!_isLoaded || _bannerAd == null) {
      return Container(
        width: widget.size.width.toDouble(),
        height: widget.size.height.toDouble(),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      ); // Keep space while loading to prevent UI jump
    }

    return Container(
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.neonCyan.withOpacity(0.6), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: _adWidget,
    );
  }
}
