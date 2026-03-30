import 'package:flutter/material.dart';

class StampClipper extends CustomClipper<Path> {
  final double radius;
  final double gap;

  StampClipper({this.radius = 8.0, this.gap = 4.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    
    // Total diameter of a punch
    double d = radius * 2;
    // Spacing between start of one punch and start of next
    double spacing = d + gap;

    // Calculate how many full punches we can fit
    int xCount = (size.width / spacing).floor();
    int yCount = (size.height / spacing).floor();

    // Calculate remainder padding to center punches
    double xRem = size.width - (xCount * spacing) + gap;
    double yRem = size.height - (yCount * spacing) + gap;
    double xPadding = xRem / 2;
    double yPadding = yRem / 2;

    path.moveTo(0, 0);

    // Top edge (moving left to right)
    path.lineTo(xPadding, 0);
    for (int i = 0; i < xCount; i++) {
      double startX = xPadding + i * spacing;
      path.lineTo(startX, 0);
      path.arcToPoint(
        Offset(startX + d, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      );
    }
    path.lineTo(size.width, 0);

    // Right edge (moving top to bottom)
    path.lineTo(size.width, yPadding);
    for (int i = 0; i < yCount; i++) {
      double startY = yPadding + i * spacing;
      path.lineTo(size.width, startY);
      path.arcToPoint(
        Offset(size.width, startY + d),
        radius: Radius.circular(radius),
        clockwise: false,
      );
    }
    path.lineTo(size.width, size.height);

    // Bottom edge (moving right to left)
    path.lineTo(size.width - xPadding, size.height);
    for (int i = xCount - 1; i >= 0; i--) {
      double startX = xPadding + i * spacing;
      path.lineTo(startX + d, size.height);
      path.arcToPoint(
        Offset(startX, size.height),
        radius: Radius.circular(radius),
        clockwise: false,
      );
    }
    path.lineTo(0, size.height);

    // Left edge (moving bottom to top)
    path.lineTo(0, size.height - yPadding);
    for (int i = yCount - 1; i >= 0; i--) {
      double startY = yPadding + i * spacing;
      path.lineTo(0, startY + d);
      path.arcToPoint(
        Offset(0, startY),
        radius: Radius.circular(radius),
        clockwise: false,
      );
    }
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
