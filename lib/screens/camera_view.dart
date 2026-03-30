import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/stamp.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class CameraView extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onPhotoTaken;

  const CameraView({Key? key, required this.storageService, required this.onPhotoTaken}) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  late AnimationController _punchController;
  late Animation<double> _punchAnimation;
  int _currentCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _punchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _punchAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _punchController, curve: Curves.easeIn, reverseCurve: Curves.easeOut),
    );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _setCamera(_cameras![0]);
    }
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      print("Error initializing camera: \$e");
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    // Play punch animation
    await _punchController.forward();

    try {
      final XFile pic = await _controller!.takePicture();
      
      // Get location (using basic coords for now as reverse geocoding requires network or API)
      Position? position;
      String locName = "Unknown Location";
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        locName = "\${position.latitude.toStringAsFixed(2)}, \${position.longitude.toStringAsFixed(2)}";
      } catch (e) {
        print("Could not get location: \$e");
      }

      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '\${directory.path}/stamp_\$timestamp.png';
      await File(pic.path).copy(fullPath);

      final stamp = Stamp(
        id: timestamp,
        filePath: fullPath,
        locationName: locName,
        dateTime: DateTime.now(),
      );

      await widget.storageService.saveStamp(stamp);
      _punchController.reverse(); // finish animation

      // Notify parent to perhaps switch tab or update library
      widget.onPhotoTaken();
      
    } catch (e) {
      print(e);
      _punchController.reverse();
    }
  }

  void _flipCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _currentCameraIdx = (_currentCameraIdx + 1) % _cameras!.length;
    _setCamera(_cameras![_currentCameraIdx]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _punchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
             child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
             ),
          ),
          
          // Vignette
          Container(color: Colors.black38),
          
          // Back Button / App Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {}, // Close app if needed
                ),
                const Text("Puncher", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Work Sans')),
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () {}, // Toggle flash
                )
              ],
            ),
          ),

          // Stamp Cutout Overlay
          Center(
            child: ScaleTransition(
              scale: _punchAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Container(
                     width: 300,
                     height: 300,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.white.withOpacity(0.1), width: 16),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 80)
                       ]
                     ),
                   ),
                   // Corner accents
                   Positioned(top: 16, left: 16, child: _buildCorner(top: true, left: true)),
                   Positioned(top: 16, right: 16, child: _buildCorner(top: true, left: false)),
                   Positioned(bottom: 16, left: 16, child: _buildCorner(top: false, left: true)),
                   Positioned(bottom: 16, right: 16, child: _buildCorner(top: false, left: false)),
                ],
              ),
            ),
          ),
          
          // Metadata Preview Note
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Center(
              child: Text(DateFormat('MMM dd, yyyy').format(DateTime.now()).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
            )
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                     border: Border.all(color: Colors.white54, width: 2),
                     borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.white54)
                ),
                
                // Capture Button
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12, width: 4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                         decoration: const BoxDecoration(
                           color: AppTheme.primary,
                           shape: BoxShape.circle,
                         ),
                      ),
                    ),
                  ),
                ),
                
                // Flip camera
                IconButton(
                  onPressed: _flipCamera,
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                )
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
           top: top ? const BorderSide(color: Colors.white60, width: 2) : BorderSide.none,
           bottom: !top ? const BorderSide(color: Colors.white60, width: 2) : BorderSide.none,
           left: left ? const BorderSide(color: Colors.white60, width: 2) : BorderSide.none,
           right: !left ? const BorderSide(color: Colors.white60, width: 2) : BorderSide.none,
        )
      ),
    );
  }
}
