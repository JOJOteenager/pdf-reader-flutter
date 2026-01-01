import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// 笔画数据
class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final StrokeType type;

  Stroke({
    required this.points,
    this.color = Colors.black,
    this.width = 2.0,
    this.type = StrokeType.pen,
  });

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    StrokeType? type,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      type: type ?? this.type,
    );
  }
}

enum StrokeType {
  pen,        // 钢笔
  highlighter, // 荧光笔
  pencil,     // 铅笔
  eraser,     // 橡皮擦
}

/// 绘图画布
class DrawingCanvas extends StatefulWidget {
  final List<Stroke> strokes;
  final Function(List<Stroke>) onStrokesChanged;
  final Color currentColor;
  final double currentWidth;
  final StrokeType currentType;
  final bool enabled;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokesChanged,
    this.currentColor = Colors.black,
    this.currentWidth = 2.0,
    this.currentType = StrokeType.pen,
    this.enabled = true,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Stroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.enabled ? _onPanStart : null,
      onPanUpdate: widget.enabled ? _onPanUpdate : null,
      onPanEnd: widget.enabled ? _onPanEnd : null,
      child: CustomPaint(
        painter: _DrawingPainter(
          strokes: widget.strokes,
          currentStroke: _currentStroke,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final point = details.localPosition;
    
    if (widget.currentType == StrokeType.eraser) {
      _eraseAt(point);
    } else {
      _currentStroke = Stroke(
        points: [point],
        color: widget.currentColor,
        width: widget.currentWidth,
        type: widget.currentType,
      );
      setState(() {});
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = details.localPosition;
    
    if (widget.currentType == StrokeType.eraser) {
      _eraseAt(point);
    } else if (_currentStroke != null) {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && widget.currentType != StrokeType.eraser) {
      final newStrokes = [...widget.strokes, _currentStroke!];
      widget.onStrokesChanged(newStrokes);
      _currentStroke = null;
      setState(() {});
    }
  }

  void _eraseAt(Offset point) {
    const eraseRadius = 20.0;
    final newStrokes = widget.strokes.where((stroke) {
      for (final p in stroke.points) {
        if ((p - point).distance < eraseRadius) {
          return false;
        }
      }
      return true;
    }).toList();
    
    if (newStrokes.length != widget.strokes.length) {
      widget.onStrokesChanged(newStrokes);
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  _DrawingPainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (stroke.type) {
      case StrokeType.pen:
        paint.color = stroke.color;
        paint.strokeWidth = stroke.width;
        break;
      case StrokeType.highlighter:
        paint.color = stroke.color.withOpacity(0.4);
        paint.strokeWidth = stroke.width * 3;
        break;
      case StrokeType.pencil:
        paint.color = stroke.color.withOpacity(0.7);
        paint.strokeWidth = stroke.width * 0.8;
        break;
      case StrokeType.eraser:
        return; // 橡皮擦不绘制
    }

    if (stroke.points.length == 1) {
      // 单点绘制为圆点
      final fillPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(stroke.points.first, stroke.width / 2, fillPaint);
      return;
    }

    // 使用二次贝塞尔曲线平滑绘制
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    
    if (stroke.points.length == 2) {
      // 两点直接连线
      path.lineTo(stroke.points[1].dx, stroke.points[1].dy);
    } else {
      // 使用二次贝塞尔曲线平滑连接
      for (int i = 1; i < stroke.points.length - 1; i++) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }
      // 连接到最后一个点
      final lastPoint = stroke.points.last;
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    // 优化重绘判断：只在笔画数量或当前笔画变化时重绘
    if (oldDelegate.strokes.length != strokes.length) return true;
    if (oldDelegate.currentStroke != currentStroke) return true;
    // 检查当前笔画的点数是否变化
    if (currentStroke != null && oldDelegate.currentStroke != null) {
      return currentStroke!.points.length != oldDelegate.currentStroke!.points.length;
    }
    return false;
  }
}
