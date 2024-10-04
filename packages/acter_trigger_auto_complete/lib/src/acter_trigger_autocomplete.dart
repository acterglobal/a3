import 'dart:async';

import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

/// The type of the Autocomplete callback which returns the widget that
/// contains the input [TextField] or [TextFormField].
///
/// See also:
///
///   * [RawAutocomplete.fieldViewBuilder], which is of this type.
typedef ActerTriggerFieldViewBuilder = Widget Function(
  BuildContext context,
  ActerTriggerAutoCompleteTextController textEditingController,
  FocusNode focusNode,
);

/// Positions the [AutocompleteTrigger] options around the [TextField] or
/// [TextFormField] that triggered the autocomplete.
enum OptionsAlignment {
  /// Positions the options to the top of the field.
  top,

  /// Positions the options to the bottom of the field.
  bottom,

  /// Positions the options to the top left of the field.
  topStart,

  /// Positions the options to the top right of the field.
  topEnd,

  /// Positions the options to the bottom left of the field.
  bottomStart,

  /// Positions the options to the bottom right of the field.
  bottomEnd;

  Anchor _toAnchor({double? widthFactor = 1.0}) {
    switch (this) {
      case OptionsAlignment.top:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.bottomCenter,
          target: Alignment.topCenter,
        );
      case OptionsAlignment.bottom:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.topCenter,
          target: Alignment.bottomCenter,
        );
      case OptionsAlignment.topStart:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.bottomLeft,
          target: Alignment.topLeft,
        );
      case OptionsAlignment.topEnd:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.bottomRight,
          target: Alignment.topRight,
        );
      case OptionsAlignment.bottomStart:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.topLeft,
          target: Alignment.bottomLeft,
        );
      case OptionsAlignment.bottomEnd:
        return Aligned(
          widthFactor: widthFactor,
          follower: Alignment.topRight,
          target: Alignment.bottomRight,
        );
    }
  }
}

/// A widget that provides a text field with autocomplete functionality.
class MultiTriggerAutocomplete extends StatefulWidget {
  /// Create an instance of StreamAutocomplete.
  ///
  /// [displayStringForOption], [optionsBuilder] and [optionsViewBuilder] must
  /// not be null.
  const MultiTriggerAutocomplete({
    super.key,
    required this.autocompleteTriggers,
    required this.textEditingController,
    required this.focusNode,
    this.fieldViewBuilder = _defaultFieldViewBuilder,
    this.optionsAlignment = OptionsAlignment.bottom,
    this.optionsWidthFactor = 1.0,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  /// The triggers that trigger autocomplete.
  final Iterable<AutocompleteTrigger> autocompleteTriggers;

  /// {@template flutter.widgets.RawAutocomplete.fieldViewBuilder}
  /// Builds the field whose input is used to get the options.
  ///
  /// Pass the provided [ActerTextController] to the field built here so that
  /// RawAutocomplete can listen for changes.
  /// {@endtemplate}
  final ActerTriggerFieldViewBuilder fieldViewBuilder;

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@template flutter.widgets.RawAutocomplete.split}
  /// The main purpose of this parameter is to allow the use of a separate text
  /// field located in another part of the widget tree instead of the text
  /// field built by [fieldViewBuilder]. For example, it may be desirable to
  /// place the text field in the AppBar and the options below in the main body.
  ///
  /// When following this pattern, [fieldViewBuilder] can return
  /// `SizedBox.shrink()` so that nothing is drawn where the text field would
  /// normally be. A separate text field can be created elsewhere, and a
  /// FocusNode and TextEditingController can be passed both to that text field
  /// and to RawAutocomplete.
  ///
  /// {@tool dartpad}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart **
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// Focus object for [ActerTextController].
  final FocusNode focusNode;

  /// The [TextEditingController] that is used for the text field.
  /// Supports [triggerStyles] to style trigger inputs.
  final ActerTriggerAutoCompleteTextController textEditingController;

  /// The alignment of the options.
  ///
  /// The default value is [MultiTriggerAutocompleteAlignment.below].
  final OptionsAlignment optionsAlignment;

  /// The width to make the options as a multiple of the width of the
  /// field.
  ///
  /// The default value is 1.0, which makes the options the same width
  /// as the field.
  final double? optionsWidthFactor;

  /// The duration of the debounce period for the [TextEditingController].
  ///
  /// The default value is [300ms].
  final Duration debounceDuration;

  static Widget _defaultFieldViewBuilder(
    BuildContext context,
    TextEditingController textEditingController,
    FocusNode focusNode,
  ) {
    return _MultiTriggerAutocompleteField(
      focusNode: focusNode,
      textEditingController: textEditingController,
    );
  }

  /// Returns the nearest [StreamAutocomplete] ancestor of the given context.
  static MultiTriggerAutocompleteState of(BuildContext context) {
    final state =
        context.findAncestorStateOfType<MultiTriggerAutocompleteState>();
    assert(state != null, 'MultiTriggerAutocomplete not found');
    return state!;
  }

  @override
  MultiTriggerAutocompleteState createState() =>
      MultiTriggerAutocompleteState();
}

class MultiTriggerAutocompleteState extends State<MultiTriggerAutocomplete> {
  late ActerTriggerAutoCompleteTextController _textEditingController;
  late FocusNode _focusNode;

