import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// LightMind：在应用内通过 webview_flutter 显示 www.lightmind.top。
///
/// 设计要点：
/// - 预留系统状态栏与底部手势导航条区域，不让网页全屏；
///   预留区域使用网页 CSS 变量 `--surface-muted` 的背景色（运行时通过
///   JS 通道回传，加载前用系统主题对应的默认色）。
/// - 网页加载完成前，屏幕中央显示小鸡破壳动画图。
/// - 不显示加载进度条。
/// - 设置自定义 User-Agent，附带 `LightMindApp/<version>` 标识。
/// - 深色模式跟随系统：通过注入 CSS 改写 :root 的 color-scheme，
///   绕过厂商 ROM 上不可靠的 setForceDark。
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
  static const String _homeUrlString = 'https://www.lightmind.top';
  static const String _appVersion = '1.2.1';

  /// 状态栏 / 底部手势栏预留区域的背景色。
  /// 加载完成后由网页 `--surface-muted` 回传；加载前按系统主题给默认色。
  Color? _surfaceColor;
  bool _loading = true;
  Brightness? _lastBrightness;

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    final ua = _buildUserAgent();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ua)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'SurfaceColorChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          final parsed = _parseColor(msg.message.trim());
          if (parsed != null) {
            setState(() => _surfaceColor = parsed);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!_loading) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            _applyTheme();
            if (_loading) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (_loading) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_homeUrlString));
  }

  /// 构造 User-Agent：在默认 Android WebView UA 后追加应用标识。
  String _buildUserAgent() {
    // 通用现代 Android WebView UA，末尾追加 LightMindApp 版本标识，
    // 便于网页端识别本应用并做相应适配。
    const base =
        'Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';
    return '$base LightMindApp/$_appVersion';
  }

  /// 注入 CSS 改写网页的深色模式判定，并回传 `--surface-muted` 颜色。
  Future<void> _applyTheme() async {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final scheme = isDark ? 'dark' : 'light';
    final css = '''
      :root {
        color-scheme: $scheme !important;
      }
    ''';
    final js = '''
      (function() {
        try {
          var id = 'lm-theme-override';
          var old = document.getElementById(id);
          if (old) { old.remove(); }
          var s = document.createElement('style');
          s.id = id;
          s.textContent = ${_jsString(css)};
          document.head.appendChild(s);
          document.documentElement.setAttribute('data-theme', '$scheme');
          document.documentElement.style.colorScheme = '$scheme';

          var sm = getComputedStyle(document.documentElement)
                      .getPropertyValue('--surface-muted').trim();
          if (sm) { window.SurfaceColorChannel.postMessage(sm); }
        } catch (e) {}
      })();
    ''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  /// 将字符串转为安全的 JS 字符串字面量（含引号）。
  String _jsString(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n');
    return "'$escaped'";
  }

  /// 解析网页回传的颜色字符串（支持 #rgb / #rrggbb / #rrggbbaa / rgb() / rgba()）。
  Color? _parseColor(String raw) {
    if (raw.isEmpty) return null;
    final s = raw.trim().toLowerCase();
    if (s.startsWith('#')) {
      var hex = s.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      } else if (hex.length == 4) {
        hex = hex.split('').map((c) => c + c).join();
      }
      if (hex.length == 6) {
        final v = int.tryParse(hex, radix: 16);
        if (v != null) return Color(0xFF000000 | v);
      } else if (hex.length == 8) {
        final v = int.tryParse(hex, radix: 16);
        if (v != null) return Color(v);
      }
      return null;
    }
    final m = RegExp(r'rgba?\(([^)]+)\)').firstMatch(s);
    if (m != null) {
      final parts = m.group(1)!.split(',').map((e) => e.trim()).toList();
      final r = int.tryParse(parts[0]);
      final g = parts.length > 1 ? int.tryParse(parts[1]) : null;
      final b = parts.length > 2 ? int.tryParse(parts[2]) : null;
      if (r != null && g != null && b != null) {
        return Color.fromARGB(255, r, g, b);
      }
    }
    return null;
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

  /// 当前预留区域背景色：优先用网页回传的 surface-muted，否则按系统主题取默认。
  Color _effectiveSurfaceColor(BuildContext context) {
    if (_surfaceColor != null) return _surfaceColor!;
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final surface = _effectiveSurfaceColor(context);
    // 状态栏图标颜色与背景明暗对应
    final overlay = _useLightOverlay(surface)
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: surface,
        systemNavigationBarColor: surface,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: surface,
          body: SafeArea(
            // 预留顶部状态栏与底部手势导航条区域
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  Container(
                    color: surface,
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/hatching_chick.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 判断给定背景色是否偏暗，决定状态栏图标用亮色还是暗色。
  bool _useLightOverlay(Color c) {
    return c.computeLuminance() < 0.5;
  }
}
