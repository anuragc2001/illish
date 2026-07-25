import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gal/gal.dart' as gal;
import '../main.dart';
import '../core/theme.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import 'recognition_sheet.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _currentLocation = 'Locating...';
  bool _isFlashOn = false;
  bool _isPickerOpen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initLocation();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        await _controller!.setFocusMode(FocusMode.auto);
        if (mounted) setState(() {});
      } on CameraException catch (e) {
        debugPrint('Camera exception: ${e.code}');
      }
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _currentLocation = 'Location disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _currentLocation = 'Location denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _currentLocation = 'Location denied');
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        if (mounted) {
          setState(() {
            _currentLocation = '${place.locality}, ${place.administrativeArea}';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocation = 'Unknown Location');
    }
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint('Failed to toggle flash: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickerOpen) return;
    _isPickerOpen = true;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _processImage(image.path, fromCamera: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please try again", style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      _isPickerOpen = false;
    }
  }

  void _takePictureAndIdentify() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile file = await _controller!.takePicture();
      _processImage(file.path, fromCamera: true);
    } catch (e) {
      debugPrint('Failed to take picture: $e');
    }
  }
  
  void _processImage(String imagePath, {bool fromCamera = false}) async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
    );
    
    // Save image to device gallery silently only if taken from camera
    if (fromCamera) {
      try {
        final hasAccess = await gal.Gal.hasAccess();
        if (!hasAccess) {
          await gal.Gal.requestAccess();
        }
        await gal.Gal.putImage(imagePath);
      } catch (e) {
        debugPrint('Failed to auto-save to gallery: $e');
      }
    }
    
    final aiService = AIService();
    final result = await aiService.analyzeFish(imagePath, _currentLocation);
    result['imagePath'] = imagePath;
    
    if (!mounted) return;
    Navigator.pop(context); // close dialog
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecognitionSheet(aiData: result),
    );
  }

  void _showRecentScans() async {
    final scans = await DBService.getRecentScans();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text("Recent Scans", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (scans.isEmpty)
              Expanded(
                child: Center(
                  child: Text("No scans yet. Scan a fish to get started.", style: GoogleFonts.inter(color: Colors.white54)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: scans.length,
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    return ListTile(
                      leading: scan.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(scan.imagePath!), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.white54)),
                          )
                        : const Icon(Icons.set_meal, color: Colors.white54),
                      title: Text(scan.englishName ?? 'Unknown', style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text('${scan.localName ?? ''} • ${scan.freshnessScore != null ? (scan.freshnessScore! * 100).toInt() : 0}% Fresh\n${scan.timestamp.toString().split('.')[0]}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.pop(context);
                        final aiData = {
                          'englishName': scan.englishName,
                          'localName': scan.localName,
                          'freshnessScore': scan.freshnessScore,
                          'freshnessStatus': scan.freshnessStatus,
                          'freshnessEvidence': scan.freshnessEvidence,
                          'bestCuts': scan.bestCuts,
                          'idealFor': scan.idealFor,
                          'imagePath': scan.imagePath,
                          'isOffline': false,
                        };
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen(aiData: aiData)));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! < -10) {
            _pickFromGallery();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
          // Camera Feed
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.width * _controller!.value.aspectRatio,
              child: GestureDetector(
                onTapDown: (details) async {
                  if (_controller == null || !_controller!.value.isInitialized) return;
                  final double x = details.localPosition.dx / size.width;
                  final double y = details.localPosition.dy / (size.width * _controller!.value.aspectRatio);
                  try {
                    await _controller!.setFocusPoint(Offset(x, y));
                    await _controller!.setExposurePoint(Offset(x, y));
                  } catch (e) {
                    debugPrint('Focus error: $e');
                  }
                },
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          
          // Top Bar
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppTheme.cardBackground,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Select Location", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.my_location, color: AppTheme.neonCyan),
                                  title: Text("Current Location", style: GoogleFonts.inter(color: Colors.white)),
                                  subtitle: Text(_currentLocation, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                  onTap: () => Navigator.pop(context),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.location_city, color: Colors.white54),
                                  title: Text("Kolkata, West Bengal", style: GoogleFonts.inter(color: Colors.white)),
                                  onTap: () {
                                    setState(() => _currentLocation = "Kolkata, West Bengal");
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(_currentLocation, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showRecentScans,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Center Reticle
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildBracket(false, false)),
                  Positioned(top: 0, right: 0, child: _buildBracket(false, true)),
                  Positioned(bottom: 0, left: 0, child: _buildBracket(true, false)),
                  Positioned(bottom: 0, right: 0, child: _buildBracket(true, true)),
                  
                  Center(
                    child: FadeTransition(
                      opacity: _pulseAnimation,
                      child: Text(
                        'Align head and\ngills here',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                          ]
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bottom Action Area
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28)
                      ),
                      GestureDetector(
                        onTap: _takePictureAndIdentify,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          ),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off, 
                          color: Colors.white, 
                          size: 28
                        )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Icon(Icons.keyboard_double_arrow_up, color: Colors.white70, size: 24),
              ],
            ),
          )
        ],
      ),
      ),
    );
  }

  Widget _buildBracket(bool isBottom, bool isRight) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isBottom ? BorderSide.none : const BorderSide(color: Colors.white, width: 3),
          bottom: isBottom ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isRight ? BorderSide.none : const BorderSide(color: Colors.white, width: 3),
          right: isRight ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (!isBottom && !isRight) ? const Radius.circular(12) : Radius.zero,
          topRight: (!isBottom && isRight) ? const Radius.circular(12) : Radius.zero,
          bottomLeft: (isBottom && !isRight) ? const Radius.circular(12) : Radius.zero,
          bottomRight: (isBottom && isRight) ? const Radius.circular(12) : Radius.zero,
        )
      ),
    );
  }
}
