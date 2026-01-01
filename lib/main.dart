import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  // 支持横屏和竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const PDFReaderApp());
}

class PDFReaderApp extends StatelessWidget {
  const PDFReaderApp({super.key});

  // 主题色 - 深绿色
  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color primaryColorLight = Color(0xFF2E7D32);
  static const Color primaryColorDark = Color(0xFF0D3D14);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'PDF阅读器',
            debugShowCheckedModeBanner: false,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
                primary: primaryColor,
                secondary: primaryColorLight,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.dark,
                primary: primaryColorLight,
                secondary: primaryColor,
              ),
              useMaterial3: true,
              appBarTheme: AppBarTheme(
                backgroundColor: primaryColorDark,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
