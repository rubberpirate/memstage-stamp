import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/stamp.dart';
import '../theme.dart';
import '../widgets/stamp_clipper.dart';

class DetailView extends StatelessWidget {
  final Stamp? stamp;
  final VoidCallback onBack;

  const DetailView({Key? key, this.stamp, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stamp == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Details"),
        ),
        body: const Center(
          child: Text("No stamp selected. Go to Archive to select one."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: onBack,
        ),
        title: const Text('Stamp Detail', style: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.bold, color: AppTheme.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Floating Stamp Visualization
            Center(
              child: Hero(
                tag: 'stamp_\${stamp!.id}',
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
                    ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipPath(
                      clipper: StampClipper(radius: 6, gap: 4),
                      child: Image.file(
                        File(stamp!.filePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Metadata Section
            Align(
               alignment: Alignment.centerLeft,
               child: Text('ARCHIVE ENTRY', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            Align(
               alignment: Alignment.centerLeft,
               child: Text('Stamp No. \${stamp!.id.substring(stamp!.id.length - 4)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Work Sans', color: AppTheme.onSurface)),
            ),
            const SizedBox(height: 24),

            // Info Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.onSurfaceVariant.withOpacity(0.1))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFd1e6eb)),
                              child: const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text('Location', style: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant))
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(stamp!.locationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Work Sans')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.onSurfaceVariant.withOpacity(0.1))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFd1e6eb)),
                              child: const Icon(Icons.event, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text('Date & Time', style: TextStyle(fontFamily: 'Work Sans', fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant))
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(DateFormat('MMM dd, yyyy').format(stamp!.dateTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Work Sans', height: 1.1)),
                        Text(DateFormat('HH:mm').format(stamp!.dateTime), style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        )
      )
    );
  }
}
