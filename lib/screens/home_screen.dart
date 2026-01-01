import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'pdf_viewer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openPdfFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (context.mounted) {
          _navigateToPdfViewer(context, path);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPdfViewer(BuildContext context, String path) {
    context.read<AppState>().setCurrentPdf(path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: path),
      ),
    );
  }

  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF阅读器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部区域 - Logo和标题
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PDF阅读器',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '专为华为平板优化',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 功能列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: const [
                    _FeatureChip(icon: Icons.picture_as_pdf, text: 'PDF阅读'),
                    _FeatureChip(icon: Icons.edit, text: '注释'),
                    _FeatureChip(icon: Icons.zoom_in, text: '缩放'),
                    _FeatureChip(icon: Icons.bookmark, text: '书签'),
                    _FeatureChip(icon: Icons.search, text: '搜索'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 打开文件按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdfFile(context),
                    icon: const Icon(Icons.folder_open, size: 24),
                    label: const Text(
                      '打开PDF文件',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 最近文件列表
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '最近打开',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            Consumer<AppState>(
                              builder: (context, appState, _) {
                                if (appState.recentFiles.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return TextButton(
                                  onPressed: () => _showClearDialog(context),
                                  child: const Text('清空'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Consumer<AppState>(
                          builder: (context, appState, _) {
                            if (appState.recentFiles.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无最近打开的文件',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: appState.recentFiles.length,
                              itemBuilder: (context, index) {
                                final filePath = appState.recentFiles[index];
                                final fileName = _getFileName(filePath);
                                final fileExists = File(filePath).existsSync();
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.picture_as_pdf,
                                      color: fileExists 
                                          ? const Color(0xFF1B5E20) 
                                          : Colors.grey,
                                      size: 40,
                                    ),
                                    title: Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: fileExists ? null : Colors.grey,
                                      ),
                                    ),
                                    subtitle: Text(
                                      fileExists ? filePath : '文件不存在',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: fileExists ? Colors.grey[600] : Colors.red[300],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        appState.removeFromRecent(filePath);
                                      },
                                    ),
                                    onTap: fileExists
                                        ? () => _navigateToPdfViewer(context, filePath)
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空记录'),
        content: const Text('确定要清空所有最近打开的文件记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().clearRecentFiles();
              Navigator.pop(context);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
