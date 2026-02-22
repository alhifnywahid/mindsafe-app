import 'package:flutter/material.dart';

class AppSpacing {
  // Base spacing unit
  static const double unit = 8.0;

  // Spacing values
  static const double xs = unit * 0.5; // 4
  static const double sm = unit; // 8
  static const double md = unit * 2; // 16
  static const double lg = unit * 3; // 24
  static const double xl = unit * 4; // 32
  static const double xxl = unit * 6; // 48

  // Padding
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal/Vertical padding
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingV = EdgeInsets.symmetric(vertical: md);

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Card settings
  static const double cardRadius = radiusLg;
  static const double cardElevation = 2.0;
}
