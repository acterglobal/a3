import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = ChangeNotifierProvider.family<GoRouter, BuildContext>(
  (ref, context) => GoRouter.of(context),
);
