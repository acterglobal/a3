import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAsyncPrefNotifier<T> extends AsyncNotifier<T>
    with Mock
    implements AsyncPrefNotifier<T> {
  MockAsyncPrefNotifier(this.value);

  final T value;

  @override
  Future<T> build() async => value;

  @override
  Future<void> set(T value) async => state = AsyncValue.data(value);
}
