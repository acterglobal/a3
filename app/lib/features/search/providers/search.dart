import 'package:riverpod/riverpod.dart';

final searchValueProvider = StateProvider.autoDispose<String>((ref) => '');
