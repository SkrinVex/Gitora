import 'package:flutter/material.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_commit.dart';

class CommitGraphPainter extends CustomPainter {
  final List<GitCommit> commits;
  final int selectedIndex;
  final double itemHeight;
  final double laneWidth;

  CommitGraphPainter({
    required this.commits,
    this.selectedIndex = -1,
    this.itemHeight = 56.0,
    this.laneWidth = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (commits.isEmpty) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..style = PaintingStyle.fill;
    final nodeBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // First pass: Draw connections between consecutive commits and parent lanes
    for (int i = 0; i < commits.length; i++) {
      final commit = commits[i];
      final currentY = (i + 0.5) * itemHeight;
      final currentX = (commit.lane + 1) * laneWidth;
      final color = _getLaneColor(commit.lane);
      linePaint.color = color;

      // Connect to parents
      for (final parentHash in commit.parentHashes) {
        // Find parent index in the current list
        final parentIndex = commits.indexWhere((c) => c.hash == parentHash);
        if (parentIndex != -1) {
          final parent = commits[parentIndex];
          final parentY = (parentIndex + 0.5) * itemHeight;
          final parentX = (parent.lane + 1) * laneWidth;

          if (commit.lane == parent.lane) {
            // Straight vertical line
            canvas.drawLine(
              Offset(currentX, currentY),
              Offset(parentX, parentY),
              linePaint,
            );
          } else {
            // Smooth cubic bezier curve connecting lanes
            final path = Path();
            path.moveTo(currentX, currentY);
            final midY = (currentY + parentY) / 2;
            path.cubicTo(currentX, midY, parentX, midY, parentX, parentY);
            canvas.drawPath(path, linePaint);
          }
        } else {
          // Parent is beyond the current visible list; draw line continuing down
          canvas.drawLine(
            Offset(currentX, currentY),
            Offset(currentX, currentY + itemHeight * 0.8),
            linePaint,
          );
        }
      }
    }

    // Second pass: Draw commit nodes on top of lines
    for (int i = 0; i < commits.length; i++) {
      final commit = commits[i];
      final centerY = (i + 0.5) * itemHeight;
      final centerX = (commit.lane + 1) * laneWidth;
      final color = _getLaneColor(commit.lane);
      final isSelected = i == selectedIndex;
      final isHead = i == 0;

      nodePaint.color = color;
      nodeBorderPaint.color = Colors.white;

      final radius = isSelected ? 6.5 : (commit.isMerge ? 5.5 : 4.5);

      if (isHead) {
        // Outer glowing ring for HEAD
        final headGlowPaint = Paint()
          ..color = color.withAlpha(80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;
        canvas.drawCircle(
          Offset(centerX, centerY),
          radius + 4.5,
          headGlowPaint,
        );
      }

      // Draw node circle
      canvas.drawCircle(Offset(centerX, centerY), radius, nodePaint);
      canvas.drawCircle(Offset(centerX, centerY), radius, nodeBorderPaint);

      // If merge commit, draw small inner circle
      if (commit.isMerge) {
        final innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(centerX, centerY), 2.0, innerPaint);
      }
    }
  }

  Color _getLaneColor(int lane) {
    final palette = AppColors.graphLaneColors;
    return palette[lane % palette.length];
  }

  @override
  bool shouldRepaint(covariant CommitGraphPainter oldDelegate) {
    return oldDelegate.commits != commits ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.itemHeight != itemHeight;
  }
}
