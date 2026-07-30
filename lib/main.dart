import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

/// LightMind 启动器：使用 Chrome Custom Tabs 打开 www.lightmind.top。
///
/// 采用系统浏览器（Custom Tabs）渲染网页，而非 WebView。
/// 系统浏览器原生遵循 prefers-color-scheme，深色模式下网页会自动切换深色主题。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 透明状态栏，让启动界面背景延伸到系统栏，颜色跟随系统深色模式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const LightMindApp());
}

class LightMindApp extends StatelessWidget {
  const LightMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      // 跟随系统深色模式
      themeMode: ThemeMode.system,
      home: const LauncherPage(),
    );
  }
}

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> {
  static final Uri _homeUrl = Uri.parse('https://www.lightmind.top');

  bool _launching = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 界面首帧绘制后立即打开页面
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPage());
  }

  Future<void> _openPage() async {
    setState(() {
      _launching = true;
      _error = null;
    });
    try {
      // colorScheme: system —— Custom Tab 工具栏与网页渲染均跟随系统深色模式，
      // 网页的 prefers-color-scheme 由系统浏览器原生支持，深色模式自动生效。
      await launchUrl(
        _homeUrl,
        prefersDeepLink: false,
        customTabsOptions: const CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes(
            colorScheme: CustomTabsColorScheme.system,
          ),
          urlBarHidingEnabled: false,
          showTitle: true,
          instantAppsEnabled: false,
        ),
      );
    } on PlatformException {
      _error = '未找到可用的浏览器';
    } catch (_) {
      _error = '打开页面失败';
    } finally {
      if (mounted) {
        setState(() => _launching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        color: isDark ? Colors.black : Colors.white,
        alignment: Alignment.center,
        child: _launching
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '正在打开 LightMind…',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error ?? '已关闭',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _openPage,
                    child: const Text('重新打开'),
                  ),
                ],
              ),
      ),
    );
  }
}
