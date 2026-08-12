import 'package:flutter/material.dart';
import 'glass_theme_v2.dart';
import 'micro_interaction_mixin.dart';

/// Button variant types for GlassButtonV2
enum ButtonVariant {
  /// Primary button with gradient and glow effect
  primary,
  
  /// Secondary button with outline style
  secondary,
  
  /// Text button with minimal styling
  text,
  
  /// Icon-only button variant
  icon,
}

/// Enhanced glass morphism button with multiple variants, loading states,
/// and micro-interactions.
///
/// Features:
/// - Multiple variants (primary, secondary, text, icon)
/// - Loading state with spinner animation
/// - Disabled state styling
/// - Press animations via MicroInteractionMixin
/// - Gradient backgrounds and glow effects
///
/// Example:
/// ```dart
/// GlassButtonV2(
///   label: 'Submit',
///   icon: Icons.check,
///   variant: ButtonVariant.primary,
///   onPressed: () => print('Pressed'),
///   isLoading: false,
/// )
/// ```
class GlassButtonV2 extends StatefulWidget {
  /// Callback when button is pressed. If null, button is disabled.
  final VoidCallback? onPressed;
  
  /// Button label text. Required for primary, secondary, and text variants.
  final String? label;
  
  /// Icon to display. Required for icon variant, optional for others.
  final IconData? icon;
  
  /// Whether button is in loading state
  final bool isLoading;
  
  /// Button variant style
  final ButtonVariant variant;
  
  /// Button width. If null, uses intrinsic width.
  final double? width;
  
  /// Button height
  final double height;

  const GlassButtonV2({
    Key? key,
    required this.onPressed,
    this.label,
    this.icon,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 55,
  }) : super(key: key);

  @override
  State<GlassButtonV2> createState() => _GlassButtonV2State();
}

class _GlassButtonV2State extends State<GlassButtonV2>
    with TickerProviderStateMixin, MicroInteractionMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    initializeMicroInteractions();
    
    // Initialize spinner animation for loading state
    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isLoading) {
      _spinnerController.repeat();
    }
  }

  @override
  void didUpdateWidget(GlassButtonV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update spinner animation based on loading state
    if (widget.isLoading && !oldWidget.isLoading) {
      _spinnerController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _spinnerController.stop();
    }
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    disposeMicroInteractions();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return buildWithMicroInteractions(
      enabled: _isEnabled,
      onTap: widget.onPressed,
      showRipple: true,
      highlightColor: _getHighlightColor(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.text:
        return _buildTextButton();
      case ButtonVariant.icon:
        return _buildIconButton();
    }
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: _isEnabled
            ? GlassThemeV2.primaryGradient
            : const LinearGradient(
                colors: [Color(0x33FFFFFF), Color(0x22FFFFFF)],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled
              ? GlassThemeV2.neonCyan.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: _isEnabled
            ? [GlassThemeV2.glowCyan, GlassThemeV2.elevation2]
            : [GlassThemeV2.elevation1],
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: GlassThemeV2.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled
              ? GlassThemeV2.neonCyan.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [GlassThemeV2.elevation1],
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton() {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildButtonContent(),
    );
  }

  Widget _buildIconButton() {
    return Container(
      width: widget.height,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.variant == ButtonVariant.icon
            ? GlassThemeV2.surface2
            : null,
        borderRadius: BorderRadius.circular(16),
        border: widget.variant == ButtonVariant.icon
            ? Border.all(
                color: _isEnabled
                    ? GlassThemeV2.neonCyan.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              )
            : null,
      ),
      child: Center(
        child: widget.isLoading
            ? _buildSpinner()
            : Icon(
                widget.icon ?? Icons.add,
                color: _isEnabled ? Colors.white : Colors.white38,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Center(
      child: widget.isLoading
          ? _buildSpinner()
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null && widget.variant != ButtonVariant.icon)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      widget.icon,
                      color: _getTextColor(),
                      size: 20,
                    ),
                  ),
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: 24,
      height: 24,
      child: RotationTransition(
        turns: _spinnerController,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getSpinnerColor(),
          ),
        ),
      ),
    );
  }

  Color _getTextColor() {
    if (!_isEnabled) {
      return Colors.white38;
    }
    
    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return GlassThemeV2.neonCyan;
      case ButtonVariant.text:
        return GlassThemeV2.neonCyan;
      case ButtonVariant.icon:
        return Colors.white;
    }
  }

  Color _getSpinnerColor() {
    if (!_isEnabled) {
      return Colors.white38;
    }
    
    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.text:
        return GlassThemeV2.neonCyan;
      case ButtonVariant.icon:
        return Colors.white;
    }
  }

  Color _getHighlightColor() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return GlassThemeV2.neonCyan;
      case ButtonVariant.secondary:
      case ButtonVariant.text:
        return GlassThemeV2.neonCyan;
      case ButtonVariant.icon:
        return Colors.white;
    }
  }
}
