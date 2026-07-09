import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

class AppSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;

  const AppSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.controller,
    this.readOnly = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasController = false;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _hasController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final showClear = _controller.text.isNotEmpty;
    if (showClear != _showClear) {
      setState(() => _showClear = showClear);
    }
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_hasController) {
        _controller.removeListener(_onTextChanged);
      }
      _hasController = widget.controller != null;
      _controller = widget.controller ?? TextEditingController();
      if (!_hasController) {
        _controller.addListener(_onTextChanged);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_hasController) {
      _controller.removeListener(_onTextChanged);
    }
    if (!_hasController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _clearText() {
    if (!widget.readOnly) {
      _controller.clear();
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.space56),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        readOnly: widget.readOnly,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          widget.onChanged?.call(value);
          _focusNode.unfocus();
        },
        onTapOutside: (_) => _focusNode.unfocus(),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: AppFontSizes.md,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search...',
          hintStyle: const TextStyle(
            fontSize: AppFontSizes.md,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: AppFontSizes.iconMd,
          ),
          suffixIcon: _showClear && !widget.readOnly
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: AppFontSizes.iconSm,
                  ),
                  onPressed: _clearText,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space7,
            vertical: AppSpacing.space5,
          ),
        ),
      ),
    );
  }
}
