import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';

final isCalendarSyncActiveProvider =
    createAsyncPrefProvider<bool>(prefKey: 'calendarSync', defaultValue: true);
