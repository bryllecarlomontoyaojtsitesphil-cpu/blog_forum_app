import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../utils/date_format.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
  child: Row(
    children: [
      const CircleAvatar(radius: 20, child: Icon(Icons.person, size: 32)),
      const SizedBox(width: 8),
      Text(
        post.authorEmail ?? 'User${post.userId.substring(0, 8)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const Spacer(),
      Text(
        formatPostDate(post.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  ),
),
if (post.images.isNotEmpty) _ImagesPreview(images: post.images),
Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        post.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(
        post.content,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
),
        ],
      ),
    ),
  );
}
}
class _ImagesPreview extends StatelessWidget {
  final List<String> images;
  const _ImagesPreview({required this.images});

  @override
  Widget build(BuildContext context) {
    final count = images.length;

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _GridImage(url: images[0]),
      );
    }

    if (count == 2) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            Expanded(child: _GridImage(url: images[0], padRight: true)),
            Expanded(child: _GridImage(url: images[1])),
          ],
        ),
      );
    }

    if (count == 3) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            Expanded(child: _GridImage(url: images[0], padRight: true)),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _GridImage(url: images[1], padBottom: true)),
                  Expanded(child: _GridImage(url: images[2])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 or more: 2x2 grid, with a "+N" overlay on the last tile if there are extras.
    final extra = count - 4;
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _GridImage(url: images[0], padRight: true, padBottom: true)),
                Expanded(child: _GridImage(url: images[1], padBottom: true)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _GridImage(url: images[2], padRight: true)),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _GridImage(url: images[3]),
                      if (extra > 0)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+$extra',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridImage extends StatelessWidget {
  final String url;
  final bool padRight;
  final bool padBottom;

  const _GridImage({
    required this.url,
    this.padRight = false,
    this.padBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: padRight ? 2 : 0, bottom: padBottom ? 2 : 0),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (c, u, e) => const Icon(Icons.broken_image),
      ),
    );
  }
}