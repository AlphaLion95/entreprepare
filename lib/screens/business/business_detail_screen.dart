import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/business.dart';
import '../planner/plan_editor_screen.dart';

class BusinessDetailScreen extends StatelessWidget {
  final Business business;
  final Map<String, dynamic>? answers;

  const BusinessDetailScreen({super.key, required this.business, this.answers});

  String _norm(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is Iterable) return v.map((e) => e?.toString() ?? '').join(', ');
    if (v is Map) return v.values.map((e) => e?.toString() ?? '').join(', ');
    return v.toString();
  }

  List<Widget> _buildSuitability() {
    if (answers == null) {
      return [const Text('No quiz answers available to explain suitability.')];
    }

    final List<Widget> reasons = [];
    final Map<String, List<String>> bmap = {
      'personality': business.personality,
      'budget': business.budget,
      'time': business.time,
      'skills': business.skills,
      'environment': business.environment,
    };

    bmap.forEach((key, bVals) {
      final userVal = (_norm(answers![key])).toLowerCase();
      if (userVal.isEmpty) return;
      final matched = bVals
          .map((e) => e.toLowerCase())
          .where((v) => v.contains(userVal) || userVal.contains(v))
          .toList();
      if (matched.isNotEmpty) {
        reasons.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Matches your $key: "${answers![key]}" — ${bVals.join(', ')}.',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (reasons.isEmpty) {
      reasons.add(
        const Text(
          'This business may still suit you based on transferable skills or interest.',
        ),
      );
    }

    return reasons;
  }

  @override
  Widget build(BuildContext context) {
    final tag = 'business-${business.docId ?? business.title}';
    final double topPadding = MediaQuery.of(context).padding.top + 12.0;
    // slightly larger header to avoid overflow when system bars present
    const double headerHeight = 200.0;

    return Scaffold(
      appBar: AppBar(
        // remove the black title to avoid duplicate text overlap, keep back button visible in white
        title: const SizedBox.shrink(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Header card with hero avatar and key info
          Container(
            height: headerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade300],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            padding: EdgeInsets.only(
              top: topPadding,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                Hero(
                  tag: tag,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (business.title.isNotEmpty
                          ? business.title[0].toUpperCase()
                          : '?'),
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // keep only the white title (AppBar title removed)
                      Text(
                        business.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        business.description,
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (business.cost.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cost: ${business.cost}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (business.earnings.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Earnings: ${business.earnings}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
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

          // Details area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why it suits you',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._buildSuitability(),
                  const Divider(height: 28),

                  const Text(
                    'Estimated startup cost',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        business.cost.isNotEmpty
                            ? business.cost
                            : 'Not specified',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Potential earnings range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        business.earnings.isNotEmpty
                            ? business.earnings
                            : 'Not specified',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Initial steps to start',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (business.initialSteps.isNotEmpty)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            business.initialSteps.length,
                            (i) {
                              final step = business.initialSteps[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue.shade50,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(step)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('No initial steps provided.'),

                  const SizedBox(height: 20),

                  // CTA row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // save business to user's favorites in Firestore
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to save'),
                                ),
                              );
                              return;
                            }
                            final favId = business.docId ?? business.title;
                            final docRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('favorites')
                                .doc(favId);

                            final payload = {
                              'businessId': favId,
                              'title': business.title,
                              'description': business.description,
                              'cost': business.cost,
                              'earnings': business.earnings,
                              'initialSteps': business.initialSteps,
                              'personality': business.personality,
                              'budget': business.budget,
                              'time': business.time,
                              'skills': business.skills,
                              'environment': business.environment,
                              '__savedAt': FieldValue.serverTimestamp(),
                            };

                            try {
                              await docRef.set(
                                payload,
                                SetOptions(merge: true),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved to favorites'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // open Plan editor prefilled by this business
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlanEditorScreen(business: business),
                              ),
                            );
                            if (result == true) {
                              // Optional toast already shown from editor redirect
                            }
                          },
                          icon: const Icon(Icons.playlist_add_check),
                          label: const Text('Start'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
