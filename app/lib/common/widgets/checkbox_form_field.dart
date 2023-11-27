import 'package:flutter/material.dart';

// Inspired by https://stackoverflow.com/questions/53479942/checkbox-form-validation
class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    Widget? title,
    FormFieldSetter<bool>? onSaved,
    FormFieldValidator<bool>? validator,
    FormFieldSetter<bool>? onChanged,
    bool initialValue = false,
    bool autovalidate = false,
    super.key,
  }) : super(
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          builder: (FormFieldState<bool> state) {
            return CheckboxListTile(
              dense: state.hasError,
              title: title,
              value: state.value,
              onChanged: (value) {
                state.didChange(value);
                if (onChanged != null) {
                  onChanged(value);
                }
              },
              subtitle: state.hasError
                  ? Builder(
                      builder: (BuildContext context) => Text(
                        state.errorText ?? '',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,),
                      ),
                    )
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        );
}
