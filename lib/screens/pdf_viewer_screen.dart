import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _nightMode = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  void _checkFile() {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      setState(() {
        _isLoading = false;
        _errorMessage = '文件不存在';
      });
    }
  }

  @override
  void dispose() {
    // 保存当前页码
    if (_totalPages > 0) {
      context.read<AppState>().setLastPage(widget.filePath, _currentPage);
    }
    super.dispose();
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: '${_currentPage + 1}');
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
      _pdfController?.setPage(page - 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入有效页码 (1-$_totalPages)')),
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pdfController?.setPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pdfController?.setPage(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    
    return Scaffold(
      backgroundColor: _nightMode ? Colors.black : Colors.grey[200],
      appBar: _showControls ? AppBar(
        title: Text(
          fileName,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 夜间模式
          IconButton(
            icon: Icon(_nightMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: _nightMode ? '日间模式' : '夜间模式',
            onPressed: () {
              setState(() {
                _nightMode = !_nightMode;
              });
            },
          ),
          // 更多选项
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
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
          if (_errorMessage != null)
            _buildErrorWidget()
          else
            GestureDetector(
              onTap: () {
                if (!_showControls) {
                  setState(() {
                    _showControls = true;
                  });
                }
              },
              child: PDFView(
                filePath: widget.filePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitPolicy: FitPolicy.BOTH,
                nightMode: _nightMode,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isReady = true;
                    _isLoading = false;
                  });
                  
                  // 恢复上次阅读位置
                  final lastPage = context.read<AppState>().getLastPage(widget.filePath);
                  if (lastPage != null && lastPage > 0 && lastPage < _totalPages) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _pdfController?.setPage(lastPage);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已恢复到第 ${lastPage + 1} 页'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  }
                },
                onError: (error) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = error.toString();
                  });
                },
                onPageError: (page, error) {
                  debugPrint('页面 $page 加载错误: $error');
                },
                onViewCreated: (controller) {
                  _pdfController = controller;
                },
                onPageChanged: (page, total) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? 0;
                  });
                },
              ),
            ),
          
          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1B5E20)),
                    SizedBox(height: 16),
                    Text('正在加载文档...'),
                  ],
                ),
              ),
            ),
          
          // 页码显示和导航
          if (_isReady && _showControls)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 上一页
                  FloatingActionButton.small(
                    heroTag: 'prev',
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    backgroundColor: _currentPage > 0 
                        ? const Color(0xFF1B5E20) 
                        : Colors.grey,
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  // 页码
                  GestureDetector(
                    onTap: _showPageJumpDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 下一页
                  FloatingActionButton.small(
                    heroTag: 'next',
                    onPressed: _currentPage < _totalPages - 1 ? _goToNextPage : null,
                    backgroundColor: _currentPage < _totalPages - 1 
                        ? const Color(0xFF1B5E20) 
                        : Colors.grey,
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // 退出全屏按钮
          if (!_showControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag: 'exit_fullscreen',
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
