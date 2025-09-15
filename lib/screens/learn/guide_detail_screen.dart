import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert' as convert;
import '../../services/guide_service.dart';
import '../../models/guide.dart';
import '../../utils/link_utils.dart';
import 'reader_webview_screen.dart';
import '../../services/local_store.dart';

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
  Future<String?>? _previewFuture;

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
    if (!mounted) return;
    Future<String?>? preview;
    final gv = g?.videoUrl;
    final gu = g?.url;
    final gb = g?.bodyMarkdown;
    final validVideo = isValidExternalLink(gv) ? gv : null;
    final validUrl = isValidExternalLink(gu) ? gu : null;
    final needsPreview = (gb == null || gb.isEmpty) &&
        validUrl != null && validVideo == null;
    if (needsPreview) {
      // Try cached preview first (valid for 7 days)
      final cached = await LocalStore.loadLearnPreviewText(
        validUrl,
        maxAge: const Duration(days: 7),
      );
      if (cached != null) {
        preview = Future.value(cached);
      } else {
        preview = _fetchPreview(validUrl).then((v) async {
          if (v != null && v.isNotEmpty) {
            await LocalStore.saveLearnPreviewText(validUrl, v);
          }
          return v;
        });
      }
    }
    setState(() {
      _guide = g;
      _previewFuture = preview;
      _loading = false;
    });
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

  Future<String?> _fetchPreview(String url) async {
    if (kIsWeb) {
      // On web, use the HTTPS function to fetch preview with CORS.
      try {
        final u = Uri.parse('https://us-central1-entreprepare-e1d7d.cloudfunctions.net/preview').replace(
          queryParameters: { 'target': url },
        );
        final resp = await http.get(u).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = convert.jsonDecode(resp.body);
          if (data is Map && data['preview'] is String) {
            final val = (data['preview'] as String).trim();
            return val.isNotEmpty ? val : null;
          }
        }
      } catch (_) {}
      return null;
    }
    try {
      // Fetch only the first ~200KB to avoid heavy parsing on large pages
      final resp = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome Mobile Safari/537.36',
              'Range': 'bytes=0-200000',
            },
          )
          .timeout(const Duration(seconds: 8));
      String? parsed;
      if (resp.statusCode == 200 || resp.statusCode == 206) {
        final html = resp.body;
        final sample = _makeSample(html);
        parsed = await compute(_extractPreviewText, sample);
      }
      // Fallback: try a small full GET if range failed or parsing returned null
      if (parsed == null) {
        final resp2 = await http
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome Mobile Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              },
            )
            .timeout(const Duration(seconds: 8));
        if (resp2.statusCode == 200) {
          final html2 = resp2.body;
          final sample2 = _makeSample(html2);
          parsed = await compute(_extractPreviewText, sample2);
        }
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  // Build a parsing sample: head + first ~50KB of body to catch first paragraph
  String _makeSample(String html) {
    final lower = html.toLowerCase();
    final headEnd = lower.indexOf('</head>');
    const bodyExtra = 50000; // 50KB after head
    const capNoHead = 150000; // 150KB if no head
    if (headEnd >= 0) {
      final end = (headEnd + 7 + bodyExtra);
      final endIdx = end < html.length ? end : html.length;
      return html.substring(0, endIdx);
    }
    final endIdx = html.length < capNoHead ? html.length : capNoHead;
    return html.substring(0, endIdx);
  }

  // Parsing helpers moved to background isolate function below.

