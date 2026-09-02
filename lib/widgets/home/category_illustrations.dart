import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Flat illustrations for 3 of the homepage's 4 category cards — Ekspertiz,
/// Sigorta, and the Acil Yardım emergency card. Araç Tamiri deliberately
/// keeps its original Material icon + wrench-overlay badge (see
/// ServiceCategoryCard's own call site in home_tab.dart) rather than a
/// custom illustration — approved and reverted during design review.
///
/// Every shape here is either solid white, a very light white-tinted
/// gradient, a low-opacity black stroke/fill, or (Acil Yardım's
/// exclamation mark only) [AppColors.emergency] — so nothing introduces a
/// color outside the card's own background plus the existing palette.
/// Drawn as CustomPainters against a fixed 96x96 design grid (matching the
/// approved illustration-proposal artifact) rather than bundled SVG assets,
/// since 3 flat shapes don't warrant a new asset pipeline / svg-rendering
/// dependency — [Canvas]/[Path] already draw the exact same primitives.
class EkspertizIllustration extends StatelessWidget {
  const EkspertizIllustration({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _EkspertizPainter());
  }
}

class _EkspertizPainter extends CustomPainter {
  static final _outline = Paint()
    ..color = Colors.black.withValues(alpha: 0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 96);

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 79), width: 40, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    // Clipboard body — subtle gradient for shading, not flat white.
    final clipboardRect = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 18, 44, 56), const Radius.circular(8));
    canvas.drawRRect(
      clipboardRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE9EEF4)],
        ).createShader(const Rect.fromLTWH(14, 18, 44, 56)),
    );
    canvas.drawRRect(clipboardRect, _outline);

    // Clip tab.
    final tabRect = RRect.fromRectAndRadius(const Rect.fromLTWH(27, 13, 18, 10), const Radius.circular(4));
    canvas.drawRRect(tabRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      tabRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    _checklistRow(canvas, top: 30, barWidth: 19);
    _checklistRow(canvas, top: 44, barWidth: 15);

    // Magnifier lens — gradient fill + highlight arc for a "glass" read.
    const lensCenter = Offset(68, 60);
    canvas.drawCircle(
      lensCenter,
      18,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE3EDFA)],
        ).createShader(Rect.fromCircle(center: lensCenter, radius: 18)),
    );
    canvas.drawCircle(
      lensCenter,
      18,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final highlight = Path()
      ..moveTo(60, 52)
      ..arcToPoint(const Offset(68, 48), radius: const Radius.circular(11));
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Handle.
    canvas.drawLine(
      const Offset(80.5, 72.5),
      const Offset(88, 80),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.5,
    );
    canvas.drawLine(
      const Offset(80.5, 72.5),
      const Offset(88, 80),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );

    // Checkmark inside the lens.
    final check = Path()
      ..moveTo(60, 60)
      ..lineTo(66, 66)
      ..lineTo(77, 51);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // One checklist row: a filled checkbox chip with a white checkmark, plus
  // a text-line bar beside it — real checkmarks, not just gray bars.
  void _checklistRow(Canvas canvas, {required double top, required double barWidth}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(21, top, 9, 9), const Radius.circular(3)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    final check = Path()
      ..moveTo(23.3, top + 4.3)
      ..lineTo(25.6, top + 6.6)
      ..lineTo(29.3, top + 1.5);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(33, top + 2, barWidth, 5), const Radius.circular(2.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Classic shield silhouette with a checkmark — Sigorta.
class SigortaIllustration extends StatelessWidget {
  const SigortaIllustration({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _SigortaPainter());
  }
}

class _SigortaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 96);

    final shield = Path()
      ..moveTo(48, 16)
      ..lineTo(74, 25)
      ..lineTo(74, 48)
      ..quadraticBezierTo(74, 68, 48, 82)
      ..quadraticBezierTo(22, 68, 22, 48)
      ..lineTo(22, 25)
      ..close();
    canvas.drawPath(shield, Paint()..color = Colors.white);
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    final check = Path()
      ..moveTo(36, 49)
      ..lineTo(45, 58)
      ..lineTo(62, 38);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hazard triangle with an exclamation mark — Acil Yardım. The one
/// deliberate exception to the white-only rule: the exclamation mark
/// knocks out to [AppColors.emergency] (the card's own red), since a real
/// warning triangle reads as red.
class AcilYardimIllustration extends StatelessWidget {
  const AcilYardimIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _AcilYardimPainter());
  }
}

class _AcilYardimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 96, size.height / 96);

    final triangle = Path()
      ..moveTo(48, 16)
      ..lineTo(86, 78)
      ..quadraticBezierTo(88, 82, 84, 82)
      ..lineTo(12, 82)
      ..quadraticBezierTo(8, 82, 10, 78)
      ..close();
    canvas.drawPath(triangle, Paint()..color = Colors.white);
    canvas.drawPath(
      triangle,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(44.5, 38, 7, 23), const Radius.circular(3.5)),
      Paint()..color = AppColors.emergency,
    );
    canvas.drawCircle(const Offset(48, 70), 4.4, Paint()..color = AppColors.emergency);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
