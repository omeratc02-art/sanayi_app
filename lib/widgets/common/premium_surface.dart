import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared elevated, tappable card shell used by every card-like element on
/// the home page (category tiles, mechanic cards, the emergency banner).
/// Centralizing this means every card gets the same soft two-layer shadow
/// and the same hover/press "lift" animation for free, instead of each
/// widget re-implementing (and subtly diverging from) the same
/// AnimatedScale + AnimatedContainer + Material + InkWell boilerplate.
class PremiumSurface extends StatefulWidget {
  const PremiumSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = AppRadius.xl,
    this.color,
    this.gradient,
    this.liftScale = 1.02,
    this.restShadow,
    this.liftedShadow,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double borderRadius;

  /// Flat background color. Ignored if [gradient] is set.
  final Color? color;
  final Gradient? gradient;

  /// Optional hairline border — for cards that need extra definition against
  /// a near-white page background where shadow alone reads too subtly.
  final BoxBorder? border;

  /// How much the card grows on hover/press. Smaller for wide, full-width
  /// cards (a big scale reads as exaggerated on those); larger is fine for
  /// small square tiles.
  final double liftScale;

  /// Defaults to [AppShadows.card] / [AppShadows.cardLifted]. Override with
  /// [AppShadows.coloredCard]/[coloredCardLifted] for a card that should
  /// cast colored light (e.g. the red emergency card) instead of neutral gray.
  final List<BoxShadow>? restShadow;
  final List<BoxShadow>? liftedShadow;

  static const _restScale = 1.0;
  static const _animationDuration = Duration(milliseconds: 160);

  @override
  State<PremiumSurface> createState() => _PremiumSurfaceState();
}

class _PremiumSurfaceState extends State<PremiumSurface> {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _isElevated => _isPressed || _isHovered;

  void _setPressed(bool value) => setState(() => _isPressed = value);
  void _setHovered(bool value) => setState(() => _isHovered = value);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedScale(
        scale: _isElevated ? widget.liftScale : PremiumSurface._restScale,
        duration: PremiumSurface._animationDuration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: PremiumSurface._animationDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.gradient == null ? (widget.color ?? AppColors.surface) : null,
            gradient: widget.gradient,
            borderRadius: radius,
            border: widget.border,
            boxShadow: _isElevated
                ? (widget.liftedShadow ?? AppShadows.cardLifted)
                : (widget.restShadow ?? AppShadows.card),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              onHover: _setHovered,
              splashColor: AppColors.primary.withValues(alpha: 0.08),
              highlightColor: AppColors.primary.withValues(alpha: 0.05),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
