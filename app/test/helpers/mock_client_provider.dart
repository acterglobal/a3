import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockClientNotifier extends AsyncNotifier<Client?>
    with Mock
    implements ClientNotifier {
  final Client? client;

  MockClientNotifier({required this.client});
}
