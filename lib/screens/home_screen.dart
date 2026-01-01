import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'pdf_viewer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // 请求存储权限
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      
      // Android 13+ 需要额外权限
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  Future<void> _openPdfFile(BuildContext context) async {
    try {
      // 再次检查权限
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('需要存储权限才能打开文件'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        // 检查文件是否存在
        final file = File(path);
        if (!file.existsSync()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('文件不存在'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // 检查文件大小
        final fileSize = file.lengthSync();
        if (fileSize == 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('文件为空'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        if (context.mounted) {
          _navigateToPdfViewer(context, path);
        }
      }
    } catch (e) {
      debugPrint('打开文件错误: $e');
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
              // 顶部区域
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PDF阅读器',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '版本 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
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
                                    const SizedBox(height: 8),
                                    Text(
                                      '点击上方按钮选择PDF文件',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
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
                                final file = File(filePath);
                                final fileExists = file.existsSync();
                                final fileSize = fileExists ? file.lengthSync() : 0;
                                
                                return Dismissible(
                                  key: Key(filePath),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  onDismissed: (_) {
                                    appState.removeFromRecent(filePath);
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: fileExists 
                                              ? const Color(0xFF1B5E20).withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          color: fileExists 
                                              ? const Color(0xFF1B5E20) 
                                              : Colors.grey,
                                          size: 28,
                                        ),
                                      ),
                                      title: Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: fileExists ? null : Colors.grey,
                                        ),
                                      ),
                                      subtitle: Text(
                                        fileExists 
                                            ? _formatFileSize(fileSize)
                                            : '文件不存在',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: fileExists ? Colors.grey[600] : Colors.red[300],
                                        ),
                                      ),
                                      trailing: fileExists
                                          ? const Icon(Icons.chevron_right)
                                          : IconButton(
                                              icon: const Icon(Icons.close, size: 20),
                                              onPressed: () {
                                                appState.removeFromRecent(filePath);
                                              },
                                            ),
                                      onTap: fileExists
                                          ? () => _navigateToPdfViewer(context, filePath)
                                          : null,
                                    ),
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
