import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/presentation/widgets/listing_poster_card.dart';

/// Step 3 — Hero image upload + additional images + poster preview.
class StepPosterCreator extends StatelessWidget {
  const StepPosterCreator({
    super.key,
    required this.category,
    required this.location,
    required this.city,
    required this.price,
    required this.area,
    required this.brokerName,
    required this.heroImage,
    required this.additionalImages,
    required this.onHeroImagePicked,
    required this.onAdditionalImagePicked,
    required this.onRemoveAdditional,
    required this.posterKey,
  });

  final ListingCategory category;
  final String location;
  final String city;
  final String price;
  final String area;
  final String brokerName;
  final File? heroImage;
  final List<File> additionalImages;
  final ValueChanged<File> onHeroImagePicked;
  final ValueChanged<File> onAdditionalImagePicked;
  final ValueChanged<int> onRemoveAdditional;
  final GlobalKey posterKey;

  Future<void> _pickImage(BuildContext context,
      {required bool isHero,}) async {
    final source = await _sourceSheet(context);
    if (source == null) return;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.isPermanentlyDenied
                    ? 'Camera permission denied. Enable it in Settings.'
                    : 'Camera permission is required to take a photo.',
              ),
              action: status.isPermanentlyDenied
                  ? const SnackBarAction(
                      label: 'Settings',
                      onPressed: openAppSettings,
                    )
                  : null,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    } else {
      // Gallery: API 33+ uses system photo picker (no permission needed).
      // For API ≤ 32, request READ_EXTERNAL_STORAGE.
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.isPermanentlyDenied
                    ? 'Gallery permission denied. Enable it in Settings.'
                    : 'Gallery permission is required to pick a photo.',
              ),
              action: status.isPermanentlyDenied
                  ? const SnackBarAction(
                      label: 'Settings',
                      onPressed: openAppSettings,
                    )
                  : null,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // 75 quality @ 900 px ≈ 55 % smaller upload than 85/1080 with no visible quality loss
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 900,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (isHero) {
      onHeroImagePicked(file);
    } else {
      onAdditionalImagePicked(file);
    }
  }

  Future<ImageSource?> _sourceSheet(BuildContext context) =>
      showModalBottomSheet<ImageSource>(
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
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Your Poster',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a property photo — we\'ll auto-generate a shareable poster.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // ── Hero image picker ──────────────────────────────────────────
        const _SectionLabel('Hero Image', subtitle: 'Required · Main photo shown on poster'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImage(context, isHero: true),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: heroImage == null
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.border,
                width: heroImage == null ? 2 : 1,
                style: heroImage == null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: heroImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(heroImage!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _pickImage(context, isHero: true),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.navyDark.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: AppColors.white, size: 16,),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.gold, size: 26,),
                      ),
                      const SizedBox(height: 10),
                      Text('Tap to upload hero photo',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.gold,
                          ),),
                      const SizedBox(height: 4),
                      const Text('JPG or PNG · max 5MB',
                          style: AppTypography.bodySmall,),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Additional images ──────────────────────────────────────────
        _SectionLabel(
          'Additional Photos',
          subtitle: 'Optional · Up to 4 more (${additionalImages.length}/4)',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (additionalImages.length < 4)
                GestureDetector(
                  onTap: () => _pickImage(context, isHero: false),
                  child: Container(
                    width: 84,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.textSecondary,),
                  ),
                ),
              ...List.generate(additionalImages.length, (i) {
                return Stack(
                  children: [
                    Container(
                      width: 84,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(additionalImages[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 14,
                      child: GestureDetector(
                        onTap: () => onRemoveAdditional(i),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.white, size: 12,),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),

        // ── Poster preview ─────────────────────────────────────────────
        if (heroImage != null) ...[
          const SizedBox(height: 28),
          const _SectionLabel('Poster Preview',
              subtitle: 'This will be shared with your listing',),
          const SizedBox(height: 12),
          Center(
            child: RepaintBoundary(
              key: posterKey,
              child: ListingPosterCard(
                heroImageFile: heroImage!,
                category: category,
                location: location,
                city: city,
                price: price,
                area: area,
                brokerName: brokerName,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Auto-generated poster · editable in future updates',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white
                  : AppColors.textPrimary,
            ),),
        if (subtitle != null)
          Text(subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),),
      ],
    );
  }
}
