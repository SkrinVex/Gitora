import 'package:flutter/material.dart';

class GitoraLogo extends StatelessWidget {
  final double size;
  final bool animate;

  const GitoraLogo({super.key, this.size = 36, this.animate = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final tertiary = theme.colorScheme.tertiary;

    return CustomPaint(
      size: Size(size, size),
      painter: _GitoraLogoPainter(primaryColor: primary, accentColor: tertiary),
    );
  }
}

class _GitoraLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _GitoraLogoPainter({required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw main branch trunk (vertical curve)
    final mainBranchPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;

    final secondaryBranchPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    // Trunk line from bottom-left to top-left
    final trunkStart = Offset(w * 0.32, h * 0.82);
    final trunkMid = Offset(w * 0.32, h * 0.45);
    final trunkEnd = Offset(w * 0.32, h * 0.18);

    canvas.drawLine(trunkStart, trunkEnd, mainBranchPaint);

    // Feature branch path splitting from trunk to top-right
    final branchPath = Path();
    branchPath.moveTo(trunkMid.dx, trunkMid.dy);
    branchPath.cubicTo(
      w * 0.32,
      h * 0.28,
      w * 0.68,
      h * 0.52,
      w * 0.68,
      h * 0.32,
    );
    canvas.drawPath(branchPath, secondaryBranchPaint);

    // Nodes (commits)
    final nodeRadius = w * 0.12;

    void drawNode(Offset center, Color fill, Color border) {
      final fillPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045;

      canvas.drawCircle(center, nodeRadius, fillPaint);
      canvas.drawCircle(center, nodeRadius, borderPaint);
    }

    // Node 1: Bottom trunk
    drawNode(trunkStart, primaryColor, Colors.white);
    // Node 2: Trunk fork
    drawNode(trunkMid, primaryColor, Colors.white);
    // Node 3: Top trunk HEAD
    drawNode(trunkEnd, primaryColor, Colors.white);
    // Node 4: Feature branch tip
    drawNode(Offset(w * 0.68, h * 0.32), accentColor, Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GitoraLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
