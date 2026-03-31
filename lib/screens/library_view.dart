import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/stamp.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/stamp_clipper.dart';

class LibraryView extends StatefulWidget {
  final StorageService storageService;
  final Function(Stamp) onStampSelected;

  const LibraryView({Key? key, required this.storageService, required this.onStampSelected}) : super(key: key);

  @override
  _LibraryViewState createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  List<Stamp> _stamps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStamps();
  }

  Future<void> _loadStamps() async {
    final stamps = await widget.storageService.loadStamps();
    if (mounted) {
      setState(() {
        _stamps = stamps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 24, width: 24),
            const SizedBox(width: 8),
            const Text('Memotage Library', style: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.primary),
            onPressed: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('User Profile'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle, size: 64, color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('rubberpirate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                ],
              ));
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _loadStamps,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding for bottom nav
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COLLECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('My Memotages', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Work Sans', color: AppTheme.onSurface)),
                      Text('${_stamps.length} Artifacts', style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2)
                    ),
                  ),

                  // Grid View
                  _stamps.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No memotages collected yet. Go capture some memories!", style: TextStyle(color: AppTheme.onSurfaceVariant))))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _stamps.length,
                        itemBuilder: (context, index) {
                          final stamp = _stamps[index];
                          return GestureDetector(
                            onTap: () => widget.onStampSelected(stamp),
                            child: Hero(
                              tag: 'stamp_\${stamp.id}',
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2)
                                    )
                                  ]
                                ),
                                child: ClipPath(
                                  clipper: StampClipper(radius: 4, gap: 2), // Smaller cuts for grid
                                  child: Image.file(
                                    File(stamp.filePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  
                  if (_stamps.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: Text("End of collection. Keep collecting.", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13))),
                    )
                ],
              ),
            ),
          )
    );
  }
}