// Runs in a background isolate via `compute` to avoid jank.
String? _extractPreviewText(String sample) {
  String _stripHtmlIso(String s) => s.replaceAll(RegExp('<[^>]+>'), ' ');
  String _normalizeSpacesIso(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
  String _decodeEntitiesIso(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  String? _extractMetaIso(String html, String attr, String value) {
    final pattern = RegExp(
      '<meta[^>]*' + attr + '=["\']' + value + '["\'][^>]*content=["\'](.*?)["\']',
      caseSensitive: false,
      dotAll: true,
    );
    final altPattern = RegExp(
      '<meta[^>]*content=["\'](.*?)["\'][^>]*' + attr + '=["\']' + value + '["\']',
      caseSensitive: false,
      dotAll: true,
    );
    final m = pattern.firstMatch(html) ?? altPattern.firstMatch(html);
    return m != null ? m.group(1) : null;
  }

  String? _firstGoodParagraphIso(String html) {
    final paraRe =
        RegExp('<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true);
    final matches = paraRe.allMatches(html).toList();
    bool isEnumeratedStart(String s) {
      final ls = s.trimLeft();
      return RegExp(r'^(step|part)\s*\d+[:).\-]\s*', caseSensitive: false)
              .hasMatch(ls) ||
          RegExp(r'^\d+\s*[).\-:]\s*').hasMatch(ls);
    }
    String clean(String raw) =>
        _normalizeSpacesIso(_decodeEntitiesIso(_stripHtmlIso(raw))).trim();
    // Prefer first paragraph that looks like a real intro sentence
    for (final m in matches) {
      final txt = m.group(1);
      if (txt == null) continue;
      final plain = clean(txt);
      if (plain.isEmpty) continue;
      if (plain.length < 40) continue; // too short, likely label/byline
      if (isEnumeratedStart(plain)) continue; // skip list starts like "1.)" or "Step 1"
      if (plain.toLowerCase().startsWith('by ') ||
          plain.toLowerCase().startsWith('posted ') ||
          plain.toLowerCase().contains('cookie') ||
          plain.toLowerCase().contains('subscribe')) continue;
      return plain;
    }
    // Fallback: first non-empty paragraph
    for (final m in matches) {
      final txt = m.group(1);
      if (txt == null) continue;
      final plain = clean(txt);
      if (plain.isNotEmpty) return plain;
    }
    return null;
  }

  

  // Try meta tags in order: og:description, twitter:description, name=description
  final metaOg = _extractMetaIso(sample, 'property', 'og:description');
  final metaTwitter = _extractMetaIso(sample, 'name', 'twitter:description') ??
      _extractMetaIso(sample, 'property', 'twitter:description');
  final metaName = _extractMetaIso(sample, 'name', 'description');
  var text = metaOg ?? metaTwitter ?? metaName;
  // If meta missing, try JSON-LD description fields
  if (text == null) {
    final ld = RegExp(
      r'<script[^>]*type\s*=\s*"application/ld\+json"[^>]*>([\s\S]*?)<\/script>',
      caseSensitive: false,
    ).firstMatch(sample);
    if (ld != null) {
      final json = ld.group(1) ?? '';
      final descMatch = RegExp(
        r'"description"\s*:\s*"([\s\S]*?)"',
      ).firstMatch(json);
      if (descMatch != null) {
        text = descMatch.group(1);
      }
    }
  }
  // Finally, fallback to first good paragraph in the body
  text = text ?? _firstGoodParagraphIso(sample);
  if (text == null) return null;
  text = _normalizeSpacesIso(_decodeEntitiesIso(_stripHtmlIso(text))).trim();
  if (text.isEmpty) return null;
  // Keep only a clean first sentence to avoid list items like "1..."
  int end = text.indexOf(RegExp(r'[.!?]\s'));
  if (end != -1 && end >= 60) {
    text = text.substring(0, end + 1);
  } else if (text.length > 220) {
    text = text.substring(0, 220).trim() + '…';
  }
  // Remove leftover leading enumeration tokens
  text = text.replaceFirst(RegExp(r'^\s*\d+\s*[).\-:]\s*'), '');
  text = text.replaceFirst(
      RegExp(r'^(step|part)\s*\d+[:).\-]\s*', caseSensitive: false), '');
  return text;
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (domain.isNotEmpty) ...[
                        const Icon(Icons.public, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          domain,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                      const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        g.author,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
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
                        if (_previewFuture != null)
                          FutureBuilder<String?>(
                            future: _previewFuture,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const SizedBox();
                              }
                              final style = Theme.of(context).textTheme.bodyMedium;
                              final text = (snap.data ?? '').trim();
                              final display = text.isNotEmpty ? text : summary;
                              if (display.isEmpty) return const SizedBox();
                              return RichText(
                                text: TextSpan(
                                  style: style,
                                  children: [
                                    TextSpan(text: display + ' '),
                                    TextSpan(
                                      text: 'Read more',
                                      style: style?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
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
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          Builder(builder: (context) {
                            final style = Theme.of(context).textTheme.bodyMedium;
                            if (summary.isEmpty) return const SizedBox();
                            return RichText(
                              text: TextSpan(
                                style: style,
                                children: [
                                  TextSpan(text: summary + ' '),
                                  TextSpan(
                                    text: 'Read more',
                                    style: style?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
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
                                ],
                              ),
                            );
                          }),
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
