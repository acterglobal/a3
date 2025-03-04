import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

String? validateEmail(BuildContext context, String? value) {
  final lang = L10n.of(context);
  if (value == null || value.isEmpty) return lang.emptyEmail;
  const String emailPattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  final RegExp regex = RegExp(emailPattern);
  return !regex.hasMatch(value) ? lang.validEmail : null;
}
