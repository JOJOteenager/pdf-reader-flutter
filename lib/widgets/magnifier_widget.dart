import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:screenshot/screenshot.dart';
import '../services/ocr_service.dart';
import 'text_action_dialog.dart';

/// 带 OCR 功能的放大镜组件
class MagnifierWidget extends StatefulWidget {
  final Widget child;
  final double magnification;
  final double size;
  final bool enabled;
  final GlobalKey? captureKey;

  const MagnifierWidget({
    super.key,
    required this.child,
    this.magnification = 2.0,
    this.size = 150,
    this.enabled = false,
    this.captureKey,
  });

  @override
  State<MagnifierWidget> createState() => _MagnifierWidgetState();
}

class _MagnifierWidgetState extends State<MagnifierWidget> {
  Offset? _position;
  bool _isDragging = false;
  bool _isRecognizing = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 原始内容（用于截图）
        RepaintBoundary(
          key: _contentKey,
          child: widget.child,
        ),
        
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
                // 松手时触发 OCR
                _performOcr();
              },
              onTapUp: (details) {
                setState(() {
                  _position = details.localPosition;
                });
                _performOcr();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        
        // OCR 识别中提示
        if (_isRecognizing)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1B5E20)),
                        SizedBox(height: 16),
                        Text('正在识别文字...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMagnifier() {
    return GestureDetector(
      onTap: _performOcr,
      child: Container(
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
          child: Stack(
            children: [
              Transform.scale(
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
              // OCR 按钮提示
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '松手识别',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performOcr() async {
    if (_position == null || _isRecognizing) return;

    setState(() => _isRecognizing = true);

    try {
      // 截取放大镜区域的图片
      final captureSize = widget.size * 1.5;
      final captureRect = Rect.fromCenter(
        center: _position!,
        width: captureSize,
        height: captureSize,
      );

      // 使用 RepaintBoundary 截图
      final boundary = _contentKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final result = await OcrService.recognizeFromBytes(
            bytes,
            image.width,
            image.height,
          );

          if (mounted) {
            setState(() => _isRecognizing = false);
            
            if (result.success && result.text.isNotEmpty) {
              _showTextActionDialog(result.text);
            } else {
              _showErrorSnackBar(result.errorMessage ?? '未识别到文字');
            }
          }
        } else {
          if (mounted) {
            setState(() => _isRecognizing = false);
            _showErrorSnackBar('截图失败');
          }
        }
      } else {
        if (mounted) {
          setState(() => _isRecognizing = false);
          _showErrorSnackBar('无法获取内容');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecognizing = false);
        _showErrorSnackBar('识别出错: $e');
      }
    }
  }

  void _showTextActionDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => TextActionDialog(text: text),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 简单的放大镜覆盖层（不带 OCR）
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
