import 'package:flutter/material.dart';

class InputTextField extends StatefulWidget {
  final String hintText;
  final TextInputType textInputType;
  final TextEditingController? controller;
  final int? maxLines;
  final void Function(String?)? onInputChanged;
  final String? validatorString;
  const InputTextField({
    required this.hintText,
    required this.textInputType,
    this.controller,
    this.maxLines,
    this.validatorString,
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
      controller: widget.controller ?? _controller,
      maxLines: widget.maxLines ?? 1,
      keyboardType: widget.textInputType,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.validatorString ?? 'Please enter some text';
        }
        return null;
      },
      onChanged: widget.onInputChanged ?? (value) {},
      onFieldSubmitted: (value) {
        FocusNode().unfocus();
      },
      cursorColor: Theme.of(context).colorScheme.tertiary,
      style: Theme.of(context).textTheme.labelLarge,
      decoration: InputDecoration(
        fillColor: Theme.of(context).colorScheme.primaryContainer,
        filled: true,
        hintText: widget.hintText,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
