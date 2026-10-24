import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResizableSplitView extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final Axis axis;
  final double defaultRatio;
  final double minFirstSize;
  final double minSecondSize;
  final String? storageKey;
  final double dividerThickness;

  const ResizableSplitView({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.axis = Axis.horizontal,
    this.defaultRatio = 0.35,
    this.minFirstSize = 180.0,
    this.minSecondSize = 240.0,
    this.storageKey,
    this.dividerThickness = 1.0,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _ratio;
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.defaultRatio;
    _loadSavedRatio();
  }

  Future<void> _loadSavedRatio() async {
    if (widget.storageKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('split_${widget.storageKey}');
      if (saved != null && saved > 0.05 && saved < 0.95 && mounted) {
        setState(() {
          _ratio = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRatio(double ratio) async {
    if (widget.storageKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('split_${widget.storageKey}', ratio);
    } catch (_) {}
  }

  void _resetToDefault() {
    setState(() {
      _ratio = widget.defaultRatio;
    });
    _saveRatio(widget.defaultRatio);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHorizontal = widget.axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = isHorizontal
            ? constraints.maxWidth
            : constraints.maxHeight;

        // If constraints are unconstrained or very small, just return flex
        if (totalSize.isInfinite || totalSize <= 0) {
          return isHorizontal
              ? Row(
                  children: [
                    Expanded(child: widget.firstChild),
                    Expanded(child: widget.secondChild),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: widget.firstChild),
                    Expanded(child: widget.secondChild),
                  ],
                );
        }

        // Clamp ratio to obey minFirstSize and minSecondSize
        final double minRatio = totalSize > 0
            ? (widget.minFirstSize / totalSize).clamp(0.05, 0.45)
            : 0.1;
        final double maxRatio = totalSize > 0
            ? (1.0 - (widget.minSecondSize / totalSize)).clamp(0.55, 0.95)
            : 0.9;

        final effectiveMin = math.min(minRatio, maxRatio);
        final effectiveMax = math.max(minRatio, maxRatio);
        final clampedRatio = _ratio.clamp(effectiveMin, effectiveMax);

        final firstSize = totalSize * clampedRatio;

        final divider = MouseRegion(
          cursor: isHorizontal
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _resetToDefault,
            onHorizontalDragStart: isHorizontal
                ? (_) => setState(() => _isDragging = true)
                : null,
            onHorizontalDragEnd: isHorizontal
                ? (_) {
                    setState(() => _isDragging = false);
                    _saveRatio(_ratio);
                  }
                : null,
            onHorizontalDragUpdate: isHorizontal
                ? (details) {
                    final delta = details.delta.dx;
                    final newRatio = (_ratio + (delta / totalSize)).clamp(
                      effectiveMin,
                      effectiveMax,
                    );
                    setState(() {
                      _ratio = newRatio;
                    });
                  }
                : null,
            onVerticalDragStart: !isHorizontal
                ? (_) => setState(() => _isDragging = true)
                : null,
            onVerticalDragEnd: !isHorizontal
                ? (_) {
                    setState(() => _isDragging = false);
                    _saveRatio(_ratio);
                  }
                : null,
            onVerticalDragUpdate: !isHorizontal
                ? (details) {
                    final delta = details.delta.dy;
                    final newRatio = (_ratio + (delta / totalSize)).clamp(
                      effectiveMin,
                      effectiveMax,
                    );
                    setState(() {
                      _ratio = newRatio;
                    });
                  }
                : null,
            child: SizedBox(
              width: isHorizontal ? 8.0 : double.infinity,
              height: isHorizontal ? double.infinity : 8.0,
              child: Center(
                child: Container(
                  width: isHorizontal
                      ? (_isDragging
                            ? 2.5
                            : (_isHovered ? 2.0 : widget.dividerThickness))
                      : double.infinity,
                  height: isHorizontal
                      ? double.infinity
                      : (_isDragging
                            ? 2.5
                            : (_isHovered ? 2.0 : widget.dividerThickness)),
                  decoration: BoxDecoration(
                    color: (_isDragging || _isHovered)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );

        if (isHorizontal) {
          return Row(
            children: [
              SizedBox(width: firstSize, child: widget.firstChild),
              divider,
              Expanded(child: widget.secondChild),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(height: firstSize, child: widget.firstChild),
              divider,
              Expanded(child: widget.secondChild),
            ],
          );
        }
      },
    );
  }
}
