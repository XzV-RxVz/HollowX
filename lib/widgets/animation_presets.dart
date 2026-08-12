import 'package:flutter/material.dart';

/// AnimationPresets provides centralized animation configurations for consistent
/// animations throughout the application.
///
/// This class defines:
/// - Standard animation durations (fast, normal, slow)
/// - Easing curves for natural motion
/// - Page transition builders for navigation
class AnimationPresets {
  // Durations
  /// Fast animation duration: 200ms
  /// Used for quick feedback and micro-interactions
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal animation duration: 300ms
  /// Used for standard transitions and animations
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animation duration: 400ms
  /// Used for emphasis and dramatic effects
  static const Duration slow = Duration(milliseconds: 400);

  // Curves
  /// Standard ease-in-out curve for smooth acceleration and deceleration
  static const Curve easeInOut = Curves.easeInOut;

  /// Ease-out curve for natural deceleration
  static const Curve easeOut = Curves.easeOut;

  /// Elastic-out curve for bouncy, playful animations
  static const Curve elasticOut = Curves.elasticOut;

  /// Bounce-out curve for spring-like effects
  static const Curve bounceOut = Curves.bounceOut;

  // Page Transitions
  /// Creates a slide transition from right to left
  ///
  /// The page slides in from the right edge with an ease-out curve.
  /// Duration: normal (300ms)
  ///
  /// Example:
  /// ```dart
  /// Navigator.of(context).push(
  ///   AnimationPresets.slideTransition(MyPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> slideTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: easeOut)),
        );
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Creates a fade transition
  ///
  /// The page fades in smoothly.
  /// Duration: fast (200ms)
  ///
  /// Example:
  /// ```dart
  /// Navigator.of(context).push(
  ///   AnimationPresets.fadeTransition(MyPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
