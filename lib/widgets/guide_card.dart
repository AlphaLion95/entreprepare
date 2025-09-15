import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/guide.dart';
import '../utils/link_utils.dart';

class GuideCard extends StatelessWidget {
  final Guide guide;
  final VoidCallback? onTap;
  const GuideCard({super.key, required this.guide, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Compute a best-effort cover image: explicit cover > YouTube thumbnail > site favicon
  final String? coverCandidate =
    (guide.coverImage != null && guide.coverImage!.isNotEmpty)
      ? guide.coverImage
      : (youtubeThumbnailFromUrl(guide.videoUrl) ??
        faviconFromUrl(guide.url));
  final bool isAssetCover =
    coverCandidate != null && coverCandidate.startsWith('assets/');
  final String? coverUrl = (!isAssetCover && isPlaceholderImageUrl(coverCandidate))
    ? null
    : coverCandidate;
    final String? validLink = isValidExternalLink(guide.videoUrl)
        ? guide.videoUrl
        : (isValidExternalLink(guide.url) ? guide.url : null);
    final bool isYouTube = isYouTubeUrl(guide.videoUrl);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.grey.shade100,
                    child: isAssetCover
                        ? Image.asset(
                            coverUrl,
                            width: isYouTube ? 112 : 88,
                            height: isYouTube ? 72 : 64,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: isYouTube ? 112 : 88,
                            height: isYouTube ? 72 : 64,
                            fit: (coverUrl.contains('s2/favicons'))
                                ? BoxFit.contain
                                : BoxFit.cover,
                            placeholder: (c, _) => Container(
                              color: Colors.grey.shade200,
                              width: isYouTube ? 112 : 88,
                              height: isYouTube ? 72 : 64,
                            ),
                            errorWidget: (c, e, s) => Container(
                              width: isYouTube ? 112 : 88,
                              height: isYouTube ? 72 : 64,
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
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
                    if (validLink != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              extractDomain(validLink) ?? 'Open',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
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
