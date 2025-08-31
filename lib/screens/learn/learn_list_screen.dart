import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/guide_service.dart';
import '../../models/guide.dart';
import '../../widgets/guide_card.dart';
import 'guide_detail_screen.dart';

class LearnListScreen extends StatefulWidget {
  const LearnListScreen({super.key});
  @override
  State<LearnListScreen> createState() => _LearnListScreenState();
}

class _LearnListScreenState extends State<LearnListScreen> {
  final GuideService _service = GuideService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Guide> _guides = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final guides = await _service.fetchGuides();
      if (mounted) {
        setState(() {
          _guides = guides;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _guides = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _loading = true);
    try {
      final results = await _service.fetchGuides(query: query);
      if (mounted) {
        setState(() {
          _guides = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _guides = [];
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String v) {
    _query = v;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _performSearch(_query),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _query = '';
    _load();
    FocusScope.of(context).unfocus();
  }

  void _openGuide(Guide g) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuideDetailScreen(guideId: g.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Hub')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search guides or tags',
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _guides.isEmpty
                ? RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const <Widget>[
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'No guides found',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: _guides.length,
                      itemBuilder: (context, index) => GuideCard(
                        guide: _guides[index],
                        onTap: () => _openGuide(_guides[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
