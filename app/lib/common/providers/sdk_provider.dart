import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sdkProvider = FutureProvider<ActerSdk>((ref) async {
  return await ActerSdk.instance;
});
