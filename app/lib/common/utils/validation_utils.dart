import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

String? validateEmail(BuildContext context, String? value) {
  const String emailPattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  final RegExp regex = RegExp(emailPattern);
  if (value == null || value.isEmpty) {
    return L10n.of(context).emptyEmail;
  } else if (!regex.hasMatch(value)) {
    return L10n.of(context).validEmail;
  } else {
    return null;
  }
}
