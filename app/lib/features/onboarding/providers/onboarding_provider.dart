import 'package:acter/features/device_permissions/calendar.dart';
import 'package:acter/features/device_permissions/notification.dart';
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
  final showNotification = await shouldShowNotificationPermissionInfoPage();
  final showCalendar = await shouldShowCalendarPermissionInfoPage();

  return OnboardingPermissions(
    showNotificationPermission: showNotification,
    showCalendarPermission: showCalendar,
  );
});
