import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickActionVisibilityProvider =
    StateProvider.autoDispose<bool>((ref) => false);