  AutocompleteQuery? _currentQuery;
  AutocompleteTrigger? _currentTrigger;

  bool _hideOptions = false;
  String _lastFieldText = '';

  // True if the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    return !_hideOptions &&
        _focusNode.hasFocus &&
        _currentQuery != null &&
        _currentTrigger != null;
  }

  void acceptAutocompleteOption(
    String option, {
    bool keepTrigger = true,
  }) {
    if (option.isEmpty) return;

    final query = _currentQuery;
    final trigger = _currentTrigger;
    if (query == null || trigger == null) return;

    final text = _textEditingController.text;
    final currentSelection = _textEditingController.selection;

    // Find the start of the current word (where the trigger character is)
    var start = currentSelection.baseOffset;
    while (start > 0 && text[start - 1] != ' ' && text[start - 1] != '\n') {
      start--;
    }

    final end = currentSelection.extentOffset;

    // Determine if we need to add the trigger character
    String finalOption = option;
    if (keepTrigger && !option.startsWith(trigger.trigger)) {
      finalOption = trigger.trigger + option;
    }

    final alreadyContainsSpace = end < text.length && text[end] == ' ';
    if (!alreadyContainsSpace) finalOption += ' ';

    var selectionOffset = start + finalOption.length;
    if (alreadyContainsSpace) selectionOffset++;

    final newText = text.replaceRange(start, end, finalOption);
    final newSelection = TextSelection.collapsed(offset: selectionOffset);

    _textEditingController.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );

    final tagStart = keepTrigger ? start : start + 1;
    final tagEnd = start + finalOption.trimRight().length;
    final tag = TaggedText(
      trigger: trigger.trigger,
      displayText: finalOption.trim(),
      start: tagStart,
      end: tagEnd,
    );

    _textEditingController.addTag(tag);

