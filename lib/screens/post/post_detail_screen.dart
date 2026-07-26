import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/post_service.dart';
import '../../widgets/comment_tile.dart';
import '../../widgets/image_picker_grid.dart';
import 'dart:typed_data';
import '../../utils/date_format.dart';
import '../edit_post/edit_post_screen.dart';
import '../login/login_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  PostModel? _post;
  bool _isLoading = true;
  String? _loadError;

  final _newCommentController = TextEditingController();
  final List<XFile> _newCommentImages = [];
  bool _isPostingComment = false;

  // Comment being edited, if any.
  CommentModel? _editingComment;
  final _editCommentController = TextEditingController();
  List<String> _editKeptImages = [];
  final List<XFile> _editNewImages = [];

  @override
  void initState() {
    super.initState();
    _loadPost();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().fetchComments(widget.postId);
    });
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.fetchPostById(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

Future<void> _deletePost() async {
  final confirmed = await _confirm('Delete this post?');
  if (!confirmed || _post == null) return;
  if (!mounted) return;   // ← add this check here too
  final success = await context.read<PostProvider>().deletePost(_post!);
  if (!mounted) return;
  if (success) {
    context.pop();
  } else {
    final error = context.read<PostProvider>().errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Failed to delete post')),
    );
  }
}

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.pop(true), child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickCommentImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _newCommentImages.add(picked));
  }

  Future<void> _submitComment() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    if (_newCommentController.text.trim().isEmpty && _newCommentImages.isEmpty) return;

    setState(() => _isPostingComment = true);
    final success = await context.read<CommentProvider>().addComment(
          postId: widget.postId,
          userId: userId,
          content: _newCommentController.text.trim(),
          images: _newCommentImages,
        );
    if (!mounted) return;
    setState(() => _isPostingComment = false);

    if (success) {
      _newCommentController.clear();
      setState(() => _newCommentImages.clear());
    } else {
      final error = context.read<CommentProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to post comment')),
      );
    }
  }

  void _startEditComment(CommentModel comment) {
    setState(() {
      _editingComment = comment;
      _editCommentController.text = comment.content;
      _editKeptImages = List.of(comment.images);
      _editNewImages.clear();
    });
  }

  Future<void> _saveEditedComment() async {
    if (_editingComment == null) return;
    final success = await context.read<CommentProvider>().updateComment(
          original: _editingComment!,
          content: _editCommentController.text.trim(),
          keptExistingImages: _editKeptImages,
          newImages: _editNewImages,
        );
    if (!mounted) return;
    if (success) {
      setState(() => _editingComment = null);
    } else {
      final error = context.read<CommentProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to update comment')),
      );
    }
  }

Future<void> _deleteComment(CommentModel comment) async {
  final confirmed = await _confirm('Delete this comment?');
  if (!confirmed) return;
  if (!mounted) return;
  final success = await context.read<CommentProvider>().deleteComment(comment);
  if (!mounted) return;
  if (!success) {
    final error = context.read<CommentProvider>().errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Failed to delete comment')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final commentProvider = context.watch<CommentProvider>();

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.go('/'),
  ),
  title: const Text('Post'),
),
      body: _buildBody(auth, commentProvider),
    );
  }

  Widget _buildBody(AuthProvider auth, CommentProvider commentProvider) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null || _post == null) {
      return Center(child: Text('Error: ${_loadError ?? 'Post not found'}'));
    }

    final post = _post!;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Row(
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
const SizedBox(height: 12),
if (post.images.isNotEmpty)
  _PostImages(
    key: ValueKey(post.images.join(',')),
    images: post.images,
  ),
const SizedBox(height: 12),
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
    ),
    if (auth.currentUser?.id == post.userId)
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz),
        onSelected: (value) async {
          if (value == 'edit') {
            final updated = await showDialog<PostModel>(
              context: context,
              builder: (_) => EditPostScreen(postId: post.id),
            );
            if (updated != null && mounted) {
              setState(() => _post = updated);
            }
          }
          if (value == 'delete') _deletePost();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
  ],
),
              const SizedBox(height: 12),
              Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
                  const Divider(height: 32),
                  Text('Comments (${commentProvider.comments.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (commentProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    for (final comment in commentProvider.comments)
                      _editingComment?.id == comment.id
                          ? _buildEditCommentForm()
                          : CommentTile(
                              comment: comment,
                              isOwner: auth.currentUser?.id == comment.userId,
                              onEdit: () => _startEditComment(comment),
                              onDelete: () => _deleteComment(comment),
                            ),
                  const SizedBox(height: 16),
                  if (auth.isLoggedIn) _buildNewCommentForm() else _buildLoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Card(
      child: ListTile(
        title: const Text('Login to leave a comment'),
        trailing: TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const LoginScreen(),
          ),
          child: const Text('Login'),
        ),
      ),
    );
  }

  Widget _buildNewCommentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_newCommentImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _newCommentImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _ComposerImagePreview(image: _newCommentImages[index]),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _newCommentImages.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        TextField(
          controller: _newCommentController,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            prefixIcon: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: _pickCommentImage,
              ),
            ),
            suffixIcon: _isPostingComment
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitComment,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditCommentForm() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _editCommentController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            ImagePickerGrid(
              existingImageUrls: _editKeptImages,
              newImages: _editNewImages,
              onExistingImagesChanged: (urls) => setState(() => _editKeptImages = urls),
              onNewImagesChanged: (files) => setState(() {
                _editNewImages
                  ..clear()
                  ..addAll(files);
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _editingComment = null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveEditedComment,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostImages extends StatefulWidget {
  final List<String> images;
  const _PostImages({super.key, required this.images});

  @override
  State<_PostImages> createState() => _PostImagesState();
}

class _PostImagesState extends State<_PostImages> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.images.length > 1;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.black12,
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  errorWidget: (c, u, e) => const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),

          if (hasMultiple && _currentIndex > 0)
            Positioned(
              left: 8,
              child: _NavArrow(
                icon: Icons.chevron_left,
                onTap: () => _goTo(_currentIndex - 1),
              ),
            ),

          if (hasMultiple && _currentIndex < widget.images.length - 1)
            Positioned(
              right: 8,
              child: _NavArrow(
                icon: Icons.chevron_right,
                onTap: () => _goTo(_currentIndex + 1),
              ),
            ),

          if (hasMultiple)
            Positioned(
              bottom: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.images.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.black54,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ComposerImagePreview extends StatelessWidget {
  final XFile image;
  const _ComposerImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 60, height: 60);
        }
        return Image.memory(snapshot.data!, width: 60, height: 60, fit: BoxFit.cover);
      },
    );
  }
}