import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_apps/providers/profile_provider.dart';
import 'package:quiz_apps/models/user.dart';

class EditProfileDialog extends StatefulWidget {
  final User currentProfile;

  const EditProfileDialog({super.key, required this.currentProfile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.currentProfile.displayName,
    );
    _bioController = TextEditingController(text: widget.currentProfile.bio);
    _avatarUrlController = TextEditingController(
      text: widget.currentProfile.avatarUrl,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final updatedProfile = widget.currentProfile.copyWith(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
    );

    await context.read<ProfileProvider>().updateUserProfile(updatedProfile);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _avatarUrlController,
              decoration: const InputDecoration(labelText: 'Avatar URL'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
