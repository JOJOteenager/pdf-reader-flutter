import 'package:flutter/material.dart';
import 'drawing_canvas.dart';

/// 注释工具栏
class AnnotationToolbar extends StatelessWidget {
  final StrokeType currentType;
  final Color currentColor;
  final double currentWidth;
  final Function(StrokeType) onTypeChanged;
  final Function(Color) onColorChanged;
  final Function(double) onWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool canUndo;

  const AnnotationToolbar({
    super.key,
    required this.currentType,
    required this.currentColor,
    required this.currentWidth,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onUndo,
    required this.onClear,
    this.canUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 笔类型选择
          _buildToolButton(
            icon: Icons.edit,
            tooltip: '钢笔',
            isSelected: currentType == StrokeType.pen,
            onTap: () => onTypeChanged(StrokeType.pen),
          ),
          _buildToolButton(
            icon: Icons.highlight,
            tooltip: '荧光笔',
            isSelected: currentType == StrokeType.highlighter,
            onTap: () => onTypeChanged(StrokeType.highlighter),
          ),
          _buildToolButton(
            icon: Icons.create,
            tooltip: '铅笔',
            isSelected: currentType == StrokeType.pencil,
            onTap: () => onTypeChanged(StrokeType.pencil),
          ),
          _buildToolButton(
            icon: Icons.auto_fix_high,
            tooltip: '橡皮擦',
            isSelected: currentType == StrokeType.eraser,
            onTap: () => onTypeChanged(StrokeType.eraser),
          ),
          
          const VerticalDivider(width: 16),
          
          // 颜色选择
          _buildColorButton(Colors.black),
          _buildColorButton(Colors.red),
          _buildColorButton(Colors.blue),
          _buildColorButton(Colors.green),
          _buildColorButton(Colors.orange),
          
          const VerticalDivider(width: 16),
          
          // 粗细调节
          SizedBox(
            width: 100,
            child: Slider(
              value: currentWidth,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onWidthChanged,
            ),
          ),
          
          const Spacer(),
          
          // 撤销
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed: canUndo ? onUndo : null,
          ),
          
          // 清除
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除全部',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF1B5E20).withOpacity(0.2) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = currentColor == color;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
