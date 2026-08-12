import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool borderGlow;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.borderGlow = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color ?? GlassTheme.glassBlack,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderGlow ? GlassTheme.neonBorder : GlassTheme.glassBorder,
              boxShadow: borderGlow
                  ? [
                      BoxShadow(
                        color: GlassTheme.neonGreen.withOpacity(0.1),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
