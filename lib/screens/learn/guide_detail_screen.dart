import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/guide_service.dart';
import '../../models/guide.dart';
import '../../utils/link_utils.dart';
import 'reader_webview_screen.dart';

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

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _fallbackSummary(Guide g) {
    final isVideo =
        (g.category ?? '').toLowerCase().contains('video') ||
        (g.videoUrl != null && g.videoUrl!.isNotEmpty);
    final domain = extractDomain(g.videoUrl ?? g.url) ?? 'source';
    final cat = (g.category ?? (isVideo ? 'Video' : 'Article'));
    final tags = g.tags.isNotEmpty ? g.tags.take(3).join(', ') : null;
    final tail = tags != null ? ' covering $tags' : '';
    return '$cat from $domain$tail.';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await _service.fetchGuideById(widget.guideId);
    if (mounted) {
      setState(() {
        _guide = g;
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_guide == null) {
      return Scaffold(body: Center(child: Text('Guide not found')));
    }

  final g = _guide!;
  final coverCandidate = (g.coverImage != null && g.coverImage!.isNotEmpty)
    ? g.coverImage
    : (youtubeThumbnailFromUrl(g.videoUrl) ?? faviconFromUrl(g.url));
  final bool isAssetCover =
    coverCandidate != null && coverCandidate.startsWith('assets/');
  final coverUrl = (!isAssetCover && isPlaceholderImageUrl(coverCandidate))
    ? null
    : coverCandidate;
    final validVideo = isValidExternalLink(g.videoUrl) ? g.videoUrl : null;
    final validUrl = isValidExternalLink(g.url) ? g.url : null;
    final domain = extractDomain(validVideo ?? validUrl) ?? '';
    final summary = (g.summary != null && g.summary!.trim().isNotEmpty)
        ? g.summary!.trim()
        : _fallbackSummary(g);
    final isYouTube = isYouTubeUrl(validVideo);
    return Scaffold(
      appBar: AppBar(title: Text(g.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (coverUrl != null)
              (isAssetCover
                  ? Image.asset(
                      coverUrl,
                      width: double.infinity,
                      height: isYouTube ? 220 : 180,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: double.infinity,
                      height: isYouTube ? 220 : 180,
                      fit: (coverUrl.contains('s2/favicons'))
                          ? BoxFit.contain
                          : BoxFit.cover,
                      errorWidget: (c, e, s) => Container(
                        height: isYouTube ? 220 : 180,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    )),
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
                  const SizedBox(height: 8),
                  if (summary.isNotEmpty)
                    Text(summary, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (domain.isNotEmpty) ...[
                        const Icon(
                          Icons.public,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          domain,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        g.author,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmtDate(g.createdAt),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  if (g.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: g.tags
                          .take(6)
                          .map(
                            (t) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(t),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (validVideo != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.ondemand_video),
                          label: const Text('Play video'),
                          onPressed: () => _openUrl(validVideo),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  if (validUrl != null && validVideo == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open resource'),
                          onPressed: () => _openUrl(validUrl),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.chrome_reader_mode),
                          label: const Text('Read in app'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReaderWebViewScreen(
                                  url: validUrl,
                                  title: g.title,
                                ),
                              ),
                            );
                          },
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
