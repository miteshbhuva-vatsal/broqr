import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';
import 'package:cpapp/features/ask/presentation/providers/ask_providers.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

enum _PostType { text, image }

/// Each entry is [startHex, endHex] for a gradient, or null for no background.
const List<List<String>?> _kGradients = [
  null,
  ['#1877F2', '#9B59B6'],
  ['#E41E3F', '#F18500'],
  ['#42B72A', '#00B4D8'],
  ['#F18500', '#FFD93D'],
  ['#7B61FF', '#E41E3F'],
  ['#1A1A2E', '#163366'],
  ['#00B4D8', '#42B72A'],
  ['#FF6B6B', '#FF9A9A'],
  ['#2C7873', '#52B788'],
];

/// Encodes a gradient selection into the storage format '#start,#end'.
String? _encodeGradient(List<String>? g) =>
    g == null ? null : '${g[0]},${g[1]}';

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

bool _isDark(Color c) {
  final r = (c.r * 255.0).round();
  final g = (c.g * 255.0).round();
  final b = (c.b * 255.0).round();
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.55;
}

LinearGradient? _gradientFromEncoded(String? encoded) {
  if (encoded == null) return null;
  final parts = encoded.split(',');
  if (parts.length < 2) {
    // Legacy solid colour — wrap as same-colour gradient.
    final c = _hexColor(parts[0]);
    return LinearGradient(colors: [c, c]);
  }
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_hexColor(parts[0]), _hexColor(parts[1])],
  );
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class AskCreateSheet extends ConsumerStatefulWidget {
  const AskCreateSheet({super.key, this.initialPost});

  /// When non-null the sheet opens in edit mode pre-filled with this post.
  final AskPost? initialPost;

  @override
  ConsumerState<AskCreateSheet> createState() => _AskCreateSheetState();
}

class _AskCreateSheetState extends ConsumerState<AskCreateSheet> {
  final _textController = TextEditingController();
  final _captionController = TextEditingController();
  File? _pickedImage;
  Uint8List? _pickedImageBytes;
  double? _imageAspectRatio;
  bool _posting = false;

  _PostType _type = _PostType.text;

  // Text-mode formatting
  bool _isBold = false;
  TextAlign _textAlign = TextAlign.left;

  /// Encoded gradient: '#start,#end' or null.
  String? _bgEncoded;

  /// Font size key: 'regular' | 'medium' | 'large'.
  String _fontSize = 'regular';

  /// Existing image URL when editing an image post (no new file yet chosen).
  String? _existingImageUrl;

  /// Set to true when the user explicitly removes the image while editing.
  bool _clearImage = false;

  bool get _isEditing => widget.initialPost != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPost;
    if (p != null) {
      if (p.hasImage) {
        _type = _PostType.image;
        _existingImageUrl = p.imageUrl;
        _captionController.text = p.text;
        _imageAspectRatio = p.imageAspectRatio;
      } else {
        _type = _PostType.text;
        _textController.text = p.text;
      }
      _isBold = p.isBold;
      _bgEncoded = p.backgroundColorHex;
      _fontSize = p.fontSize;
      _textAlign = switch (p.textAlign) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        _ => TextAlign.left,
      };
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  String get _textAlignValue => switch (_textAlign) {
        TextAlign.center => 'center',
        TextAlign.right => 'right',
        _ => 'left',
      };

  void _cycleAlign() => setState(() {
        _textAlign = switch (_textAlign) {
          TextAlign.left => TextAlign.center,
          TextAlign.center => TextAlign.right,
          _ => TextAlign.left,
        };
      });

