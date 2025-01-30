import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class UtcNowNotifier extends StateNotifier<DateTime> {
  late Timer _timer;
  UtcNowNotifier() : super(DateTime.now().toUtc()) {
    _timer = Timer.periodic(const Duration(seconds: 59), (t) {
      state = DateTime.now().toUtc();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
