import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isAnnotationMode = false;
  double _zoomLevel = 1.0;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到页面'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '输入页码 (1-$_totalPages)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
              }
              Navigator.pop(context);
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 缩放
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
                _pdfController.zoomLevel = _zoomLevel;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
                _pdfController.zoomLevel = _zoomLevel;
              });
            },
          ),
          // 注释模式
          IconButton(
            icon: Icon(
              _isAnnotationMode ? Icons.edit_off : Icons.edit,
              color: _isAnnotationMode ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isAnnotationMode = !_isAnnotationMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isAnnotationMode ? '注释模式已开启' : '注释模式已关闭',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // 书签
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.filePath),
            key: _pdfViewerKey,
            controller: _pdfController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
          ),
          // 页码显示
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _showPageJumpDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 更多功能菜单
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildBottomMenu(),
          );
        },
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('搜索'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 搜索功能
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('翻译'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 翻译功能
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('繁简转换'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 繁简转换
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('分享'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 分享功能
            },
          ),
        ],
      ),
    );
  }
}
