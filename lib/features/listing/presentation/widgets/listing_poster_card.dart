import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';

/// Auto-generated poster card — Meta/Instagram sponsored-ad style.
/// Wrap in [RepaintBoundary] with a [GlobalKey] to capture as PNG.
class ListingPosterCard extends StatelessWidget {
  const ListingPosterCard({
    super.key,
    required this.heroImageFile,
    required this.category,
    required this.location,
    required this.city,
    required this.price,
    required this.area,
    required this.brokerName,
    this.brokerPhotoUrl,
    this.width = 360,
    this.height = 480,
  });

  final File heroImageFile;
  final ListingCategory category;
  final String location;
  final String city;
  final String price;
  final String area;
  final String brokerName;
  final String? brokerPhotoUrl;
  final double width;
  final double height;

  String get _priceLabel {
    final v = double.tryParse(price.replaceAll(',', '')) ?? 0;
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    return '₹$price';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Hero image ───────────────────────────────────────────────
            Image.file(heroImageFile, fit: BoxFit.cover),

            // ── Gradient overlay ─────────────────────────────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 1.0],
                  colors: [
                    Color(0x55000000),
                    Colors.transparent,
                    Color(0xEE0A1628),
                  ],
                ),
              ),
            ),

            // ── Category badge ───────────────────────────────────────────
            Positioned(
              top: 14,
              left: 14,
              child: _CategoryBadge(category: category),
            ),

            // ── CPApp watermark ──────────────────────────────────────────
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CPApp',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // ── Bottom info panel ────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Price
                    Text(
                      _priceLabel,
                      style: AppTypography.priceTag.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 2),
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.white, size: 13,),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '$location, $city',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          area.isEmpty ? '' : '$area sq.ft',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0x33FFFFFF), height: 1),
                    const SizedBox(height: 10),

                    // Broker row + CTA
                    Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.navyLight,
                          child: Text(
                            brokerName.isNotEmpty
                                ? brokerName[0].toUpperCase()
                                : 'B',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                brokerName,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Verified Broker · CPApp',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textOnDarkSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // CTA button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8,),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Inquire Now',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final ListingCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
