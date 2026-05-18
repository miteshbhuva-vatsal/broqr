import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/shared/providers/locality_provider.dart';

// ── Single-field locality autocomplete ───────────────────────────────────────
//
// Drop-in replacement for a TextFormField. Shows a suggestion overlay while
// the user types; tapping a suggestion fills the field and saves usage.
// If the typed text doesn't match any locality the overlay shows an
// "Add '<text>'" row that creates the entry in Firestore on tap.

class LocalityAutocomplete extends ConsumerStatefulWidget {
  const LocalityAutocomplete({
    required this.controller,
    required this.hint,
    required this.city,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String city;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  @override
  ConsumerState<LocalityAutocomplete> createState() =>
      _LocalityAutocompleteState();
}

class _LocalityAutocompleteState extends ConsumerState<LocalityAutocomplete> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  final _focusNode = FocusNode();
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _buildOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    widget.onChanged?.call(widget.controller.text);
    if (_focusNode.hasFocus) _rebuildOverlay();
  }

  List<String> _filter(List<String> all) {
    final q = widget.controller.text.trim().toLowerCase();
    if (q.isEmpty) return all.take(8).toList();
    return all
        .where((l) => l.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  void _select(String name) {
    widget.controller.text = name;
    widget.controller.selection =
        TextSelection.collapsed(offset: name.length);
    widget.onChanged?.call(name);
    addLocality(name, widget.city);
    _focusNode.unfocus();
  }

  Future<void> _addNew() async {
    final name = widget.controller.text.trim();
    if (name.isEmpty) return;
    await addLocality(name, widget.city);
    widget.onChanged?.call(name);
    _focusNode.unfocus();
  }

  void _buildOverlay() {
    _removeOverlay();
    setState(() => _showOverlay = true);
    _overlay = OverlayEntry(builder: (_) => Consumer(
      builder: (_, cRef, __) => _OverlayWidget(
        link: _layerLink,
        query: widget.controller.text,
        localitiesAsync: cRef.watch(localitiesProvider(widget.city)),
        filter: _filter,
        onSelect: _select,
        onAddNew: _addNew,
        onDismiss: _focusNode.unfocus,
      ),
    ),);
    Overlay.of(context).insert(_overlay!);
  }

  void _rebuildOverlay() {
    _overlay?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localitiesProvider(widget.city));
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        textCapitalization: TextCapitalization.words,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
          suffixIcon: _showOverlay
              ? const Icon(Icons.expand_less_rounded,
                  size: 18, color: AppColors.textHint,)
              : const Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textHint,),
        ),
      ),
    );
  }
}

// ── Multi-chip locality picker ────────────────────────────────────────────────
//
// Shows a text input with autocomplete + a row of dismissible chips for the
// currently selected localities. Used for "Preferred Working Areas" on the
// seller edit profile and profile setup.

class LocalityMultiPicker extends ConsumerStatefulWidget {
  const LocalityMultiPicker({
    required this.selected,
    required this.onChanged,
    required this.city,
    this.hint = 'e.g. Bandra, Powai, Whitefield…',
    super.key,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String city;
  final String hint;

  @override
  ConsumerState<LocalityMultiPicker> createState() =>
      _LocalityMultiPickerState();
}

class _LocalityMultiPickerState extends ConsumerState<LocalityMultiPicker> {
  final _ctrl = TextEditingController();
  final _layerLink = LayerLink();
  final _focusNode = FocusNode();
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _ctrl.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ctrl.removeListener(_onTextChange);
    _focusNode.dispose();
    _ctrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _buildOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() => _overlay?.markNeedsBuild();

  List<String> _filter(List<String> all) {
    final q = _ctrl.text.trim().toLowerCase();
    final notYetSelected =
        all.where((l) => !widget.selected.contains(l)).toList();
    if (q.isEmpty) return notYetSelected.take(8).toList();
    return notYetSelected
        .where((l) => l.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  void _select(String name) {
    if (widget.selected.contains(name)) return;
    final next = [...widget.selected, name];
    widget.onChanged(next);
    addLocality(name, widget.city);
    _ctrl.clear();
    _overlay?.markNeedsBuild();
  }

  Future<void> _addNew() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || widget.selected.contains(name)) return;
    await addLocality(name, widget.city);
    final next = [...widget.selected, name];
    widget.onChanged(next);
    _ctrl.clear();
    _overlay?.markNeedsBuild();
  }

  void _remove(String name) {
    widget.onChanged(widget.selected.where((s) => s != name).toList());
  }

  void _buildOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => Consumer(
      builder: (_, cRef, __) => _OverlayWidget(
        link: _layerLink,
        query: _ctrl.text,
        localitiesAsync: cRef.watch(localitiesProvider(widget.city)),
        filter: _filter,
        onSelect: _select,
        onAddNew: _addNew,
        onDismiss: _focusNode.unfocus,
      ),
    ),);
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localitiesProvider(widget.city));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chips for already-selected localities ──────────────────────────
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selected.map((area) => _Chip(
              label: area,
              isDark: isDark,
              onRemove: () => _remove(area),
            ),).toList(),
          ),
          const SizedBox(height: 10),
        ],

        // ── Autocomplete input ─────────────────────────────────────────────
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addNew(),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.add_location_alt_outlined, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: _addNew,
                      child: const Icon(Icons.add_circle_outline_rounded,
                          size: 20, color: AppColors.gold,),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared overlay widget ─────────────────────────────────────────────────────

class _OverlayWidget extends StatelessWidget {
  const _OverlayWidget({
    required this.link,
    required this.query,
    required this.localitiesAsync,
    required this.filter,
    required this.onSelect,
    required this.onAddNew,
    required this.onDismiss,
  });

  final LayerLink link;
  final String query;
  final AsyncValue<List<String>> localitiesAsync;
  final List<String> Function(List<String>) filter;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddNew;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = localitiesAsync.valueOrNull ?? [];
    final suggestions = filter(all);
    final trimmed = query.trim();
    final exactMatch = all.any(
      (l) => l.toLowerCase() == trimmed.toLowerCase(),
    );
    final showAdd = trimmed.isNotEmpty && !exactMatch;

    if (suggestions.isEmpty && !showAdd) return const SizedBox.shrink();

    return Stack(
      children: [
        // Full-screen barrier — tapping outside the dropdown dismisses it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
          ),
        ),
        Positioned.fill(
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, 52),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    children: [
                      ...suggestions.map((s) => _SuggestionTile(
                        label: s,
                        query: trimmed,
                        icon: Icons.location_on_outlined,
                        onTap: () => onSelect(s),
                        isDark: isDark,
                      ),),
                      if (showAdd)
                        _SuggestionTile(
                          label: 'Add "$trimmed"',
                          query: '',
                          icon: Icons.add_location_alt_outlined,
                          onTap: onAddNew,
                          isDark: isDark,
                          isAdd: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.label,
    required this.query,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isAdd = false,
  });

  final String label;
  final String query;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isAdd ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isAdd
                  ? Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : _HighlightedText(text: label, query: query, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

// Highlights matching query substring in gold.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.isDark,
  });
  final String text;
  final String query;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.white : AppColors.textPrimary,
        ),
      );
    }
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx < 0) {
      return Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.white : AppColors.textPrimary,
        ),
      );
    }
    return Text.rich(TextSpan(children: [
      if (idx > 0)
        TextSpan(
          text: text.substring(0, idx),
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (idx + query.length < text.length)
        TextSpan(
          text: text.substring(idx + query.length),
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
    ],),);
  }
}

// ── Dismissible chip ──────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isDark, required this.onRemove});
  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.white : AppColors.navyDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
