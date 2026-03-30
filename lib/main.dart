import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'theme.dart';
import 'models/stamp.dart';
import 'services/storage_service.dart';
import 'screens/camera_view.dart';
import 'screens/library_view.dart';
import 'screens/detail_view.dart';

void main() {
  runApp(const StampApp());
}

class StampApp extends StatelessWidget {
  const StampApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stamp Puncher App',
      theme: AppTheme.lightTheme,
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  _MainNavigatorState createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  bool _hasPermissions = false;
  final StorageService _storageService = StorageService();

  // Used for details view pushing over the current context via internal state
  Stamp? _selectedStamp;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    if (statuses[Permission.camera]!.isGranted && statuses[Permission.location]!.isGranted) {
      if (mounted) setState(() => _hasPermissions = true);
    } else {
      // Permission denied loop or show error UI
      print("Permissions not granted");
    }
  }

  void _onPhotoTaken() {
    setState(() {
      _currentIndex = 1; // Switch to archive automatically after punching? Or stay on camera. Let's stay on camera, just update list. Actually let's just stay on camera.
    });
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory punched!')));
  }

  void _onStampSelected(Stamp stamp) {
    setState(() {
      _selectedStamp = stamp;
      _currentIndex = 2; // Switch to detail tab
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Icon(Icons.security, size: 64, color: AppTheme.primary),
               const SizedBox(height: 24),
               const Text("Permissions Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               const Text("We need camera and location to\ncreate your memory stamps.", textAlign: TextAlign.center),
               const SizedBox(height: 32),
               ElevatedButton(
                 onPressed: _checkPermissions, 
                 child: const Text("Grant Permissions")
               )
             ],
           )
        )
      );
    }

    Widget currentBody;
    switch (_currentIndex) {
      case 0:
        currentBody = CameraView(storageService: _storageService, onPhotoTaken: _onPhotoTaken);
        break;
      case 1:
        currentBody = LibraryView(storageService: _storageService, onStampSelected: _onStampSelected);
        break;
      case 2:
      default:
        currentBody = DetailView(
          stamp: _selectedStamp,
          onBack: () {
            setState(() {
              _currentIndex = 1; // Go back to library
            });
          }
        );
        break;
    }

    return Scaffold(
      body: currentBody,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (index != 2) _selectedStamp = null; // Clear detail when navigating away
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.primary.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Inter'),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, fontFamily: 'Inter'),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.camera),
                activeIcon: Icon(Icons.camera, fill: 1.0),
                label: 'Puncher'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                activeIcon: Icon(Icons.grid_view, fill: 1.0),
                label: 'Archive'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info_outline),
                activeIcon: Icon(Icons.info, fill: 1.0),
                label: 'Details'
              ),
            ],
          ),
        ),
      ),
    );
  }
}
