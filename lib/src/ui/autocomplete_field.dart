import 'package:flutter/material.dart';

import '../api/locationiq_autocomplete_api.dart';
import '../api/models.dart';
import 'controller.dart';
import 'package:flutter/services.dart';

typedef OptionBuilder =
    Widget Function(BuildContext context, LocationIQAutocompleteResult option);

class LocationIQAutocompleteField extends StatefulWidget {
  const LocationIQAutocompleteField({
    super.key,
    this.api,
    this.controller,
    required this.onSelected,
    this.request = const LocationIQAutocompleteRequest(),
    this.textController,
    this.focusNode,
    this.decoration = const InputDecoration(hintText: 'Search location…'),
    this.minChars = 3,
    this.debounce = const Duration(milliseconds: 300),
    this.maxOptionsHeight = 280,
    this.optionBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.rateLimitedBuilder,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  }) : assert(
         api != null || controller != null,
         'Provide either api or controller.',
       );

  /// Provide [api] if you want this widget to create and own its controller.
  final LocationIQAutocompleteApi? api;

  /// Provide a controller if you want to manage/reuse it outside.
  final LocationIQAutocompleteController? controller;

  final LocationIQAutocompleteRequest request;

  final ValueChanged<LocationIQAutocompleteResult> onSelected;

  final TextEditingController? textController;
  final FocusNode? focusNode;

  final InputDecoration decoration;
  final int minChars;
  final Duration debounce;

  final double maxOptionsHeight;

  final OptionBuilder? optionBuilder;

  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context, DateTime? cooldownUntil)?
  rateLimitedBuilder;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;

  final bool autofocus;
  final bool enabled;
  final bool readOnly;

  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<LocationIQAutocompleteField> createState() =>
      _LocationIQAutocompleteFieldState();
}

class _LocationIQAutocompleteFieldState
    extends State<LocationIQAutocompleteField> {
  late final TextEditingController _textController =
      widget.textController ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  LocationIQAutocompleteController? _ownedController;
  LocationIQAutocompleteController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _ownedController = LocationIQAutocompleteController(
        api: widget.api!,
        request: widget.request,
        minChars: widget.minChars,
        debounce: widget.debounce,
      );
    } else {
      widget.controller!.request = widget.request;
    }

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _controller.snapshot.addListener(_onSnapshotChanged);
  }

  @override
  void didUpdateWidget(covariant LocationIQAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.request = widget.request;
  }

  @override
  void dispose() {
    _removeOverlay();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.snapshot.removeListener(_onSnapshotChanged);

    if (widget.textController == null) _textController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    _controller.setQuery(text);
    widget.onChanged?.call(text);
    setState(() {});
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else {
      _showOrUpdateOverlay();
    }
  }

  void _onSnapshotChanged() {
    if (_focusNode.hasFocus) {
      _showOrUpdateOverlay();
    }
  }

  void _showOrUpdateOverlay() {
    if (!_focusNode.hasFocus) return;

    final snap = _controller.snapshot.value;
    final shouldShow = switch (snap.status) {
      LocationIQAutocompleteStatus.loading => true,
      LocationIQAutocompleteStatus.success => snap.items.isNotEmpty,
      LocationIQAutocompleteStatus.empty => true,
      LocationIQAutocompleteStatus.error => true,
      LocationIQAutocompleteStatus.rateLimited => true,
      LocationIQAutocompleteStatus.idle => false,
    };

    if (!shouldShow) {
      _removeOverlay();
      return;
    }

    if (_overlay == null) {
      _overlay = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context, rootOverlay: true).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size.zero;

    return Positioned(
      left: 0,
      top: 0,
      width: size.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, size.height + 6),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
            child: _buildDropdown(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final snap = _controller.snapshot.value;

    if (snap.status == LocationIQAutocompleteStatus.loading) {
      return widget.loadingBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Searching…'),
              ],
            ),
          );
    }

    if (snap.status == LocationIQAutocompleteStatus.rateLimited) {
      return widget.rateLimitedBuilder?.call(context, snap.cooldownUntil) ??
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              snap.cooldownUntil == null
                  ? 'Rate limited. Please try again.'
                  : 'Rate limited. Try again after ${snap.cooldownUntil}.',
            ),
          );
    }

    if (snap.status == LocationIQAutocompleteStatus.error) {
      final err = snap.error ?? 'Unknown error';
      return widget.errorBuilder?.call(context, err) ??
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: $err'),
          );
    }

    if (snap.status == LocationIQAutocompleteStatus.empty) {
      return widget.emptyBuilder?.call(context) ??
          const Padding(padding: EdgeInsets.all(12), child: Text('No results'));
    }

    final items = snap.items;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        final child =
            widget.optionBuilder?.call(context, item) ??
            ListTile(
              title: Text(item.title),
              subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
            );

        return InkWell(
          onTap: () {
            widget.onSelected(item);
            _textController.text = item.displayName;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
            _controller.clear();
            _removeOverlay();
            _focusNode.unfocus();
          },
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        onSubmitted: widget.onSubmitted,
        decoration: widget.decoration.copyWith(
          suffixIcon: _textController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                    _controller.clear();
                    _removeOverlay();
                  },
                ),
        ),
      ),
    );
  }
}
