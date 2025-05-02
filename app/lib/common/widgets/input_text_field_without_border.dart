import 'package:flutter/material.dart';

class InputTextFieldWithoutBorder extends StatefulWidget {
  final String hintText;
  final TextInputType textInputType;
  final TextInputAction textInputAction;
  final TextEditingController? controller;
  final int? maxLines;
  final void Function(String?)? onInputChanged;
  final String? Function(String?)? validator;
  final bool? readOnly;

  const InputTextFieldWithoutBorder({
    required this.hintText,
    required this.textInputType,
    this.textInputAction = TextInputAction.next,
    this.controller,
    this.maxLines,
    this.validator,
    this.readOnly,
    this.onInputChanged,
    super.key,
  });

  @override
  State<InputTextFieldWithoutBorder> createState() =>
      _InputTextFieldWithoutBorderState();
}

class _InputTextFieldWithoutBorderState extends State<InputTextFieldWithoutBorder> {
  final TextEditingController _controller = TextEditingController();

  OutlineInputBorder get _circularBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // More circular
        borderSide: BorderSide.none,
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: widget.readOnly ?? false,
      controller: widget.controller ?? _controller,
      maxLines: widget.maxLines ?? 1,
      keyboardType: widget.textInputType,
      textInputAction: widget.textInputAction,
      // required field, space allowed
      validator:
      widget.validator ??
              (val) => val == null || val.isEmpty ? 'Field can’t be empty' : null,
      onChanged: widget.onInputChanged ?? (value) {},
      onFieldSubmitted: (value) {
        FocusNode().unfocus();
      },
      cursorColor: Theme.of(context).colorScheme.secondary,
      style: Theme.of(context).textTheme.labelLarge,
      decoration: InputDecoration(
        filled: true,
        hintText: widget.hintText,
        fillColor: Theme.of(context).colorScheme.surface,
        border: _circularBorder,
        enabledBorder: _circularBorder,
        focusedBorder: _circularBorder,
        errorBorder: _circularBorder,
        focusedErrorBorder: _circularBorder,
      ),
    );
  }
}
