import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/guide.dart';

class GuideCard extends StatelessWidget {
  final Guide guide;
  final VoidCallback? onTap;
  const GuideCard({super.key, required this.guide, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (guide.coverImage != null && guide.coverImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: guide.coverImage!,
                    width: 88,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (c, _) => Container(
                      color: Colors.grey.shade200,
                      width: 88,
                      height: 64,
                    ),
                    errorWidget: (c, e, s) => Container(
                      // 👈 ADD THIS
                      width: 88,
                      height: 64,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  width: 88,
                  height: 64,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.article),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      guide.summary ?? 'No summary available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: guide.tags
                          .take(3)
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
