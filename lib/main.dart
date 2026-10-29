import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PainBrowserApp());
}

class PainBrowserApp extends StatelessWidget {
  const PainBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pain Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFBB86FC),
        scaffoldBackgroundColor: const Color(0xFF2D1B4E),
        useMaterial3: true,
      ),
      home: const BrowserHome(),
    );
  }
}

class BrowserTab {
  WebViewController? controller;
  String url;
  String title;
  String label;
  bool pinned;
  bool isLoading;
  double progress;

  BrowserTab({
    this.controller,
    this.url = '',
    this.title = 'Tab moi',
    this.label = '',
    this.pinned = false,
    this.isLoading = false,
    this.progress = 0,
  });

  String get displayTitle =>
      label.trim().isNotEmpty ? label.trim() : (title.isNotEmpty ? title : 'Tab');
}

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final TextEditingController _urlController = TextEditingController();
  final List<BrowserTab> _tabs = [];
  int _currentTabIndex = 0;

  bool _isFullscreen = false;
  bool _isIncognito = false;
  bool _isDesktopUA = false;
  bool _gameMode = false;
  bool _blockImages = false;
  bool _hideBar = false;
  bool _saveHistory = true;
  bool _dataSaver = false;
  bool _enableBackButton = true;
  bool _enableIncognito = true;
  bool _enableJavaScript = true;

  String _searchEngine = 'google';
  String _homeUrl = '';
  String _customUA = '';
  String _gameOrientation = 'auto';
  double _zoom = 1.0;

  List<Map<String, String>> _history = [];
  List<Map<String, String>> _bookmarks = [];
  List<Map<String, dynamic>> _scripts = [];
  List<Map<String, String>> _quickLinks = [
    {'name': 'Google', 'url': 'https://www.google.com'},
    {'name': 'UGPhone', 'url': 'https://www.ugphone.com'},
    {'name': 'Discord', 'url': 'https://discord.com'},
  ];

  static const _bg = Color(0xFF2D1B4E);
  static const _card = Color(0xFF3D2A5C);
  static const _accent = Color(0xFFBB86FC);
  static const _accent2 = Color(0xFF9B59B6);
  static const _border = Color(0xFF5B3F8A);

  final _mobileUA =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  final _desktopUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  BrowserTab get _tab => _tabs[_currentTabIndex];
  String get _activeUA =>
      _customUA.trim().isNotEmpty ? _customUA.trim() : (_isDesktopUA ? _desktopUA : _mobileUA);
  bool get _showChrome => !_isFullscreen && !_gameMode && !_hideBar;

  @override
  void initState() {
    super.initState();
    _tabs.add(BrowserTab(title: 'Trang chu'));
    _loadData();
  }

  @override
  void dispose() {
    _saveData();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _enableBackButton = p.getBool('enableBack') ?? true;
      _enableIncognito = p.getBool('enableIncognito') ?? true;
      _enableJavaScript = p.getBool('enableJS') ?? true;
      _isDesktopUA = p.getBool('desktopUA') ?? false;
      _blockImages = p.getBool('blockImages') ?? false;
      _hideBar = p.getBool('hideBar') ?? false;
      _saveHistory = p.getBool('saveHistory') ?? true;
      _dataSaver = p.getBool('dataSaver') ?? false;
      _searchEngine = p.getString('searchEngine') ?? 'google';
      _homeUrl = p.getString('homeUrl') ?? '';
      _customUA = p.getString('customUA') ?? '';
      _gameOrientation = p.getString('gameOrientation') ?? 'auto';
      _zoom = p.getDouble('zoom') ?? 1.0;

      final h = p.getString('history');
      if (h != null) {
        _history = (jsonDecode(h) as List).map((e) => Map<String, String>.from(e)).toList();
      }
      final b = p.getString('bookmarks');
      if (b != null) {
        _bookmarks = (jsonDecode(b) as List).map((e) => Map<String, String>.from(e)).toList();
      }
      final s = p.getString('scripts');
      if (s != null) {
        _scripts = (jsonDecode(s) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final ql = p.getString('quickLinks');
      if (ql != null) {
        _quickLinks = (jsonDecode(ql) as List).map((e) => Map<String, String>.from(e)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('enableBack', _enableBackButton);
    await p.setBool('enableIncognito', _enableIncognito);
    await p.setBool('enableJS', _enableJavaScript);
    await p.setBool('desktopUA', _isDesktopUA);
    await p.setBool('blockImages', _blockImages);
    await p.setBool('hideBar', _hideBar);
    await p.setBool('saveHistory', _saveHistory);
    await p.setBool('dataSaver', _dataSaver);
    await p.setString('searchEngine', _searchEngine);
    await p.setString('homeUrl', _homeUrl);
    await p.setString('customUA', _customUA);
    await p.setString('gameOrientation', _gameOrientation);
    await p.setDouble('zoom', _zoom);
    await p.setString('history', jsonEncode(_history));
    await p.setString('bookmarks', jsonEncode(_bookmarks));
    await p.setString('scripts', jsonEncode(_scripts));
    await p.setString('quickLinks', jsonEncode(_quickLinks));
  }

  void _initController(BrowserTab tab) {
    tab.controller = WebViewController()
      ..setJavaScriptMode(_enableJavaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setUserAgent(_activeUA)
      ..setBackgroundColor(_bg)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (v) {
          tab.progress = v / 100.0;
          if (_tabs[_currentTabIndex] == tab) setState(() {});
        },
        onPageStarted: (url) {
          tab.isLoading = true;
          tab.url = url;
          if (_tabs[_currentTabIndex] == tab) setState(() => _urlController.text = url);
        },
        onPageFinished: (url) async {
          final title = await tab.controller?.getTitle();
          tab.isLoading = false;
          tab.progress = 1;
          tab.title = title ?? 'Tab';
          tab.url = url;
          if (_tabs[_currentTabIndex] == tab) setState(() => _urlController.text = url);
          setState(() {});
          if (!_isIncognito && _saveHistory && url.isNotEmpty) {
            _addHistory(title ?? url, url);
          }
          if (_blockImages) {
            await tab.controller?.runJavaScript(
              "document.querySelectorAll('img').forEach(i=>i.style.display='none');",
            );
          }
          if (_zoom != 1.0) {
            await tab.controller?.runJavaScript('document.body.style.zoom="$_zoom";');
          }
        },
        onWebResourceError: (_) {
          tab.isLoading = false;
          setState(() {});
        },
        onNavigationRequest: (req) async {
          final u = req.url.toLowerCase();
          if (['.pdf', '.apk', '.zip', '.rar', '.mp3', '.mp4'].any(u.endsWith)) {
            final uri = Uri.tryParse(req.url);
            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
  }

  void _addHistory(String title, String url) {
    _history.removeWhere((e) => e['url'] == url);
    _history.insert(0, {'title': title, 'url': url, 'time': DateTime.now().toIso8601String()});
    if (_history.length > 50) _history = _history.sublist(0, 50);
    _saveData();
  }

  String _searchUrl(String q) {
    final e = Uri.encodeComponent(q);
    if (_searchEngine == 'ddg') return 'https://duckduckgo.com/?q=$e';
    if (_searchEngine == 'bing') return 'https://www.bing.com/search?q=$e';
    return 'https://www.google.com/search?q=$e';
  }

  void _loadUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return;
    if (_tab.controller == null) _initController(_tab);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = (url.contains('.') && !url.contains(' ')) ? 'https://$url' : _searchUrl(url);
    }
    setState(() => _tab.url = url);
    _tab.controller!.loadRequest(Uri.parse(url));
  }

  void _newTab() {
    setState(() {
      _tabs.add(BrowserTab(title: 'Tab moi'));
      _currentTabIndex = _tabs.length - 1;
      _urlController.clear();
    });
  }

  void _closeTab(int i) {
    if (_tabs[i].pinned) return;
    if (_tabs.length == 1) {
      setState(() {
        _tabs[0] = BrowserTab(title: 'Trang chu');
        _currentTabIndex = 0;
        _urlController.clear();
      });
      return;
    }
    setState(() {
      _tabs.removeAt(i);
      if (_currentTabIndex >= _tabs.length) _currentTabIndex = _tabs.length - 1;
      _urlController.text = _tabs[_currentTabIndex].url;
    });
  }

  void _goHome() {
    if (_homeUrl.trim().isNotEmpty) {
      _loadUrl(_homeUrl.trim());
      return;
    }
    setState(() {
      _tab.controller = null;
      _tab.url = '';
      _tab.title = 'Trang chu';
      _urlController.clear();
    });
  }

  Future<void> _goBack() async {
    if (!_enableBackButton) return;
    final c = _tab.controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
    } else {
      _goHome();
    }
  }

  Future<void> _goForward() async {
    final c = _tab.controller;
    if (c != null && await c.canGoForward()) await c.goForward();
  }

  void _toggleGameMode() {
    setState(() {
      _gameMode = !_gameMode;
      _isFullscreen = _gameMode;
    });
    if (_gameMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  Future<void> _toggleDesktopMode() async {
    setState(() => _isDesktopUA = !_isDesktopUA);
    await _saveData();
    if (_tab.controller != null) {
      await _tab.controller!.setUserAgent(_activeUA);
      await _tab.controller!.reload();
    }
  }

  void _toggleIncognito() {
    if (!_enableIncognito) return;
    setState(() => _isIncognito = !_isIncognito);
    if (_isIncognito) {
      _tab.controller?.clearCache();
      _tab.controller?.clearLocalStorage();
    }
  }

  void _toggleBookmark() {
    final url = _tab.url;
    if (url.isEmpty) return;
    final exists = _bookmarks.any((e) => e['url'] == url);
    setState(() {
      if (exists) {
        _bookmarks.removeWhere((e) => e['url'] == url);
      } else {
        _bookmarks.insert(0, {'title': _tab.displayTitle, 'url': url});
      }
    });
    _saveData();
  }

  Future<void> _pasteAndGo() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    _urlController.text = text;
    _loadUrl(text);
  }

  void _showList(String type) {
    final source = type == 'history' ? _history : _bookmarks;
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: 400,
        child: ListView(
          children: [
            ListTile(
              title: Text(type == 'history' ? 'Lich su' : 'Dau trang',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ...source.map((e) => ListTile(
                  title: Text(e['title'] ?? '', style: const TextStyle(color: Colors.white), maxLines: 1),
                  subtitle: Text(e['url'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1),
                  onTap: () {
                    Navigator.pop(ctx);
                    _loadUrl(e['url'] ?? '');
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showTabs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tab (${_tabs.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () { _newTab(); setM(() {}); }, child: const Text('Tab moi', style: TextStyle(color: _accent))),
                ],
              ),
              ...List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                return ListTile(
                  title: Text(t.displayTitle, style: const TextStyle(color: Colors.white), maxLines: 1),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                    onPressed: () { _closeTab(i); setM(() {}); },
                  ),
                  onTap: () {
                    setState(() {
                      _currentTabIndex = i;
                      _urlController.text = _tabs[i].url;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cai dat', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Pain Browser · Trinh duyet web ca nhan\nKhong thu thap dang nhap · Khong doi IP he thong',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SwitchListTile(
                  title: const Text('An danh', style: TextStyle(color: Colors.white)),
                  value: _enableIncognito,
                  activeColor: _accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setM(() => _enableIncognito = v);
                    setState(() => _enableIncognito = v);
                    _saveData();
                  },
                ),
                SwitchListTile(
                  title: const Text('Che do may tinh', style: TextStyle(color: Colors.white)),
                  value: _isDesktopUA,
                  activeColor: _accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) async {
                    setState(() => _isDesktopUA = v);
                    setM(() {});
                    await _saveData();
                    if (_tab.controller != null) {
                      await _tab.controller!.setUserAgent(_activeUA);
                      await _tab.controller!.reload();
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Luu lich su', style: TextStyle(color: Colors.white)),
                  value: _saveHistory,
                  activeColor: _accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setM(() => _saveHistory = v);
                    setState(() => _saveHistory = v);
                    _saveData();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: _accent),
                  title: const Text('Lich su', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showList('history');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark, color: _accent),
                  title: const Text('Dau trang', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showList('bookmarks');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_paste_go, color: _accent),
                  title: const Text('Paste & Go', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pasteAndGo();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share, color: _accent),
                  title: const Text('Chia se link', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    if (_tab.url.isNotEmpty) Share.share(_tab.url);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Xoa cache', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    _tab.controller?.clearCache();
                    _tab.controller?.clearLocalStorage();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWeb = _tab.controller != null && _tab.url.isNotEmpty;
    final bookmarked = _bookmarks.any((e) => e['url'] == _tab.url);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            if (_showChrome) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_accent2, Color(0xFF6C3483)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.public, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isIncognito
                                ? 'Pain Browser · An danh'
                                : (_isDesktopUA ? 'Pain Browser · Desktop' : 'Pain Browser'),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            hasWeb ? _tab.displayTitle : 'Trang chu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (hasWeb)
                      IconButton(
                        icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: bookmarked ? _accent : Colors.white60),
                        onPressed: _toggleBookmark,
                      ),
                    IconButton(icon: const Icon(Icons.web_asset, color: Colors.white60), onPressed: _showTabs),
                    IconButton(icon: const Icon(Icons.more_vert, color: Colors.white60), onPressed: _openSettings),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _isIncognito ? _accent.withOpacity(0.7) : _border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(_isIncognito ? Icons.visibility_off : Icons.search, color: _accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Tim kiem hoac nhap dia chi...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: _loadUrl,
                        ),
                      ),
                      if (_tab.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (hasWeb && _tab.progress < 1)
                LinearProgressIndicator(value: _tab.progress, minHeight: 2, color: _accent, backgroundColor: _border),
            ],
            Expanded(
              child: Stack(
                children: [
                  hasWeb ? WebViewWidget(controller: _tab.controller!) : _home(),
                  if (_gameMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Opacity(
                        opacity: 0.45,
                        child: Material(
                          color: _card,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _toggleGameMode,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text('Thoat Game', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_showChrome)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: _enableBackButton ? _goBack : null,
                      icon: Icon(Icons.arrow_back_ios_new,
                          size: 22, color: _enableBackButton ? Colors.white70 : Colors.white24),
                    ),
                    IconButton(onPressed: _goForward, icon: const Icon(Icons.arrow_forward_ios, size: 22, color: Colors.white70)),
                    IconButton(onPressed: _newTab, icon: const Icon(Icons.add, size: 22, color: Colors.white70)),
                    IconButton(
                      onPressed: _toggleIncognito,
                      icon: Icon(_isIncognito ? Icons.visibility_off : Icons.visibility,
                          size: 22, color: _isIncognito ? _accent : Colors.white70),
                    ),
                    IconButton(
                      onPressed: _toggleDesktopMode,
                      icon: Icon(_isDesktopUA ? Icons.computer : Icons.phone_android,
                          size: 22, color: _isDesktopUA ? _accent : Colors.white70),
                    ),
                    IconButton(
                      onPressed: hasWeb ? _toggleGameMode : null,
                      icon: Icon(Icons.videogame_asset, size: 22, color: _gameMode ? _accent : Colors.white70),
                    ),
                    IconButton(onPressed: _goHome, icon: const Icon(Icons.home, size: 22, color: Colors.white70)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accent2, Color(0xFF6C3483)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.public, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Pain Browser', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Tab \( {_currentTabIndex + 1}/ \){_tabs.length}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.45)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: _accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Tim Google hoac nhap link...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: _loadUrl,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: _accent),
                    onPressed: () => _loadUrl(_urlController.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Paste & Go'),
                  onPressed: _pasteAndGo,
                  backgroundColor: _card,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                ..._quickLinks.map((l) => ActionChip(
                      label: Text(l['name'] ?? ''),
                      onPressed: () => _loadUrl(l['url'] ?? ''),
                      backgroundColor: _card,
                      labelStyle: const TextStyle(color: Colors.white),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
