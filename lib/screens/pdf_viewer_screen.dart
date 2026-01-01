import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../providers/app_state.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    
    // 获取默认缩放级别
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      setState(() {
        _zoomLevel = appState.defaultZoom;
      });
    });
  }

  @override
  void dispose() {
    // 保存当前页码
    if (_totalPages > 0) {
      context.read<AppState>().setLastPage(widget.filePath, _currentPage);
    }
    _pdfController.dispose();
    super.dispose();
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到页面'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入页码 (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _jumpToPage(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              _jumpToPage(controller.text);
              Navigator.pop(context);
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入有效页码 (1-$_totalPages)')),
      );
    }
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 4.0);
      _pdfController.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 4.0);
      _pdfController.zoomLevel = _zoomLevel;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _pdfController.zoomLevel = _zoomLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    
    return Scaffold(
      appBar: _showControls ? AppBar(
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 缩放控制
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: '缩小',
            onPressed: _zoomLevel > 0.5 ? _zoomOut : null,
          ),
          GestureDetector(
            onTap: _resetZoom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: '放大',
            onPressed: _zoomLevel < 4.0 ? _zoomIn : null,
          ),
          // 书签
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: '书签',
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
          // 更多选项
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'search':
                  // 搜索功能由 PDF Viewer 内置支持
                  break;
                case 'goto':
                  _showPageJumpDialog();
                  break;
                case 'fullscreen':
                  setState(() {
                    _showControls = false;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'goto',
                child: ListTile(
                  leading: Icon(Icons.find_in_page),
                  title: Text('跳转页面'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'fullscreen',
                child: ListTile(
                  leading: Icon(Icons.fullscreen),
                  title: Text('全屏模式'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          // PDF 查看器
          GestureDetector(
            onTap: () {
              if (!_showControls) {
                setState(() {
                  _showControls = true;
                });
              }
            },
            child: _errorMessage != null
                ? _buildErrorWidget()
                : SfPdfViewer.file(
                    File(widget.filePath),
                    key: _pdfViewerKey,
                    controller: _pdfController,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    canShowPaginationDialog: true,
                    enableDoubleTapZooming: true,
                    enableTextSelection: true,
                    interactionMode: PdfInteractionMode.selection,
                    onDocumentLoaded: (details) {
                      setState(() {
                        _totalPages = details.document.pages.count;
                        _isLoading = false;
                      });
                      
                      // 恢复上次阅读位置
                      final lastPage = context.read<AppState>().getLastPage(widget.filePath);
                      if (lastPage != null && lastPage > 1 && lastPage <= _totalPages) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _pdfController.jumpToPage(lastPage);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已恢复到第 $lastPage 页'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        });
                      }
                    },
                    onDocumentLoadFailed: (details) {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = details.description;
                      });
                    },
                    onPageChanged: (details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onZoomLevelChanged: (details) {
                      setState(() {
                        _zoomLevel = details.newZoomLevel;
                      });
                    },
                  ),
          ),
          
          // 加载指示器
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text('正在加载文档...'),
                ],
              ),
            ),
          
          // 页码显示
          if (!_isLoading && _errorMessage == null && _showControls)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _showPageJumpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // 退出全屏按钮
          if (!_showControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _showControls = true;
                  });
                },
                backgroundColor: Colors.black54,
                child: const Icon(Icons.fullscreen_exit, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              '无法打开文档',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