  IconData get _alignIcon => switch (_textAlign) {
        TextAlign.center => Icons.format_align_center_rounded,
        TextAlign.right => Icons.format_align_right_rounded,
        _ => Icons.format_align_left_rounded,
      };

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1350,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ratio = await _computeAspectRatio(bytes);
    setState(() {
      _pickedImage = File(picked.path);
      _pickedImageBytes = bytes;
      _imageAspectRatio = ratio;
    });
  }

  Future<double?> _computeAspectRatio(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      frame.image.dispose();
      return h > 0 ? w / h : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final isImageMode = _type == _PostType.image;
    final text = isImageMode
        ? _captionController.text.trim()
        : _textController.text.trim();

    if (!isImageMode && text.isEmpty) return;
    // In image mode: need either a new file, an existing URL, or at least a caption if keeping image.
    if (isImageMode && _pickedImage == null && _existingImageUrl == null) return;

    setState(() => _posting = true);

    bool ok;
    if (_isEditing) {
      ok = await ref.read(askFeedProvider.notifier).updatePost(
            post: widget.initialPost!,
            text: text,
            newImageFile: _pickedImage,
            imageAspectRatio: isImageMode ? _imageAspectRatio : null,
            clearImage: _clearImage,
            isBold: isImageMode ? false : _isBold,
            textAlign: isImageMode ? 'left' : _textAlignValue,
            backgroundColorHex: isImageMode ? null : _bgEncoded,
            fontSize: isImageMode ? 'regular' : _fontSize,
          );
    } else {
      ok = await ref.read(askFeedProvider.notifier).createPost(
            text: text,
            imageFile: isImageMode ? _pickedImage : null,
            imageAspectRatio: isImageMode ? _imageAspectRatio : null,
            isBold: isImageMode ? false : _isBold,
            textAlign: isImageMode ? 'left' : _textAlignValue,
            backgroundColorHex: isImageMode ? null : _bgEncoded,
            fontSize: isImageMode ? 'regular' : _fontSize,
          );
    }

    if (!mounted) return;
    setState(() => _posting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? l.askEditFailed : l.askPostFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    final isImageMode = _type == _PostType.image;
    final canPost = !_posting &&
        (isImageMode
            ? (_pickedImage != null || _existingImageUrl != null)
            : _textController.text.trim().isNotEmpty);

    final gradient = _gradientFromEncoded(_bgEncoded);
    final previewColor = gradient?.colors.first;
    final textOnBg = previewColor != null
        ? (_isDark(previewColor) ? Colors.white : AppColors.navyDark)
        : (isDark ? AppColors.white : AppColors.navyDark);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
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
              // ── Mode toggle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeChip(
                        icon: Icons.text_fields_rounded,
                        label: 'Text',
                        selected: _type == _PostType.text,
                        isDark: isDark,
                        onTap: () => setState(() => _type = _PostType.text),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ModeChip(
                        icon: Icons.image_rounded,
                        label: 'Image',
                        selected: _type == _PostType.image,
                        isDark: isDark,
                        onTap: () => setState(() => _type = _PostType.image),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 16),
              // ── Post button row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: isDark ? AppColors.white : AppColors.navyDark,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canPost ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        disabledBackgroundColor:
                            AppColors.gold.withValues(alpha: 0.4),
                        foregroundColor: AppColors.navyDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _posting
                            ? (_isEditing ? l.askSaving : l.askPosting)
                            : (_isEditing ? l.askSave : l.askPost),
                        style:
                            const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 8),
              // ── Content area ─────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: isImageMode
                      ? _ImageBody(
                          isDark: isDark,
                          pickedImage: _pickedImage,
                          pickedImageBytes: _pickedImageBytes,
                          existingImageUrl: _existingImageUrl,
                          imageAspectRatio: _imageAspectRatio,
                          captionController: _captionController,
                          posting: _posting,
                          onPickImage: _pickImage,
                          onRemoveImage: () => setState(() {
                            _pickedImage = null;
                            _pickedImageBytes = null;
                            _existingImageUrl = null;
                            _imageAspectRatio = null;
                            _clearImage = true;
                          }),
                        )
                      : _TextBody(
                          isDark: isDark,
                          controller: _textController,
                          gradient: gradient,
                          textOnBg: textOnBg,
                          textAlign: _textAlign,
                          isBold: _isBold,
                          fontSize: _fontSize,
                          selectedGradient: _bgEncoded?.split(','),
                          alignIcon: _alignIcon,
                          posting: _posting,
                          onChanged: () => setState(() {}),
                          onBoldTap: () =>
                              setState(() => _isBold = !_isBold),
                          onAlignTap: _cycleAlign,
                          onSelectGradient: (g) => setState(
                            () => _bgEncoded = _encodeGradient(g),
                          ),
                          onFontSizeChanged: (s) =>
                              setState(() => _fontSize = s),
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

// ── Mode chip ─────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : (isDark ? AppColors.navyMid : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color:
                    selected ? AppColors.gold : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text-mode body ────────────────────────────────────────────────────────────

class _TextBody extends StatelessWidget {
  const _TextBody({
    required this.isDark,
    required this.controller,
    required this.gradient,
    required this.textOnBg,
    required this.textAlign,
    required this.isBold,
    required this.fontSize,
    required this.selectedGradient,
    required this.alignIcon,
    required this.posting,
    required this.onChanged,
    required this.onBoldTap,
    required this.onAlignTap,
    required this.onSelectGradient,
    required this.onFontSizeChanged,
  });

  final bool isDark;
  final TextEditingController controller;
  final LinearGradient? gradient;
  final Color textOnBg;
  final TextAlign textAlign;
  final bool isBold;
  final String fontSize;

  /// The currently selected gradient as [startHex, endHex], or null.
  final List<String>? selectedGradient;
  final IconData alignIcon;
  final bool posting;
  final VoidCallback onChanged;
  final VoidCallback onBoldTap;
  final VoidCallback onAlignTap;
  final void Function(List<String>?) onSelectGradient;
  final void Function(String) onFontSizeChanged;

  double get _fontPx => switch (fontSize) {
        'large' => 24,
        'medium' => 18,
        _ => 14,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = isDark ? AppColors.white : AppColors.navyDark;
    final activeBg = isDark ? AppColors.navyMid : AppColors.surfaceLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Compose field ───────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints:
              BoxConstraints(minHeight: gradient != null ? 140 : 0),
          padding: gradient != null
              ? const EdgeInsets.all(16)
              : EdgeInsets.zero,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            minLines: gradient != null ? 3 : 4,
            textAlign: textAlign,
            onChanged: (_) => onChanged(),
            cursorColor: textOnBg,
            style: TextStyle(
              color: textOnBg,
              fontSize: _fontPx,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.normal,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: l.askComposeHint,
              hintStyle: TextStyle(
                fontSize: _fontPx,
                color: gradient != null
                    ? textOnBg.withValues(alpha: 0.55)
                    : AppColors.textHint,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Formatting toolbar ──────────────────────────────────────────
        Row(
          children: [
            // Bold
            _ToolBtn(
              active: isBold,
              activeBg: activeBg,
              onTap: onBoldTap,
              child: Text(
                'B',
                style: TextStyle(
                  color: isBold ? AppColors.gold : fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Alignment
            _ToolBtn(
              active: alignIcon != Icons.format_align_left_rounded,
              activeBg: activeBg,
              onTap: onAlignTap,
              child: Icon(alignIcon, size: 20, color: fg),
            ),
            const SizedBox(width: 10),
            // Font size selector
            _FontSizeSelector(
              selected: fontSize,
              isDark: isDark,
              onSelect: onFontSizeChanged,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Gradient chips ──────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kGradients.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = _kGradients[i];
              final isSelected = selectedGradient == null
                  ? g == null
                  : (g != null &&
                      g[0] == selectedGradient![0] &&
                      g[1] == selectedGradient![1]);
              return _GradientChip(
                gradient: g,
                selected: isSelected,
                onTap: () => onSelectGradient(g),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Image-mode body ───────────────────────────────────────────────────────────

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.isDark,
    required this.pickedImage,
    required this.captionController,
    required this.posting,
    required this.onPickImage,
    required this.onRemoveImage,
    this.pickedImageBytes,
    this.existingImageUrl,
    this.imageAspectRatio,
  });

  final bool isDark;
  final File? pickedImage;
  final Uint8List? pickedImageBytes;
  final String? existingImageUrl;
  final double? imageAspectRatio;
  final TextEditingController captionController;
  final bool posting;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textColor = isDark ? AppColors.white : AppColors.navyDark;

    return Column(
      children: [
        if (pickedImage == null && existingImageUrl == null)
          GestureDetector(
            onTap: posting ? null : onPickImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.navyMid : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 52,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.askAddPhoto,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose from gallery',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: imageAspectRatio ?? (4 / 5),
                  child: pickedImageBytes != null
                      ? Image.memory(pickedImageBytes!, fit: BoxFit.cover, gaplessPlayback: true)
                      : CachedNetworkImage(
                          imageUrl: existingImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint,),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onRemoveImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: posting ? null : onPickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.askChangePhoto,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        TextField(
          controller: captionController,
          maxLines: 3,
          minLines: 1,
          style: AppTypography.bodyMedium.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: 'Add a caption… (optional)',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color:
                    isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Font size selector ────────────────────────────────────────────────────────

class _FontSizeSelector extends StatelessWidget {
  const _FontSizeSelector({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final String selected;
  final bool isDark;
  final void Function(String) onSelect;

  static const _sizes = [
    ('regular', 'Aa', 13.0),
    ('medium', 'Aa', 15.0),
    ('large', 'Aa', 18.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _sizes.map((item) {
          final (key, label, size) = item;
          final isActive = selected == key;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: size,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? AppColors.navyDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared toolbar widgets ────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.child,
    required this.active,
    required this.activeBg,
    required this.onTap,
  });

  final Widget child;
  final bool active;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

// ── Gradient chip ─────────────────────────────────────────────────────────────

class _GradientChip extends StatelessWidget {
  const _GradientChip({
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final List<String>? gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = gradient == null
        ? null
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hexColor(gradient![0]),
              _hexColor(gradient![1]),
            ],
          );

    final borderColor = gradient == null
        ? (isDark ? AppColors.borderDark : AppColors.border)
        : _hexColor(gradient![0]);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: grad,
          color: gradient == null
              ? (isDark ? AppColors.surfaceDark : AppColors.white)
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.gold : borderColor,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 16,
                color: gradient != null
                    ? (_isDark(_hexColor(gradient![0]))
                        ? Colors.white
                        : AppColors.navyDark)
                    : AppColors.navyDark,
              )
            : (gradient == null
                ? Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  )
                : null),
      ),
    );
  }
}
