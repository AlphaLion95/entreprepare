import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide.dart';

class GuideService {
  // point to the collection you updated in Firestore
  final _col = FirebaseFirestore.instance.collection('learningResources');

  Future<List<Guide>> fetchGuides({String? tag, String? query, int limit = 50}) async {
    Query q = _col.orderBy('createdAt', descending: true).limit(limit);
    if (tag != null && tag.isNotEmpty) {
      q = q.where('tags', arrayContains: tag);
    }
    final snap = await q.get();
    // debug
    // ignore: avoid_print
    print('DEBUG: fetched ${snap.docs.length} docs from learningResources');
    var guides = snap.docs.map((d) => Guide.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

    if (query != null && query.isNotEmpty) {
      final ql = query.toLowerCase();
      guides = guides.where((g) =>
          g.title.toLowerCase().contains(ql) ||
          (g.summary ?? '').toLowerCase().contains(ql) ||
          (g.bodyMarkdown ?? '').toLowerCase().contains(ql) ||
          g.tags.any((t) => t.toLowerCase().contains(ql)) ||
          (g.category ?? '').toLowerCase().contains(ql) ||
          (g.url ?? '').toLowerCase().contains(ql)
      ).toList();
      // ignore: avoid_print
      print('DEBUG: after filter, ${guides.length} guides match "$query"');
    }

    return guides;
  }

  Future<Guide?> fetchGuideById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Guide.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}