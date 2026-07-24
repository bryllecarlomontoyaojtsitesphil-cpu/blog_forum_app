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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _newImages
        ..clear()
        ..add(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
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

              // Image area
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black12,
                      child: _newImages.isEmpty
                          ? const Center(
                              child: Icon(Icons.add_photo_alternate, size: 40),
                            )
                          : _ImagePreview(image: _newImages.first),
                    ),
                  ),
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