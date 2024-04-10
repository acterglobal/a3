import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:riverpod/riverpod.dart';

final sdkProvider = FutureProvider<ActerSdk>((ref) async {
  return await ActerSdk.instance;
});
