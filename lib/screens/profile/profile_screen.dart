import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSavingName = false;
  bool _isUpdatingPhoto = false;
  bool _isEditingName = false;
  bool _showSaveSuccessMessage = false;
  Timer? _saveSuccessTimer;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentProfile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _saveSuccessTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _showProfileSavedMessage() {
    _saveSuccessTimer?.cancel();
    setState(() => _showSaveSuccessMessage = true);
    _saveSuccessTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showSaveSuccessMessage = false);
    });
  }

  void _openAvatarViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: Container(
                width: 360,
                height: 360,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white70,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => const ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final authProvider = context.read<AuthProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUpdatingPhoto = true);
    final success = await authProvider.uploadAvatar(picked);
    if (!mounted) return;
    setState(() => _isUpdatingPhoto = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update photo',
          ),
        ),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isUpdatingPhoto = true);
    final success = await context.read<AuthProvider>().deleteAvatar();
    if (!mounted) return;
    setState(() => _isUpdatingPhoto = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Failed to remove photo',
          ),
        ),
      );
    }
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingName = true);
    final success = await context
        .read<AuthProvider>()
        .updateDisplayName(_nameController.text.trim());
    if (!mounted) return;
    setState(() => _isSavingName = false);

    if (success) {
      setState(() => _isEditingName = false);
      _showProfileSavedMessage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Failed to update name',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<AuthProvider>().currentProfile;
    final avatarUrl = profile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final userEmail = auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        MouseRegion(
                          cursor: hasAvatar
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: hasAvatar ? () => _openAvatarViewer(avatarUrl) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage:
                                    hasAvatar ? CachedNetworkImageProvider(avatarUrl) : null,
                                child: !hasAvatar
                                    ? Text(
                                        (profile?.displayName ?? '?')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (_isUpdatingPhoto)
                          const Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.black45,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _isUpdatingPhoto ? null : _pickAndUploadAvatar,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 3,
                                  ),
                                ),
                                padding: const EdgeInsets.all(7),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userEmail,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (hasAvatar) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: _isUpdatingPhoto ? null : _removeAvatar,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove photo'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'DISPLAY NAME',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.6,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                enabled: _isEditingName,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter a display name',
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Display name is required'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isSavingName
                                      ? null
                                      : () {
                                          if (_isEditingName) {
                                            _saveName();
                                          } else {
                                            setState(() => _isEditingName = true);
                                          }
                                        },
                                  icon: _isSavingName
                                      ? const SizedBox.shrink()
                                      : Icon(
                                          _isEditingName ? Icons.check : Icons.edit,
                                          size: 18,
                                        ),
                                  label: _isSavingName
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(_isEditingName ? 'Save' : 'Edit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showSaveSuccessMessage
                  ? Center(
                      child: Container(
                      key: const ValueKey('profile-saved-message'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Profile updated successfully.',
                              softWrap: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}