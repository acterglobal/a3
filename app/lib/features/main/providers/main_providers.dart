import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickActionVisibilityProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final appLinks = AppLinks(); // AppLinks is singleton
