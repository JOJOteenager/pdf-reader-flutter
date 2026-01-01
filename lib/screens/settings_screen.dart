import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return ListView(
            children: [
              // 外观设置
              _buildSectionHeader(context, '外观'),
              SwitchListTile(
                title: const Text('深色模式'),
                subtitle: const Text('切换应用的明暗主题'),
                secondary: Icon(
                  appState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF1B5E20),
                ),
                value: appState.isDarkMode,
                onChanged: (_) => appState.toggleDarkMode(),
              ),
              const Divider(),
              
              // 阅读设置
              _buildSectionHeader(context, '阅读'),
              ListTile(
                leading: const Icon(Icons.zoom_in, color: Color(0xFF1B5E20)),
                title: const Text('默认缩放级别'),
                subtitle: Text('${(appState.defaultZoom * 100).toInt()}%'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: appState.defaultZoom,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${(appState.defaultZoom * 100).toInt()}%',
                    onChanged: (value) => appState.setDefaultZoom(value),
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('记住阅读位置'),
                subtitle: const Text('下次打开时自动跳转到上次阅读的页面'),
                secondary: const Icon(Icons.bookmark, color: Color(0xFF1B5E20)),
                value: appState.rememberLastPage,
                onChanged: (value) => appState.setRememberLastPage(value),
              ),
              const Divider(),
              
              // 存储设置
              _buildSectionHeader(context, '存储'),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF1B5E20)),
                title: const Text('最近打开的文件'),
                subtitle: Text('${appState.recentFiles.length} 个文件'),
                trailing: TextButton(
                  onPressed: appState.recentFiles.isEmpty
                      ? null
                      : () => _showClearHistoryDialog(context, appState),
                  child: const Text('清空'),
                ),
              ),
              const Divider(),
              
              // 关于
              _buildSectionHeader(context, '关于'),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF1B5E20)),
                title: const Text('版本'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Color(0xFF1B5E20)),
                title: const Text('开发框架'),
                subtitle: const Text('Flutter'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Color(0xFF1B5E20)),
                title: const Text('优化设备'),
                subtitle: const Text('华为 MatePad 11 (HarmonyOS)'),
              ),
              
              const SizedBox(height: 32),
              
              // 版权信息
              Center(
                child: Text(
                  '© 2024 PDF阅读器',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有最近打开的文件记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              appState.clearRecentFiles();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('历史记录已清空')),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
