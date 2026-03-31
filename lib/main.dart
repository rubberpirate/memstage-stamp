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
      title: 'Memotage',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Memory punched!'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
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
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
            if (index != 2) _selectedStamp = null; // Clear detail when navigating away
          });
        },
        selectedIndex: _currentIndex,
        indicatorColor: AppTheme.surfaceContainerHighest,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Image.asset('assets/logo.png', width: 24, height: 24),
            icon: Image.asset('assets/logo.png', width: 24, height: 24),
            label: 'Capture',
          ),
          const NavigationDestination(
            selectedIcon: Icon(Icons.grid_view),
            icon: Icon(Icons.grid_view_outlined),
            label: 'Archive',
          ),
          const NavigationDestination(
            selectedIcon: Icon(Icons.info),
            icon: Icon(Icons.info_outline),
            label: 'Details',
          ),
        ],
      ),
    );
  }
}
