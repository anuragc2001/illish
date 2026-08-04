import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gal/gal.dart' as gal;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../main.dart';
import '../core/theme.dart';
import '../config/app_config.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import 'recognition_sheet.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import '../core/models/scan_record.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  int _cameraIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Offset? _focusPoint;
  late AnimationController _focusController;
  late AnimationController _locAnimController;
  late Animation<double> _locAnimation;

  String _currentLocation = 'Locating...';
  List<String> _locationHistory = [];
  bool _isFlashOn = false;
  bool _isPickerOpen = false;
  bool _isUIHidden = false;
  final ImagePicker _picker = ImagePicker();
  Timer? _locationTimer; // Deprecated, kept for reference if needed
  StreamSubscription<Position>? _positionStreamSubscription;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 5.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initCamera().then((_) {
      if (mounted) {
        _initLocation();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _focusController.reverse();
        });
      }
    });

    _locAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _locAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _locAnimController, curve: Curves.easeOutExpo),
    );

    _loadLocationHistory();
  }

  Future<void> _loadLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _locationHistory = prefs.getStringList('location_history') ?? [];
      });
    }
  }

  Future<void> _saveLocationHistory(String newLoc) async {
    if (newLoc.isEmpty || newLoc.contains('denied') || newLoc == 'Locating...')
      return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('location_history') ?? [];
    history.remove(newLoc);
    history.insert(0, newLoc);
    if (history.length > 5) history = history.sublist(0, 5);
    await prefs.setStringList('location_history', history);
    if (mounted) {
      setState(() {
        _locationHistory = history;
      });
    }
  }

  void _triggerLocationAnimation() {
    if (mounted) {
      _locAnimController.forward().then((_) {
        if (mounted) _locAnimController.reverse();
      });
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        await _controller!.setFocusMode(FocusMode.auto);
        _minZoom = await _controller!.getMinZoomLevel();
        final maxZ = await _controller!.getMaxZoomLevel();
        _maxZoom = maxZ.clamp(1.0, 5.0);
        if (mounted) setState(() {});
      } on CameraException catch (e) {
        debugPrint('Camera exception: ${e.code}');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    setState(() {
      _cameraIndex = (_cameraIndex + 1) % cameras.length;
    });
    // Wait for the new camera to initialize
    await _initCamera();
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
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          final loc = '${place.locality}, ${place.administrativeArea}';
          if (mounted) {
            setState(() {
              _currentLocation = loc;
            });
            _saveLocationHistory(loc);
            _triggerLocationAnimation();
          }
        }
      } catch (geocodingError) {
        debugPrint('Geocoding error: $geocodingError');
        if (mounted) {
          final loc =
              '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
          setState(() {
            _currentLocation = loc;
          });
          _saveLocationHistory(loc);
          _triggerLocationAnimation();
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        // Fallback if completely unable to get GPS
        setState(() => _currentLocation = 'Unknown Location');
      }
    }

    // Start background distance tracking only after permissions are confirmed
    if (_positionStreamSubscription == null) {
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 500, // 500 meters travel distance
            ),
          ).listen(
            (Position position) {
              if (mounted) {
                _updateLocationFromPosition(position);
              }
            },
            onError: (e) {
              debugPrint('Location stream error: $e');
            },
          );
    }
  }

  Future<void> _updateLocationFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final loc = '${place.locality}, ${place.administrativeArea}';
        if (mounted) {
          setState(() {
            _currentLocation = loc;
          });
          _saveLocationHistory(loc);
        }
      }
    } catch (geocodingError) {
      debugPrint('Stream Geocoding error: $geocodingError');
      if (mounted) {
        final loc =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        setState(() {
          _currentLocation = loc;
        });
        _saveLocationHistory(loc);
      }
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    setState(() => _currentZoom = clamped);
    try {
      await _controller!.setZoomLevel(clamped);
    } catch (e) {
      debugPrint('Zoom error: $e');
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
            content: Text(
              "Please try again",
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      _isPickerOpen = false;
    }
  }

  void _takePictureAndIdentify() async {
    HapticFeedback.lightImpact();
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile file = await _controller!.takePicture();
      _processImage(file.path, fromCamera: true);
    } catch (e) {
      debugPrint('Failed to take picture: $e');
    }
  }

  void _processImage(String imagePath, {bool fromCamera = false}) async {
    String processedPath = imagePath;
    String savedFilename = imagePath.split('/').last;

    try {
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last.replaceAll('.png', '.jpg')}';
      final targetPath = '${AppConfig.documentsPath}/$filename';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        processedPath = compressedFile.path;
        savedFilename = filename;
      }
    } catch (e) {
      debugPrint('Failed to compress image before AI analysis: $e');
    }

    final aiService = AIService();
    final operation = aiService.analyzeFish(processedPath, _currentLocation);
    bool isCancelled = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HUDThumbnail(processedPath),
                        const SizedBox(height: 24),
                        Text(
                          "Analyzing freshness...",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                borderRadius: BorderRadius.circular(100),
                                onPressed: () {
                                  isCancelled = true;
                                  operation.cancel();
                                  Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.close,
                                      color: AppTheme.neonCyan,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Cancel & Retake",
                                      style: GoogleFonts.inter(
                                        color: AppTheme.neonCyan,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final result = await operation.valueOrCancellation();
    if (!mounted || isCancelled) return;

    Navigator.pop(context); // close dialog
    if (result != null) {
      result['imagePath'] = savedFilename;

      int? savedId;
      if (result['error'] != true) {
        savedId = await DBService.saveScan(result, isBookmark: false);
        result['id'] = savedId;
      }
      final eName = result['englishName']?.toString().toLowerCase() ?? '';
      final isUnknown =
          eName == 'unknown' ||
          eName == 'unknown fish' ||
          result['error'] == true;

      setState(() => _isUIHidden = true);
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: false, // Prevents black gaps
        backgroundColor: Colors.transparent,
        builder: (context) => RecognitionSheet(aiData: result, scanId: savedId),
      );
      if (mounted) setState(() => _isUIHidden = false);
    }
  }

  void _showRecentScans() async {
    // We'll pass the context to a stateful widget to handle tabs
    showModalBottomSheet(
      context: context,
      useSafeArea: false, // Prevents black gaps
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const SavedItemsSheet(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _controller?.resumePreview();

      // Fetch location when app is brought back to foreground
      if (mounted) {
        _initLocation();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _controller?.dispose();
    _pulseController.dispose();
    _focusController.dispose();
    _locAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonCyan),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);

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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onScaleStart: (details) {
                        _baseZoom = _currentZoom;
                      },
                      onScaleUpdate: (details) {
                        _setZoom(_baseZoom * details.scale);
                      },
                      onDoubleTap: _switchCamera,
                      onTapDown: (details) async {
                        if (_controller == null ||
                            !_controller!.value.isInitialized)
                          return;
                        final double x = details.localPosition.dx / size.width;
                        final double y =
                            details.localPosition.dy /
                            (size.width * _controller!.value.aspectRatio);
                        setState(() => _focusPoint = details.localPosition);
                        _focusController.forward(from: 0.0);
                        try {
                          await _controller!.setFocusPoint(Offset(x, y));
                          await _controller!.setExposurePoint(Offset(x, y));
                          await _controller!.setFocusMode(FocusMode.auto);
                          await _controller!.setExposureMode(ExposureMode.auto);
                        } catch (e) {
                          debugPrint('Focus error: $e');
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        child:
                            _controller != null &&
                                _controller!.value.isInitialized
                            ? CameraPreview(
                                _controller!,
                                key: ValueKey<int>(_cameraIndex),
                              )
                            : Container(
                                key: const ValueKey('empty'),
                                color: Colors.black,
                              ),
                      ),
                    ),
                    if (_focusPoint != null)
                      Positioned(
                        left: _focusPoint!.dx - 25,
                        top: _focusPoint!.dy - 25,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1.5, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _focusController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: _focusController,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.yellowAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // UI Elements Overlay
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isUIHidden ? 0.0 : 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Top Bar
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (!Platform.isIOS)
                                GestureDetector(
                                  onTap: () => SystemNavigator.pop(),
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              if (!Platform.isIOS) const SizedBox(width: 12),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 220,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          useSafeArea:
                                              false, // Prevents black gaps
                                          isScrollControlled: true,
                                          backgroundColor:
                                              AppTheme.cardBackground,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                          ),
                                          builder: (context) => SafeArea(
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Select Location",
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.my_location,
                                                        color:
                                                            AppTheme.neonCyan,
                                                      ),
                                                      title: Text(
                                                        "Current Location",
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      subtitle: Text(
                                                        "Detect using GPS",
                                                        style:
                                                            GoogleFonts.inter(
                                                              color: Colors
                                                                  .white54,
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        setState(
                                                          () =>
                                                              _currentLocation =
                                                                  "Locating...",
                                                        );
                                                        _initLocation();
                                                      },
                                                    ),
                                                    const Divider(
                                                      color: Colors.white10,
                                                    ),
                                                    if (_locationHistory
                                                        .isNotEmpty) ...[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8,
                                                            ),
                                                        child: Text(
                                                          "RECENT",
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: Colors
                                                                    .white38,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      ..._locationHistory.map(
                                                        (loc) => ListTile(
                                                          leading: const Icon(
                                                            Icons.history,
                                                            color:
                                                                Colors.white54,
                                                          ),
                                                          title: Text(
                                                            loc,
                                                            style:
                                                                GoogleFonts.inter(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                          onTap: () {
                                                            setState(
                                                              () =>
                                                                  _currentLocation =
                                                                      loc,
                                                            );
                                                            _saveLocationHistory(
                                                              loc,
                                                            );
                                                            _triggerLocationAnimation();
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const Divider(
                                                        color: Colors.white10,
                                                      ),
                                                    ],
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      child: Text(
                                                        "NEARBY CITIES",
                                                        style:
                                                            GoogleFonts.inter(
                                                              color: Colors
                                                                  .white38,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.location_city,
                                                        color: Colors.white54,
                                                      ),
                                                      title: Text(
                                                        "Kolkata, West Bengal",
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      onTap: () {
                                                        setState(
                                                          () => _currentLocation =
                                                              "Kolkata, West Bengal",
                                                        );
                                                        _saveLocationHistory(
                                                          "Kolkata, West Bengal",
                                                        );
                                                        _triggerLocationAnimation();
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            ScaleTransition(
                                              scale: _locAnimation,
                                              child: const Icon(
                                                Icons.location_on,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _currentLocation,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _showRecentScans,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  NotificationService().unreadCount,
                              builder: (context, count, child) {
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        if (count > 0)
                                          Positioned(
                                            right: -6,
                                            top: -6,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                count > 9 ? '9+' : '$count',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildBracket(false, false),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildBracket(false, true),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: _buildBracket(true, false),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _buildBracket(true, true),
                          ),

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
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                        // Zoom Pills (1x / 2x Macro mode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [1.0, 2.0].map((z) {
                            final isSelected = (_currentZoom - z).abs() < 0.2;
                            return GestureDetector(
                              onTap: () => _setZoom(z),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.neonCyan
                                      : Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.neonCyan
                                        : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${z.toInt()}x',
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _pickFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _takePictureAndIdentify,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.neonCyan.withOpacity(0.5),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: AppTheme.neonCyan.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.neonCyan
                                                .withOpacity(0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleFlash,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _isFlashOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Icon(
                          Icons.keyboard_double_arrow_up,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  // End of UI Elements Overlay
                ],
              ),
            ),
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
          top: isBottom
              ? BorderSide.none
              : const BorderSide(color: Colors.white, width: 3),
          bottom: isBottom
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: isRight
              ? BorderSide.none
              : const BorderSide(color: Colors.white, width: 3),
          right: isRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (!isBottom && !isRight)
              ? const Radius.circular(12)
              : Radius.zero,
          topRight: (!isBottom && isRight)
              ? const Radius.circular(12)
              : Radius.zero,
          bottomLeft: (isBottom && !isRight)
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: (isBottom && isRight)
              ? const Radius.circular(12)
              : Radius.zero,
        ),
      ),
    );
  }
}

class _HUDThumbnail extends StatefulWidget {
  final String imagePath;
  const _HUDThumbnail(this.imagePath);

  @override
  State<_HUDThumbnail> createState() => _HUDThumbnailState();
}

class _HUDThumbnailState extends State<_HUDThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withOpacity(0.1 + 0.3 * _anim.value),
                blurRadius: 10 + 20 * _anim.value,
                spreadRadius: 2 + 5 * _anim.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipOval(
        child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

class SavedItemsSheet extends StatefulWidget {
  const SavedItemsSheet({super.key});

  @override
  State<SavedItemsSheet> createState() => _SavedItemsSheetState();
}

class _SavedItemsSheetState extends State<SavedItemsSheet> {
  bool _isRecent = true; // true = Recent Scans, false = Bookmarks
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isClearing = false;

  late final ScrollController _scrollController;
  static const int _pageSize = 15;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  StreamSubscription<void>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadData();

    _dbSubscription = DBService.isar.scanRecords.watchLazy().listen((_) {
      if (mounted) {
        _loadData(showSpinner: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _dbSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _hasMore = true;
        _items = [];
      });
    }

    final newItems = _isRecent
        ? await DBService.getRecentScans(offset: 0, limit: _pageSize)
        : await DBService.getBookmarks(offset: 0, limit: _pageSize);

    if (mounted) {
      setState(() {
        _items = newItems;
        _offset = newItems.length;
        _hasMore = newItems.length == _pageSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final newItems = _isRecent
        ? await DBService.getRecentScans(offset: _offset, limit: _pageSize)
        : await DBService.getBookmarks(offset: _offset, limit: _pageSize);

    if (mounted) {
      setState(() {
        _items.addAll(newItems);
        _offset += newItems.length;
        _hasMore = newItems.length == _pageSize;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a fixed height container rather than DraggableScrollableSheet
    // to fix the swipe-down dismiss animation stutter (Fix 12).
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab("Recent Scans", true),
                const SizedBox(width: 16),
                _buildTab("Bookmarks", false),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (!_isLoading && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Swipe left to remove",
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  if (_isRecent)
                    GestureDetector(
                      onTap: () async {
                        if (_items.isEmpty || _isClearing) return;
                        setState(() {
                          _isClearing = true;
                        });
                        // Calculate total animation time based on visible list size (max out around 1 second)
                        final totalTimeMs = 300 + (_items.length * 40);
                        await Future.delayed(
                          Duration(
                            milliseconds: totalTimeMs > 1000
                                ? 1000
                                : totalTimeMs,
                          ),
                        );

                        await DBService.hideRecentScans(); // Soft delete

                        if (mounted) {
                          setState(() {
                            _items.clear();
                            _isClearing = false;
                          });
                        }
                      },
                      child: Text(
                        "Clear All",
                        style: GoogleFonts.inter(
                          color: Colors.redAccent, // Made it red as requested
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  )
                : _items.isEmpty
                ? Center(
                    child: Text(
                      "No scans found",
                      style: GoogleFonts.inter(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppTheme.neonCyan,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = _items[index];
                      // Base animation delay is 100ms, each item after adds 40ms so they swipe sequentially right to left
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 40)),
                        curve:
                            Curves.easeInCubic, // Starts slow, picks up speed
                        transform: Matrix4.translationValues(
                          _isClearing ? -MediaQuery.sizeOf(context).width : 0,
                          0,
                          0,
                        ),
                        child: Dismissible(
                          key: Key(item.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent.withOpacity(0.2),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                          onDismissed: (direction) async {
                            if (!_isRecent) {
                              await DBService.setBookmarkStatus(
                                item.id,
                                item.imagePath,
                                false,
                              );
                            } else {
                              await DBService.hideScan(item.id); // Soft delete
                            }
                            setState(() {
                              _items.removeWhere((e) => e.id == item.id);
                            });
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: item.imagePath != null
                                  ? Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            File(
                                              DBService.getImagePath(
                                                    item.imagePath!,
                                                  ) ??
                                                  '',
                                            ),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return const Icon(
                                                Icons.image,
                                                color: Colors.white54,
                                              );
                                            },
                                          ),
                                        ),
                                        if (!AppConfig.isPremiumUser &&
                                            !item.isUnlocked)
                                          Positioned(
                                            top: -4,
                                            left: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.8,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white24,
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : const Icon(
                                      Icons.set_meal,
                                      color: Colors.white54,
                                    ),
                              title: Text(
                                item.englishName ?? 'Unknown',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${item.localName ?? ''} • ${DBService.formatAmPm(item.timestamp)} • ${item.freshnessScore != null ? (item.freshnessScore! * 100).toInt() : 0}% Fresh',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_left,
                                color: Colors.white24,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                final aiData = {
                                  'id': item.id,
                                  'englishName': item.englishName,
                                  'localName': item.localName,
                                  'freshnessScore': item.freshnessScore,
                                  'freshnessStatus': item.freshnessStatus,
                                  'freshnessEvidence': item.freshnessEvidence,
                                  'bestCuts': item.bestCuts,
                                  'idealFor': item.idealFor,
                                  'trickeryTips': item.trickeryTips,
                                  'suggestedPrice': item.suggestedPrice,
                                  'marketAvgPrice': item.marketAvgPrice,
                                  'imagePath': item.imagePath,
                                  'isOffline': false,
                                  'timestamp': item.timestamp.toIso8601String(),
                                  'location': item.region,
                                };

                                if (!AppConfig.isPremiumUser &&
                                    !item.isUnlocked) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: false,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => RecognitionSheet(
                                      aiData: aiData,
                                      scanId: item.id,
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ResultsScreen(aiData: aiData),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isRecentTab) {
    final isActive = _isRecent == isRecentTab;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() => _isRecent = isRecentTab);
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          _loadData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.neonCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? AppTheme.neonCyan : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? AppTheme.neonCyan : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
