import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReaderWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  const ReaderWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ReaderWebViewScreen> createState() => _ReaderWebViewScreenState();
}

class _ReaderWebViewScreenState extends State<ReaderWebViewScreen> {
  bool _loading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
