import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/guide_service.dart';
import '../../models/guide.dart';

class GuideDetailScreen extends StatefulWidget {
  final String guideId;
  const GuideDetailScreen({super.key, required this.guideId});
  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  final GuideService _service = GuideService();
  Guide? _guide;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await _service.fetchGuideById(widget.guideId);
    if (mounted)
      setState(() {
        _guide = g;
        _loading = false;
      });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: avoid_print
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_guide == null)
      return Scaffold(body: Center(child: Text('Guide not found')));

    final g = _guide!;
    return Scaffold(
      appBar: AppBar(title: Text(g.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (g.coverImage != null && g.coverImage!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: g.coverImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorWidget: (c, e, s) => Container(
                  // 👈 ADD THIS
                  height: 200,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Category: ${g.category ?? '—'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  if (g.videoUrl != null && g.videoUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.ondemand_video),
                          label: const Text('Play video'),
                          onPressed: () => _openUrl(g.videoUrl!),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  if (g.url != null &&
                      (g.videoUrl == null || g.videoUrl!.isEmpty))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open resource'),
                          onPressed: () => _openUrl(g.url!),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  if (g.bodyMarkdown != null && g.bodyMarkdown!.isNotEmpty)
                    MarkdownBody(data: g.bodyMarkdown!),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
