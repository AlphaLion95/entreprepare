import 'package:cloud_firestore/cloud_firestore.dart';

class Guide {
  final String id;
  final String title;
  final String? summary;
  final String? bodyMarkdown;
  final List<String> tags;
  final String? coverImage;
  final String? videoUrl;
  final String? url;
  final String? category;
  final String author;
  final DateTime createdAt;

  Guide({
    required this.id,
    required this.title,
    this.summary,
    this.bodyMarkdown,
    this.tags = const [],
    this.coverImage,
    this.videoUrl,
    this.url,
    this.category,
    this.author = 'Unknown',
    required this.createdAt,
  });

  /// Helper to safely unwrap Firestore fields
  static dynamic _unwrap(dynamic v) {
    if (v == null) return null;
    if (v is Map && v.containsKey('value')) return v['value'];
    return v;
  }

  static List<String> _toList(dynamic v) {
    final unwrapped = _unwrap(v);
    if (unwrapped == null) return [];
    if (unwrapped is String) return [unwrapped];
    if (unwrapped is Iterable) {
      return unwrapped.map((e) => e?.toString() ?? '').toList();
    }
    return [unwrapped.toString()];
  }

  static DateTime _parseCreatedAt(dynamic v) {
    final unwrapped = _unwrap(v);
    if (unwrapped == null) return DateTime.now();
    if (unwrapped is int) return DateTime.fromMillisecondsSinceEpoch(unwrapped);
    if (unwrapped is Timestamp) return unwrapped.toDate();
    if (unwrapped is String) {
      try {
        return DateTime.parse(unwrapped);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Guide.fromMap(String id, Map<String, dynamic> map) {
    final type = (_unwrap(map['type']) ?? '').toString().toLowerCase();
    final legacyUrl = _unwrap(map['url'])?.toString();
    final video =
        _unwrap(map['videoUrl'])?.toString() ??
        (type == 'video' ? legacyUrl : null);

    return Guide(
      id: id,
      title: (_unwrap(map['title']) ?? '').toString(),
      summary: _unwrap(map['summary'])?.toString(),
      bodyMarkdown: _unwrap(map['bodyMarkdown'])?.toString(),
      tags: _toList(map['tags'] ?? map['tag'] ?? map['categories']),
      coverImage: _unwrap(map['coverImage'])?.toString(),
      videoUrl: video,
      url: legacyUrl,
      category: _unwrap(map['category'])?.toString(),
      author: (_unwrap(map['author']) ?? 'Unknown').toString(),
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    if (summary != null) 'summary': summary,
    if (bodyMarkdown != null) 'bodyMarkdown': bodyMarkdown,
    'tags': tags,
    if (coverImage != null) 'coverImage': coverImage,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (url != null) 'url': url,
    if (category != null) 'category': category,
    'author': author,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
