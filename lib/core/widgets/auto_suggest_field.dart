// core/widgets/auto_suggest_field.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../debug/app_logger.dart';
import '../theme/app_dimensions.dart';

/// SPoT: Auto-complete widget - reusable across app
class AutoSuggestField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final Future<List<T>> Function(String) searchFn;
  final String Function(T) displayFn;
  final Widget Function(T) itemBuilder;
  final ValueChanged<T> onSelected;
  final String? Function(T?)? validator;
  final TextEditingController? controller;
  final bool enabled;

  const AutoSuggestField({
    super.key,
    required this.label,
    required this.hint,
    required this.searchFn,
    required this.displayFn,
    required this.itemBuilder,
    required this.onSelected,
    this.validator,
    this.controller,
    this.enabled = true,
  });

  @override
  State<AutoSuggestField<T>> createState() => _AutoSuggestFieldState<T>();
}

class _AutoSuggestFieldState<T> extends State<AutoSuggestField<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<T> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  T? _selectedItem;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _suggestions = []);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () async {
      if (value.isEmpty) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      try {
        final results = await widget.searchFn(value);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (e, stackTrace) {
        AppLogger.error('AutoSuggest search failed: $e', stackTrace);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: _onChanged,
          validator: (value) => widget.validator?.call(_selectedItem),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppDimensions.md),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
        ),
        if (_suggestions.isNotEmpty && _focusNode.hasFocus)
          _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Card(
      elevation: AppDimensions.elevationLg,
      margin: const EdgeInsets.only(top: AppDimensions.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final item = _suggestions[index];
            return ListTile(
              title: widget.itemBuilder(item),
              dense: true,
              onTap: () {
                setState(() {
                  _selectedItem = item;
                  _suggestions = [];
                });
                _controller.text = widget.displayFn(item);
                widget.onSelected(item);
                _focusNode.unfocus();
              },
            );
          },
        ),
      ),
    );
  }
}
