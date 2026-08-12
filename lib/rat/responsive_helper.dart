import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class untuk responsive design
/// Mendeteksi ukuran layar dan memberikan layout yang sesuai
class ResponsiveHelper {
  /// Cek apakah device adalah mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Cek apakah device adalah tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1200;
  }

  /// Cek apakah device adalah desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Cek apakah device adalah web
  static bool isWeb(BuildContext context) {
    return kIsWeb;
  }

  /// Cek apakah device adalah mobile web
  static bool isMobileWeb(BuildContext context) {
    return isWeb(context) && isMobile(context);
  }

  /// Cek apakah device adalah desktop web
  static bool isDesktopWeb(BuildContext context) {
    return isWeb(context) && isDesktop(context);
  }

  /// Mendapatkan padding yang sesuai untuk layout
  static EdgeInsets getPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// Mendapatkan container width yang sesuai untuk desktop
  static double? getContainerWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200;
    } else if (isTablet(context)) {
      return 800;
    }
    return null;
  }

  /// Mendapatkan spacing yang sesuai
  static double getSpacing(BuildContext context, {double level = 1}) {
    if (isDesktop(context)) {
      return 24 * level;
    } else if (isTablet(context)) {
      return 16 * level;
    } else {
      return 12 * level;
    }
  }

  /// Mendapatkan font size yang sesuai
  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) {
      return baseSize * 1.1;
    } else if (isTablet(context)) {
      return baseSize * 1.0;
    } else {
      return baseSize * 0.9;
    }
  }

  /// Mendapatkan grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 2;
    }
  }

  /// Widget wrapper untuk responsive layout
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return builder(context, isMobile, isTablet, isDesktop);
  }
}

/// Responsive wrapper widget
class ResponsiveWrapper extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWrapper({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (isMobile && mobile != null) return mobile!;
    if (isTablet && tablet != null) return tablet!;
    if (isDesktop && desktop != null) return desktop!;

    return builder(context, isMobile, isTablet, isDesktop);
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final EdgeInsetsGeometry? mobile;
  final EdgeInsetsGeometry? tablet;
  final EdgeInsetsGeometry? desktop;
  final Widget child;

  const ResponsivePadding({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    EdgeInsetsGeometry padding;
    if (isMobile && mobile != null) {
      padding = mobile!;
    } else if (isTablet && tablet != null) {
      padding = tablet!;
    } else if (isDesktop && desktop != null) {
      padding = desktop!;
    } else {
      padding = ResponsiveHelper.getPadding(context);
    }

    return Padding(padding: padding, child: child);
  }
}

/// Responsive container width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final containerWidth = maxWidth ?? ResponsiveHelper.getContainerWidth(context);

    return Center(
      child: Container(
        width: isDesktop ? containerWidth : double.infinity,
        padding: padding ?? ResponsiveHelper.getPadding(context),
        child: child,
      ),
    );
  }
}
