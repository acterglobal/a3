import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';

typedef NavigateTo = Future<void> Function(
  Routes route, {
  Future<bool> Function(BuildContext)? prepare,
  bool? push,
  Map<String, String>? pathParameters,
  Map<String, String>? queryParameters,
  Object? extra,
});
