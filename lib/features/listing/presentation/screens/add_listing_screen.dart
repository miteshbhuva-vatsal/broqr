import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/features/listing/presentation/widgets/step_category_selector.dart';
import 'package:cpapp/features/listing/presentation/widgets/step_poster_creator.dart';
import 'package:cpapp/features/listing/presentation/widgets/step_property_details.dart';
import 'package:cpapp/shared/widgets/app_button.dart';
import 'package:cpapp/shared/widgets/loading_overlay.dart';

/// Multi-step Add Listing screen:
///   Step 0 → Category selection
///   Step 1 → Property details
///   Step 2 → Poster creation + publish
class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _pageController = PageController();
  final _detailsFormKey = GlobalKey<FormState>();
  final _posterKey = GlobalKey(); // for RepaintBoundary capture


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Poster capture ─────────────────────────────────────────────────────

  Future<List<int>?> _capturePoster() async {
    try {
      final boundary = _posterKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List().toList();
    } catch (_) {
      return null;
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _next() {
    final l = AppLocalizations.of(context);
    final state = ref.read(addListingProvider);
    if (state.step == 0 && !state.isStep1Valid) {
      _showSnack(l.pleaseSelectCategory);
      return;
    }
    if (state.step == 1) {
      if (!_detailsFormKey.currentState!.validate() || state.city.isEmpty) {
        if (state.city.isEmpty) _showSnack(l.pleaseSelectCity);
        return;
      }
    }
    ref.read(addListingProvider.notifier).nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (ref.read(addListingProvider).step == 0) {
      context.pop();
      return;
    }
    ref.read(addListingProvider.notifier).prevStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _publish() async {
    final l = AppLocalizations.of(context);
    final state = ref.read(addListingProvider);
    if (!state.isStep3Valid) {
      _showSnack(l.pleaseUploadHeroPhoto);
      return;
    }
    // Only capture poster when a new hero image file was picked
    final posterBytes = state.heroImage != null ? await _capturePoster() : null;
    await ref.read(addListingProvider.notifier).publish(
          posterPngBytes: posterBytes,
        );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyMid,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formState = ref.watch(addListingProvider);
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    // Navigate away on success, show snack on error
    ref.listen<AddListingFormState>(addListingProvider, (_, next) {
      if (next.publishedListing != null) {
        ref.read(addListingProvider.notifier).reset();
        context.go(Routes.feed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).listingPublishedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.errorMessage != null) {
        _showSnack(next.errorMessage!);
        ref.read(addListingProvider.notifier).clearError();
      }
    });

    final l = AppLocalizations.of(context);
    final isEditMode = formState.isEditMode;
    final steps = [l.stepCategory, l.stepDetails, l.stepPoster];
    final isLastStep = formState.step == 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: LoadingOverlay(
        isLoading: formState.isSubmitting,
        message: formState.uploadProgress != null
            ? '${l.uploadingPhotos} ${(formState.uploadProgress! * 100).round()}%'
            : l.publishingListing,
        progress: formState.uploadProgress,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.navyDark : AppColors.offWhite,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.navyDark : AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: _back,
            ),
            title: Text(
              isEditMode ? 'Edit Listing' : l.newListing,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _StepIndicator(
                steps: steps,
                currentStep: formState.step,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Page view ───────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Step 0 — Category
                    _StepPage(
                      child: StepCategorySelector(
                        selected: formState.category,
                        onSelect: ref
                            .read(addListingProvider.notifier)
                            .selectCategory,
                      ),
                    ),

                    // Step 1 — Details
                    _StepPage(
                      child: StepPropertyDetails(
                        formKey: _detailsFormKey,
                        category: formState.category ?? ListingCategory.barterDeal,
                        propertyType: formState.propertyType,
                        title: formState.title,
                        city: formState.city,
                        location: formState.location,
                        area: formState.area,
                        price: formState.price,
                        originalPrice: formState.originalPrice,
                        brokerage: formState.brokerage,
                        instagramUrl: formState.instagramUrl,
                        pdfFile: formState.pdfFile,
                        description: formState.description,
                        onPropertyTypeChanged: ref
                            .read(addListingProvider.notifier)
                            .selectPropertyType,
                        onTitleChanged: ref
                            .read(addListingProvider.notifier)
                            .updateTitle,
                        onCityChanged: ref
                            .read(addListingProvider.notifier)
                            .updateCity,
                        onLocationChanged: ref
                            .read(addListingProvider.notifier)
                            .updateLocation,
                        onAreaChanged: ref
                            .read(addListingProvider.notifier)
                            .updateArea,
                        areaUnit: formState.areaUnit,
                        onAreaUnitChanged: ref
                            .read(addListingProvider.notifier)
                            .updateAreaUnit,
                        onPriceChanged: ref
                            .read(addListingProvider.notifier)
                            .updatePrice,
                        onOriginalPriceChanged: ref
                            .read(addListingProvider.notifier)
                            .updateOriginalPrice,
                        onBrokerageChanged: ref
                            .read(addListingProvider.notifier)
                            .updateBrokerage,
                        onInstagramUrlChanged: ref
                            .read(addListingProvider.notifier)
                            .updateInstagramUrl,
                        onPdfFileChanged: ref
                            .read(addListingProvider.notifier)
                            .setPdfFile,
                        onPdfFileCleared: ref
                            .read(addListingProvider.notifier)
                            .clearPdfFile,
                        onDescriptionChanged: ref
                            .read(addListingProvider.notifier)
                            .updateDescription,
                        visibility: formState.visibility,
                        onVisibilityChanged: ref
                            .read(addListingProvider.notifier)
                            .updateVisibility,
                      ),
                    ),

                    // Step 2 — Poster
                    _StepPage(
                      child: StepPosterCreator(
                        posterKey: _posterKey,
                        category: formState.category ?? ListingCategory.barterDeal,
                        location: formState.location,
                        city: formState.city,
                        price: formState.price,
                        area: formState.area,
                        brokerName: user?.name ?? '',
                        heroImage: formState.heroImage,
                        additionalImages: formState.additionalImages,
                        onHeroImagePicked: ref
                            .read(addListingProvider.notifier)
                            .setHeroImage,
                        onAdditionalImagesPicked: ref
                            .read(addListingProvider.notifier)
                            .addAdditionalImages,
                        onRemoveAdditional: ref
                            .read(addListingProvider.notifier)
                            .removeAdditionalImage,
                        existingHeroImageUrl: formState.existingHeroImageUrl,
                        existingAdditionalImageUrls:
                            formState.existingAdditionalImageUrls,
                        onRemoveExistingAdditional: ref
                            .read(addListingProvider.notifier)
                            .removeExistingAdditionalImage,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom action bar ────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyMid : AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: isLastStep
                        ? (isEditMode ? 'Update Listing' : l.publishListing)
                        : l.nextArrow,
                    onPressed: formState.isSubmitting
                        ? null
                        : (isLastStep ? _publish : _next),
                    isLoading: formState.isSubmitting,
                    variant: isLastStep
                        ? AppButtonVariant.primary
                        : AppButtonVariant.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.currentStep,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isCompleted = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.gold : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = currentStep > stepIndex;
          final isCurrent = currentStep == stepIndex;

          return _StepDot(
            label: steps[stepIndex],
            index: stepIndex + 1,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isDark: isDark,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.isDark,
  });

  final String label;
  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted || isCurrent ? AppColors.gold : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.gold
                : (isCurrent
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    color: AppColors.navyDark, size: 14,)
                : Text(
                    '$index',
                    style: AppTypography.labelSmall.copyWith(
                      color: isCurrent ? AppColors.gold : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isCurrent || isCompleted
                ? AppColors.gold
                : AppColors.textSecondary,
            fontWeight:
                isCurrent ? FontWeight.w700 : FontWeight.w400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Scrollable step page wrapper ────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  const _StepPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: child,
    );
  }
}
