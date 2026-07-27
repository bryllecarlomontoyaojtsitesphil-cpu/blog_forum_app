import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../utils/validators.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<XFile> _newImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final result = await context.read<PostProvider>().createPost(
          userId: userId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          newImages: _newImages,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<PostProvider>().errorMessage ?? 'Failed to create post'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Create Post', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Main image area — same size/shape as the original single-image tile.
                // Shows the picker icon when empty, or the first picked image with a
                // small "add more" button overlaid once at least one image is added.
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _newImages.isEmpty
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              color: Colors.black12,
                              child: const Center(
                                child: Icon(Icons.add_photo_alternate, size: 40),
                              ),
                            ),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            _ImagePreview(image: _newImages.first),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: _SmallAddButton(onTap: _pickImages),
                            ),
                          ],
                        ),
                ),

                // Thumbnail strip for managing/removing individual images once
                // more than one has been picked.
                if (_newImages.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _newImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => SizedBox(
                          width: 64,
                          child: _ImageThumbnail(
                            image: _newImages[index],
                            onRemove: () => _removeImage(index),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_newImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_newImages.length} image${_newImages.length == 1 ? '' : 's'} selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => Validators.required(v, field: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: 'Content'),
                        maxLines: 2,
                        validator: (v) => Validators.required(v, field: 'Content'),
                      ),
                      const SizedBox(height: 20),
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
                                : const Text('Publish'),
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

class _SmallAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SmallAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.add_photo_alternate, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile image;
  const _ImagePreview({required this.image});

  @override
  Widget build(BuildContext context) {
    // Works for both web (bytes) and mobile/desktop (File path)
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
      },
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final XFile image;
  final VoidCallback onRemove;
  const _ImageThumbnail({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: Colors.black12,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}