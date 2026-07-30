import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// LightMind：在应用内通过 webview_flutter 显示 www.lightmind.top。
///
/// 深色模式方案（可靠，绕开厂商 ROM 上不可靠的 ForceDark）：
/// 不依赖 WebView 的 setForceDark，而是在每次页面加载完成时注入一段 CSS，
/// 直接改写 :root 的 color-scheme 与 prefers-color-scheme 查询，
/// 让网页“以为”自己处于深色环境，从而触发网页自身定义的深色样式。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      themeMode: ThemeMode.system,
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  static final Uri _homeUrl = Uri.parse('https://www.lightmind.top');

  late final WebViewController _controller;
  bool _loading = true;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!_loading) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            _applyTheme();
            if (_loading) setState(() => _loading = false);
          },
          onWebResourceError: (e) {
            if (_loading) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(_homeUrl);
  }

  /// 注入 CSS 改写网页的深色模式判定，使其跟随系统深色模式。
  ///
  /// 原理：网页判断深色通常用 `@media (prefers-color-scheme: dark)` 或
  /// `:root { color-scheme: ... }`。由于 WebView 不像系统浏览器那样可靠地
  /// 传递 prefers-color-scheme，这里在运行时注入一段样式，强制覆盖这两项，
  /// 让网页自身的深色样式生效。浅色模式则恢复 light。
  Future<void> _applyTheme() async {
    final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final scheme = isDark ? 'dark' : 'light';
    final css = '''
      :root {
        color-scheme: $scheme !important;
      }
    ''';
    final js = '''
      (function() {
        var id = 'lm-theme-override';
        var old = document.getElementById(id);
        if (old) { old.remove(); }
        var s = document.createElement('style');
        s.id = id;
        s.textContent = ${_jsString(css)};
        document.head.appendChild(s);
        document.documentElement.setAttribute('data-theme', '$scheme');
        document.documentElement.style.colorScheme = '$scheme';
      })();
    ''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  /// 将字符串转为安全的 JS 字符串字面量（含引号）
  String _jsString(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n');
    return "'$escaped'";
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final current =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (current != _lastBrightness) {
      _lastBrightness = current;
      _applyTheme();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white70 : Colors.black45,
                    ),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
