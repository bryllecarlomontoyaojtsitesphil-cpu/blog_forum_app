import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../utils/date_format.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  void _openImageViewer(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ImageViewerDialog(
        images: comment.images,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.authorAvatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
          child: !hasAvatar ? const Icon(Icons.person, size: 16) : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            comment.authorEmail ?? 'User${comment.userId.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (isOwner)
          SizedBox(
            height: 24,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 20),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
      ],
    ),
    const SizedBox(height: 4),
    Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Row(
        children: [
          Expanded(
            child: Text(comment.content),
          ),
          Text(
            formatPostDate(comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  ],
),

          if (comment.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: comment.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _openImageViewer(context, index),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: comment.images[index],
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewerDialog({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}