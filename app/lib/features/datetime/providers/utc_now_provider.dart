import 'package:acter/features/datetime/providers/notifiers/now_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the "current" UTC datetime, automatically updating at least
/// once a minute
final utcNowProvider =
    StateNotifierProvider<UtcNowNotifier, DateTime>((ref) => UtcNowNotifier());
