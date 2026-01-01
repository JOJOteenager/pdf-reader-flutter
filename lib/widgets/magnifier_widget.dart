import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/ocr_service.dart';
import '../services/chinese_converter_service.dart';
import '../services/translation_service.dart';

class MagnifierWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onClose;

  const MagnifierWidget({
    super.key,
    required this.child,
    this.enabled = false,
    this.onClose,
  });

  @override
  State<MagnifierWidget> createState() => _MagnifierWidgetState();
}

class _MagnifierWidgetState extends State<MagnifierWidget> {
  Offset? _startPosition;
  Offset? _currentPosition;
  bool _isProcessing = false;
  bool _showResult = false;
  final GlobalKey _contentKey = GlobalKey();
  String _originalText = '';
  String _convertedText = '';
  String _currentMode = '繁→简';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(key: _contentKey, child: widget.child),
        if (widget.enabled && !_showResult)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (d) => setState(() { _startPosition = d.localPosition; _currentPosition = d.localPosition; }),
              onPanUpdate: (d) => setState(() => _currentPosition = d.localPosition),
              onPanEnd: (d) { if (_startPosition != null && _currentPosition != null) { final r = Rect.fromPoints(_startPosition!, _currentPosition!); if (r.width > 20 && r.height > 20) _captureAndRecognize(); } },
              child: Container(color: Colors.transparent),
            ),
          ),
        if (widget.enabled && _startPosition != null && _currentPosition != null && !_showResult)
          Positioned(
            left: Rect.fromPoints(_startPosition!, _currentPosition!).left,
            top: Rect.fromPoints(_startPosition!, _currentPosition!).top,
            width: Rect.fromPoints(_startPosition!, _currentPosition!).width,
            height: Rect.fromPoints(_startPosition!, _currentPosition!).height,
            child: Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1B5E20), width: 2), color: const Color(0xFF1B5E20).withOpacity(0.1))),
          ),
        if (_showResult) _buildResultPanel(),
        if (_isProcessing) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildResultPanel() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                _buildModeChip('繁→简', Icons.text_rotation_angledown),
                const SizedBox(width: 8),
                _buildModeChip('简→繁', Icons.text_rotation_none),
                const SizedBox(width: 8),
                _buildModeChip('英→中', Icons.translate),
              ]),
            ),
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFFFFBF0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8DCC8))),
                  child: SelectableText(_convertedText.isEmpty ? '正在识别...' : _convertedText, style: const TextStyle(fontSize: 20, height: 1.9, color: Color(0xFF2D2D2D), letterSpacing: 1.0)),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(children: [Icon(Icons.article_outlined, size: 16, color: Colors.grey[500]), const SizedBox(width: 6), Text('查看原文', style: TextStyle(fontSize: 13, color: Colors.grey[500]))]),
                    tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)), child: SelectableText(_originalText, style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[600])))],
                  ),
                ),
              ]),
            )),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(children: [
                Expanded(child: _buildActionBtn(Icons.refresh, '重选', _resetSelection)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn(Icons.copy, '复制', _copyResult, primary: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildActionBtn(Icons.close, '关闭', _closePanel)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () { setState(() => _currentMode = mode); _applyConversion(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[300]!)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(mode, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap, {bool primary = false}) {
    return Material(
      color: primary ? const Color(0xFF1B5E20) : Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: primary ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: primary ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black38,
        child: Center(child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Color(0xFF1B5E20), strokeWidth: 3), SizedBox(height: 20), Text('正在识别文字...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))])),
        )),
      ),
    );
  }

  Future<void> _captureAndRecognize() async {
    setState(() => _isProcessing = true);
    try {
      final boundary = _contentKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) { _showError('无法获取内容'); return; }
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { _showError('截图失败'); return; }
      final bytes = byteData.buffer.asUint8List();
      final result = await OcrService.recognizeFromBytes(bytes, 0, 0);
      if (!mounted) return;
      if (result.success && result.text.isNotEmpty) {
        setState(() { _originalText = result.text; _isProcessing = false; _showResult = true; });
        _applyConversion();
      } else { _showError(result.errorMessage ?? '未识别到文字'); }
    } catch (e) { _showError('识别出错: $e'); }
  }

  Future<void> _applyConversion() async {
    if (_originalText.isEmpty) return;
    switch (_currentMode) {
      case '繁→简': setState(() => _convertedText = ChineseConverterService.toSimplified(_originalText)); break;
      case '简→繁': setState(() => _convertedText = ChineseConverterService.toTraditional(_originalText)); break;
      case '英→中':
        setState(() => _convertedText = '翻译中...');
        final result = await TranslationService.englishToChinese(_originalText);
        if (mounted) setState(() => _convertedText = result.success ? result.translatedText : '翻译失败');
        break;
    }
  }

  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _convertedText));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Color(0xFF1B5E20), duration: Duration(seconds: 1)));
  }

  void _resetSelection() { setState(() { _startPosition = null; _currentPosition = null; _showResult = false; _originalText = ''; _convertedText = ''; }); }
  void _closePanel() { _resetSelection(); widget.onClose?.call(); }
  void _showError(String msg) { if (mounted) { setState(() => _isProcessing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red[700])); } }
}
