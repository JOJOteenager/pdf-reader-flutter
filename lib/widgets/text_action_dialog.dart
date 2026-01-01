import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chinese_converter_service.dart';
import '../services/translation_service.dart';

/// 文本操作对话框
class TextActionDialog extends StatefulWidget {
  final String text;

  const TextActionDialog({super.key, required this.text});

  @override
  State<TextActionDialog> createState() => _TextActionDialogState();
}

class _TextActionDialogState extends State<TextActionDialog> {
  String _resultText = '';
  bool _isLoading = false;
  String _currentAction = '';
  int _translationRequestId = 0;

  @override
  void initState() {
    super.initState();
    _resultText = widget.text;
  }
  
  @override
  void dispose() {
    // 取消待处理的翻译请求
    _translationRequestId++;
    super.dispose();
  }

  Future<void> _translate() async {
    final currentRequestId = ++_translationRequestId;
    setState(() {
      _isLoading = true;
      _currentAction = '翻译中...';
    });

    final result = await TranslationService.englishToChinese(widget.text);
    
    // 检查是否是最新的请求
    if (!mounted || currentRequestId != _translationRequestId) return;
    
    setState(() {
      _isLoading = false;
      if (result.success) {
        _resultText = result.translatedText;
        _currentAction = '英译中';
      } else {
        _resultText = result.errorMessage ?? '翻译失败';
        _currentAction = '错误';
      }
    });
  }

  void _toTraditional() {
    setState(() {
      _resultText = ChineseConverterService.toTraditional(widget.text);
      _currentAction = '简→繁';
    });
  }

  void _toSimplified() {
    setState(() {
      _resultText = ChineseConverterService.toSimplified(widget.text);
      _currentAction = '繁→简';
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.text_fields, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                const Text(
                  '文本操作',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // 原文
            const Text(
              '原文:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.translate,
                  label: '翻译',
                  onTap: _translate,
                ),
                _buildActionButton(
                  icon: Icons.text_rotation_none,
                  label: '简→繁',
                  onTap: _toTraditional,
                ),
                _buildActionButton(
                  icon: Icons.text_rotation_angledown,
                  label: '繁→简',
                  onTap: _toSimplified,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 结果
            if (_currentAction.isNotEmpty) ...[
              Text(
                '结果 ($_currentAction):',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              _resultText,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _copyToClipboard,
                            tooltip: '复制',
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1B5E20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示文本操作对话框
void showTextActionDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (context) => TextActionDialog(text: text),
  );
}
