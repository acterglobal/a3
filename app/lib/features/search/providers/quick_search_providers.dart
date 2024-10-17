import 'package:riverpod/riverpod.dart';

final quickSearchValueProvider = StateProvider.autoDispose<String>((ref) => '');
