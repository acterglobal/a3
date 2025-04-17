import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPermissions {
  final bool showNotificationPermission;
  final bool showCalendarPermission;

  const OnboardingPermissions({
    required this.showNotificationPermission,
    required this.showCalendarPermission,
  });
}

final onboardingPermissionsProvider = FutureProvider<OnboardingPermissions>((
  ref,
) async {
  final showNotification = await isShowNotificationPermissionInfoPage();
  final showCalendar = await isShowCalendarPermissionInfoPage();

  return OnboardingPermissions(
    showNotificationPermission: showNotification,
    showCalendarPermission: showCalendar,
  );
});
