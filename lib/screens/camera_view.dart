import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../models/stamp.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/stamp_clipper.dart';

Uint8List? cropImageAndEncodeSync(Uint8List imageBytes) {
  try {
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage != null) {
      // Calculate central 1:1 crop matching the stamp viewport
      int size = originalImage.width < originalImage.height ? originalImage.width : originalImage.height;
      int x = (originalImage.width - size) ~/ 2;
      int y = (originalImage.height - size) ~/ 2;
      img.Image cropped = img.copyCrop(originalImage, x: x, y: y, width: size, height: size);
      img.Image resized = img.copyResize(cropped, width: 800, height: 800);
      return img.encodeJpg(resized, quality: 85);
    }
  } catch (e) {
    print("Image crop failed: \$e");
  }
  return null;
}

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
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _punchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
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
    _controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);
    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      print("Error initializing camera: \$e");
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;

    // Play fast punch animation
    await _punchController.forward();

    try {
      final XFile pic = await _controller!.takePicture();
      _punchController.reverse(); // Bounce back instantly
      
      // Trigger the snacbkar right away!
      widget.onPhotoTaken();
      
      // We don't await the complex background tasks, ensuring 0 frozen UI.
      _processAndSavePhoto(pic);
    } catch (e) {
      print("Take photo error (could be flash or permission): \$e");
      _punchController.reverse();
    }
  }

  Future<void> _processAndSavePhoto(XFile pic) async {
    try {
      // Get optional location safely
      String mainLocName = "Unknown Location";
      String subLocName = "";
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position? position = await Geolocator.getLastKnownPosition();
            position ??= await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium
            ).timeout(const Duration(seconds: 5));
            
            subLocName = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
            
            // Try reverse geocoding
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
              if (placemarks.isNotEmpty) {
                Placemark place = placemarks[0];
                mainLocName = "${place.locality ?? place.subLocality ?? place.administrativeArea ?? 'Unknown Area'}";
              }
            } catch (e) {
              debugPrint("Geocoding failed: $e");
            }
          }
        }
      } catch (e) {
        print("Could not get location safely: $e");
      }

      // Process and save cropped 1:1 image
      final directory = await getApplicationDocumentsDirectory();
      final String rawUuid = const Uuid().v4().replaceAll('-', '').toUpperCase();
      final String stampCode = "${rawUuid.substring(0, 4)}-${rawUuid.substring(4, 8)}";

      final String fullPath = '${directory.path}/stamp_$stampCode.jpg';

      Uint8List originalBytes = await pic.readAsBytes();
      Uint8List? croppedBytes = await compute(cropImageAndEncodeSync, originalBytes);

      if (croppedBytes != null) {
        await File(fullPath).writeAsBytes(croppedBytes);
      } else {
        await File(pic.path).copy(fullPath); // fallback
      }

      final stamp = Stamp(
        id: stampCode,
        filePath: fullPath,
        locationName: "$mainLocName|$subLocName", // Packing them into the existing locationName field
        dateTime: DateTime.now(),
      );

      await widget.storageService.saveStamp(stamp);
      
    } catch (e) {
      print(e);
    }
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await _controller!.setFlashMode(_isFlashOn ? FlashMode.always : FlashMode.off);
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
          
          // Vignette / Dimmer with Stamp Hole
          IgnorePointer(
            child: ClipPath(
              clipper: _HoleClipper(),
              child: Container(color: Colors.black87),
            ),
          ),
          
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
                  onPressed: () {
                    SystemNavigator.pop();
                  }, // Close app if needed
                ),
                const Text("Puncher", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Work Sans')),
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                  onPressed: _toggleFlash, // Toggle flash
                )
              ],
            ),
          ),

          // Stamp Cutout Overlay - physical white border
          IgnorePointer(
            child: Center(
              child: ScaleTransition(
                scale: _punchAnimation,
                child: SizedBox(
                   width: 300,
                   height: 300,
                   child: CustomPaint(
                     painter: _StampBorderPainterLocal(),
                   ),
                ),
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
    return Container(); // No longer used, but kept to avoid errors if any refs remain
  }
}

class _HoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    double width = 300;
    double height = 300;
    Path stampPath = StampClipper(radius: 6, gap: 4).getClip(Size(width, height));
    stampPath = stampPath.shift(Offset((size.width - width) / 2, (size.height - height) / 2));
    
    path.addPath(stampPath, Offset.zero);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _StampBorderPainterLocal extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path stampPath = StampClipper(radius: 6, gap: 4).getClip(size);
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(stampPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

