import 'package:flutter/material.dart';

/// 放大镜组件
class MagnifierWidget extends StatefulWidget {
  final Widget child;
  final double magnification;
  final double size;
  final bool enabled;

  const MagnifierWidget({
    super.key,
    required this.child,
    this.magnification = 2.0,
    this.size = 150,
    this.enabled = false,
  });

  @override
  State<MagnifierWidget> createState() => _MagnifierWidgetState();
}

class _MagnifierWidgetState extends State<MagnifierWidget> {
  Offset? _position;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 原始内容
        widget.child,
        
        // 放大镜
        if (widget.enabled && _position != null)
          Positioned(
            left: _position!.dx - widget.size / 2,
            top: _position!.dy - widget.size - 20,
            child: _buildMagnifier(),
          ),
        
        // 手势检测层
        if (widget.enabled)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                  _position = details.localPosition;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _position = details.localPosition;
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  Widget _buildMagnifier() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1B5E20),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: widget.magnification,
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(
                -(_position!.dx - widget.size / 2 / widget.magnification),
                -(_position!.dy - widget.size / 2 / widget.magnification),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 简单的放大镜覆盖层
class SimpleMagnifier extends StatelessWidget {
  final Offset position;
  final double size;
  final double magnification;

  const SimpleMagnifier({
    super.key,
    required this.position,
    this.size = 120,
    this.magnification = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size - 30,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF1B5E20),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.zoom_in,
            size: 40,
            color: Color(0xFF1B5E20),
          ),
        ),
      ),
    );
  }
}
