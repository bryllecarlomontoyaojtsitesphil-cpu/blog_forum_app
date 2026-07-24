import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../services/post_service.dart';
import '../../utils/validators.dart';
import '../../widgets/image_picker_grid.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  const EditPostScreen({super.key, required this.postId});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postService = PostService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<XFile> _newImages = [];
  List<String> _keptImages = [];

  PostModel? _original;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.fetchPostById(widget.postId);
      _original = post;
      _titleController.text = post.title;
      _contentController.text = post.content;
      _keptImages = List.of(post.images);
    } catch (e) {
      _loadError = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _original == null) return;
    setState(() => _isSubmitting = true);

    final result = await context.read<PostProvider>().updatePost(
          original: _original!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          keptExistingImages: _keptImages,
          newImages: _newImages,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
    Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<PostProvider>().errorMessage ?? 'Failed to update post'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_loadError != null || _original == null) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: ${_loadError ?? 'Post not found'}'),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Post', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => Validators.required(v, field: 'Title'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: 'Content'),
                        maxLines: 6,
                        validator: (v) => Validators.required(v, field: 'Content'),
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Images'),
                      ),
                      const SizedBox(height: 8),
                      ImagePickerGrid(
                        existingImageUrls: _keptImages,
                        newImages: _newImages,
                        onExistingImagesChanged: (urls) => setState(() => _keptImages = urls),
                        onNewImagesChanged: (files) => setState(() {
                          _newImages
                            ..clear()
                            ..addAll(files);
                        }),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: 160,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}