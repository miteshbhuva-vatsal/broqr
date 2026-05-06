import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/presentation/widgets/listing_poster_card.dart';

const _kMaxAdditional = 9;

/// Step 3 — Hero image upload + additional images (up to 9) + poster preview.
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
    required this.onAdditionalImagesPicked,
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
  final ValueChanged<List<File>> onAdditionalImagesPicked;
  final ValueChanged<int> onRemoveAdditional;
  final GlobalKey posterKey;

  Future<void> _pickHero(BuildContext context) async {
    final source = await _sourceSheet(context);
    if (source == null) return;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (context.mounted) _showPermissionSnack(context, 'Camera');
        return;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        if (context.mounted) _showPermissionSnack(context, 'Gallery');
        return;
      }
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 1920,
    );
    if (picked == null) return;
    onHeroImagePicked(File(picked.path));
  }

  Future<void> _pickAdditional(BuildContext context) async {
    final remaining = _kMaxAdditional - additionalImages.length;
    if (remaining <= 0) return;

    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      if (context.mounted) _showPermissionSnack(context, 'Gallery');
      return;
    }

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 100,
      maxWidth: 1920,
      limit: remaining,
    );
    if (picked.isEmpty) return;
    onAdditionalImagesPicked(picked.map((x) => File(x.path)).toList());
  }

  void _showPermissionSnack(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type permission denied. Enable it in Settings.'),
        action: const SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final remaining = _kMaxAdditional - additionalImages.length;

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
          'Upload photos — we\'ll auto-generate a shareable poster.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // ── Hero image picker ──────────────────────────────────────────
        const _SectionLabel('Hero Image', subtitle: 'Required · Main photo shown on poster'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickHero(context),
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
                            onTap: () => _pickHero(context),
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
          subtitle: 'Optional · ${additionalImages.length}/$_kMaxAdditional · select multiple at once',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (remaining > 0)
                GestureDetector(
                  onTap: () => _pickAdditional(context),
                  child: Container(
                    width: 84,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.textSecondary, size: 22,),
                        const SizedBox(height: 4),
                        Text(
                          '+$remaining',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
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
