import 'dart:async';

import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnForward = FutureOr<void> Function(BuildContext, WidgetRef, Room);
