import 'package:flutter/material.dart';
import 'animation_presets.dart';

/// MicroInteractionMixin provides reusable animation behaviors for interactive widgets.
///
/// This mixin handles:
/// - Scale animation on press
/// - Ripple effect animation
/// - Hover/focus highlight animation
/// - Proper AnimationController lifecycle management
///
/// Usage:
/// ```dart
/// class MyButton extends StatefulWidget {
///   @override
///   _MyButtonState createState() => _MyButtonState();
/// }
///
/// class _MyButtonState extends State<MyButton>
///     with SingleTickerProviderStateMixin, MicroInteractionMixin {
///   @override
///   void initState() {
///     super.initState();
///     initializeMicroInteractions();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return buildWithMicroInteractions(
///       child: YourWidget(),
///       onTap: () { /* your action */ },
///     );
///   }
/// }
/// ```
mixin MicroInteractionMixin<T extends StatefulWidget> on State<T>, TickerProvider {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isHovered = false;
  bool _isFocused = false;

  /// Initialize the micro-interaction animations.
  /// Call this in initState() of your StatefulWidget.
  void initializeMicroInteractions() {
    // Scale animation controller for press feedback
    _scaleController = AnimationController(
      duration: AnimationPresets.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AnimationPresets.easeOut,
    ));

    // Ripple animation controller
    _rippleController = AnimationController(
      duration: AnimationPresets.normal,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: AnimationPresets.easeOut,
    ));
  }

  /// Dispose animation controllers to prevent memory leaks.
  /// Call this in dispose() of your StatefulWidget.
  void disposeMicroInteractions() {
    _scaleController.dispose();
    _rippleController.dispose();
  }

  /// Trigger the press animation (scale down).
  void onPressStart() {
    _scaleController.forward();
    _rippleController.forward(from: 0.0);
  }

  /// Release the press animation (scale back to normal).
  void onPressEnd() {
    _scaleController.reverse();
  }

  /// Set hover state.
  void setHovered(bool hovered) {
    if (mounted) {
      setState(() {
        _isHovered = hovered;
      });
    }
  }

  /// Set focus state.
  void setFocused(bool focused) {
    if (mounted) {
      setState(() {
        _isFocused = focused;
      });
    }
  }

  /// Get the current highlight state (hover or focus).
  bool get isHighlighted => _isHovered || _isFocused;

  /// Build a widget with micro-interactions applied.
  ///
  /// This wraps your child widget with:
  /// - Scale animation on press
  /// - Ripple effect
  /// - Hover/focus highlight
  ///
  /// Parameters:
  /// - [child]: The widget to wrap with micro-interactions
  /// - [onTap]: Callback when the widget is tapped
  /// - [enabled]: Whether interactions are enabled (default: true)
  /// - [showRipple]: Whether to show ripple effect (default: true)
  /// - [highlightColor]: Color for hover/focus highlight
  Widget buildWithMicroInteractions({
    required Widget child,
    VoidCallback? onTap,
    bool enabled = true,
    bool showRipple = true,
    Color? highlightColor,
  }) {
    return MouseRegion(
      onEnter: enabled ? (_) => setHovered(true) : null,
      onExit: enabled ? (_) => setHovered(false) : null,
      child: Focus(
        onFocusChange: enabled ? setFocused : null,
        child: GestureDetector(
          onTapDown: enabled ? (_) => onPressStart() : null,
          onTapUp: enabled ? (_) {
            onPressEnd();
            onTap?.call();
          } : null,
          onTapCancel: enabled ? () => onPressEnd() : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleController, _rippleController]),
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  children: [
                    // Original child
                    child,
                    
                    // Ripple effect overlay
                    if (showRipple && _rippleAnimation.value > 0)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomPaint(
                            painter: _RipplePainter(
                              progress: _rippleAnimation.value,
                              color: (highlightColor ?? Colors.white).withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    
                    // Hover/focus highlight overlay
                    if (isHighlighted)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (highlightColor ?? Colors.white).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for ripple effect.
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * progress;
    
    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
