import 'package:flutter/material.dart';

class DoseCheckMark extends StatelessWidget {
  const DoseCheckMark({
    super.key,
    this.size = 32,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'DoseCheck',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _DoseCheckMarkPainter(
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _DoseCheckMarkPainter extends CustomPainter {
  const _DoseCheckMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        stroke,
        stroke,
        size.width - (stroke * 2),
        size.height - (stroke * 2),
      ),
      Radius.circular(size.width * 0.31),
    );

    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawRRect(outer, outline);

    final divider = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = stroke * 0.72
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.38),
      Offset(size.width * 0.70, size.height * 0.38),
      divider,
    );

    final check = Path()
      ..moveTo(size.width * 0.31, size.height * 0.62)
      ..lineTo(size.width * 0.45, size.height * 0.74)
      ..lineTo(size.width * 0.72, size.height * 0.49);

    final checkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _DoseCheckMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
