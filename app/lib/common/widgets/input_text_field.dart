import 'package:flutter/material.dart';

class InputTextField extends StatefulWidget {
  final String hintText;
  final TextInputType textInputType;
  final TextInputAction textInputAction;
  final TextEditingController? controller;
  final int? maxLines;
  final void Function(String?)? onInputChanged;
  final String? Function(String?)? validator;
  final bool? readOnly;

  const InputTextField({
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
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  final TextEditingController _controller = TextEditingController();

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
      decoration: InputDecoration(filled: true, hintText: widget.hintText),
    );
  }
}
