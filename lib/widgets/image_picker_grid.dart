import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget that shows existing (already-uploaded) image URLs
/// plus newly-picked local images, with per-image remove buttons and an
/// "add image" tile. Used by create/edit post and comment forms.
class ImagePickerGrid extends StatefulWidget {
  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final ValueChanged<List<String>> onExistingImagesChanged;
  final ValueChanged<List<XFile>> onNewImagesChanged;

  const ImagePickerGrid({
    super.key,
    required this.existingImageUrls,
    required this.newImages,
    required this.onExistingImagesChanged,
    required this.onNewImagesChanged,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    widget.onNewImagesChanged([...widget.newImages, ...picked]);
  }

  void _removeExisting(String url) {
    widget.onExistingImagesChanged(
      widget.existingImageUrls.where((u) => u != url).toList(),
    );
  }

  void _removeNew(XFile file) {
    widget.onNewImagesChanged(
      widget.newImages.where((f) => f != file).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final url in widget.existingImageUrls)
          _ImageTile(
            child: CachedNetworkImage(
              imageUrl: url,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (c, u) => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (c, u, e) => const Icon(Icons.broken_image),
            ),
            onRemove: () => _removeExisting(url),
          ),
        for (final file in widget.newImages)
          _ImageTile(
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                );
              },
            ),
            onRemove: () => _removeNew(file),
          ),
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_a_photo_outlined),
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageTile({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 90, height: 90, child: child),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black87,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
