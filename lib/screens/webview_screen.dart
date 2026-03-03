import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String initialTab; // 'privacy' or 'terms'

  const WebViewScreen({super.key, this.initialTab = 'privacy'});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String _privacyUrl =
      'https://www.termsfeed.com/live/your-privacy-policy-url';
  static const String _termsUrl =
      'https://www.termsfeed.com/live/your-terms-url';

  late final WebViewController _privacyController;
  late final WebViewController _termsController;

  bool _privacyLoading = true;
  bool _termsLoading = true;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab == 'terms' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);

    _privacyController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _privacyLoading = false),
      ))
      ..loadRequest(Uri.parse(_privacyUrl));

    _termsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _termsLoading = false),
      ))
      ..loadRequest(Uri.parse(_termsUrl));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Legal',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 52),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: isDark ? Colors.white : const Color(0xFF111111),
                  unselectedLabelColor: const Color(0xFF888888),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Privacy Policy'),
                    Tab(text: 'Terms & Conditions'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // WebView content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Privacy Policy tab
                  Stack(
                    children: [
                      WebViewWidget(controller: _privacyController),
                      if (_privacyLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6B8A),
                            strokeWidth: 2.5,
                          ),
                        ),
                    ],
                  ),

                  // Terms & Conditions tab
                  Stack(
                    children: [
                      WebViewWidget(controller: _termsController),
                      if (_termsLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6B8A),
                            strokeWidth: 2.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