    return closeOptions();
  }

  void closeOptions() {
    final prevQuery = _currentQuery;
    final prevTrigger = _currentTrigger;
    if (prevQuery == null || prevTrigger == null) return;

    _currentQuery = null;
    _currentTrigger = null;
    if (mounted) setState(() {});
  }

  void showOptions(
    AutocompleteQuery query,
    AutocompleteTrigger trigger,
  ) {
    final prevQuery = _currentQuery;
    final prevTrigger = _currentTrigger;
    if (prevQuery == query && prevTrigger == trigger) return;

    _currentQuery = query;
    _currentTrigger = trigger;
    if (mounted) setState(() {});
  }

  // Checks if there is any invoked autocomplete trigger and returns the first
  // one along with the query that matches the current input.
  _AutocompleteInvokedTriggerWithQuery? _getInvokedTriggerWithQuery(
    TextEditingValue textEditingValue,
  ) {
    final autocompleteTriggers = widget.autocompleteTriggers.toSet();
    for (final trigger in autocompleteTriggers) {
      final query = trigger.invokingTrigger(textEditingValue);
      if (query != null) {
        return _AutocompleteInvokedTriggerWithQuery(trigger, query);
      }
    }
    return null;
  }

  Timer? _debounceTimer;

  // Called when _textEditingController changes.
  void _onChangedField() {
    if (_debounceTimer?.isActive == true) _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      final textEditingValue = _textEditingController.value;

      // If the content has not changed, then there is nothing to do.
      if (textEditingValue.text == _lastFieldText) return;

      // Make sure the options are no longer hidden if the content of the
      // field changes.
      _hideOptions = false;
      _lastFieldText = textEditingValue.text;

      // If the text field is empty, then there is no need to do anything.
      if (textEditingValue.text.isEmpty) return closeOptions();

      // If the text field is not empty, then we need to check if the
      // text field contains a trigger.
      final triggerWithQuery = _getInvokedTriggerWithQuery(textEditingValue);

      // If the text field does not contain a trigger, then there is no need
      // to do anything.
      if (triggerWithQuery == null) return closeOptions();

      // If the text field contains a trigger, then we need to open the
      // portal.
      final trigger = triggerWithQuery.trigger;
      final query = triggerWithQuery.query;
      return showOptions(query, trigger);
    });
  }

  // Called when the field's FocusNode changes.
  void _onChangedFocus() {
    // Options should no longer be hidden when the field is re-focused.
    _hideOptions = !_focusNode.hasFocus;
    if (mounted) setState(() {});
  }

  // Handle a potential change in textEditingController by properly disposing of
  // the old one and setting up the new one, if needed.
  void _updateTextEditingController(
    ActerTriggerAutoCompleteTextController? old,
    ActerTriggerAutoCompleteTextController? current,
  ) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController.dispose();
      _textEditingController = current!;
    } else if (current == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = ActerTriggerAutoCompleteTextController();
    } else {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = current;
    }
    _textEditingController.addListener(_onChangedField);
  }

  // Handle a potential change in focusNode by properly disposing of the old one
  // and setting up the new one, if needed.
  void _updateFocusNode(FocusNode? old, FocusNode? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode.dispose();
      _focusNode = current!;
    } else if (current == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = FocusNode();
    } else {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = current;
    }
    _focusNode.addListener(_onChangedFocus);
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = widget.textEditingController;
    _textEditingController.addListener(_onChangedField);
    _focusNode = widget.focusNode;
    _focusNode.addListener(_onChangedFocus);
  }

  @override
  void didUpdateWidget(MultiTriggerAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTextEditingController(
      oldWidget.textEditingController,
      widget.textEditingController,
    );
    _updateFocusNode(oldWidget.focusNode, widget.focusNode);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _currentTrigger = null;
    _currentQuery = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adding additional builder so that [MultiTriggerAutocomplete.of] works.
    return Builder(
      builder: (context) {
        final anchor = widget.optionsAlignment._toAnchor(
          widthFactor: widget.optionsWidthFactor,
        );
        final shouldShowOptions = _shouldShowOptions;
        final optionViewBuilder = shouldShowOptions
            ? TextFieldTapRegion(
                child: _currentTrigger!.optionsViewBuilder(
                  context,
                  _currentQuery!,
                  _textEditingController,
                ),
              )
            : null;

        return PortalTarget(
          anchor: anchor,
          visible: shouldShowOptions,
          portalFollower: optionViewBuilder,
          child: widget.fieldViewBuilder(
            context,
            _textEditingController,
            _focusNode,
          ),
        );
      },
    );
  }
}

class _AutocompleteInvokedTriggerWithQuery {
  const _AutocompleteInvokedTriggerWithQuery(this.trigger, this.query);

  final AutocompleteTrigger trigger;
  final AutocompleteQuery query;
}

// The default Material-style Autocomplete text field.
class _MultiTriggerAutocompleteField extends StatelessWidget {
  const _MultiTriggerAutocompleteField({
    required this.focusNode,
    required this.textEditingController,
  });

  final FocusNode focusNode;

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      focusNode: focusNode,
    );
  }
}
