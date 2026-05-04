import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cpapp/core/theme/app_colors.dart';

/// Circular avatar that lets the broker pick a photo from camera or gallery.
/// Calls [onImagePicked] with the selected [File].
class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.onImagePicked,
    this.currentFile,
    this.networkUrl,
    this.radius = 52,
  });

  final ValueChanged<File> onImagePicked;
  final File? currentFile;
  final String? networkUrl;
  final double radius;

  Future<void> _pick(BuildContext context) async {
    final source = await _showSourceSheet(context);
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: AppConstants._quality,
      maxWidth: 600,
    );
    if (picked != null) onImagePicked(File(picked.path));
  }

  Future<ImageSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.navyLight,
            backgroundImage: _resolveImage(),
            child: _resolveImage() == null
                ? Icon(Icons.person_outline_rounded,
                    size: radius * 0.8, color: AppColors.textOnDarkSecondary,)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 16, color: AppColors.navyDark,),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    if (currentFile != null) return FileImage(currentFile!);
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(networkUrl!);
    }
    return null;
  }
}

// Inline constant so we don't need a separate import just for quality value
abstract final class AppConstants {
  static const int _quality = 85;
}
