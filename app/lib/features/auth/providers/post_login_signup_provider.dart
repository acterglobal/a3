import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/desktop_setup/actions/desktop_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:acter/features/analytics/actions/telemetry_analytics.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::post_login_signup');

/// Provider for the PostLoginSignupService
final postLoginSignupProvider = Provider<PostLoginSignupService>(
  (ref) => PostLoginSignupService(
    steps: [
      PostLoginSignupStep(
        name: 'Notification Permission',
        execute: handleNotificationPermission,
      ),
      PostLoginSignupStep(
        name: 'Calendar Permission',
        execute: handleCalendarPermission,
      ),
      if (isDesktop)
        PostLoginSignupStep(
          name: 'Launch at Startup',
          execute: showDesktopSetup,
        ),
      PostLoginSignupStep(
        name: 'Analytics Opt-in',
        execute: showAnalyticsOptIn,
      ),
    ],
  ),
);

/// A contract for a post-login-signup step
class PostLoginSignupStep {
  final String name;
  final Future<void> Function(BuildContext context) execute;

  const PostLoginSignupStep({
    required this.name,
    required this.execute,
  });
}

/// A service that runs a series of post-login-signup steps
class PostLoginSignupService {
  final List<PostLoginSignupStep> steps;

  PostLoginSignupService({required this.steps});

  /// Run all post-login-signup initialization steps
  Future<void> initialize(BuildContext context) async {
    for (final step in steps) {
      _log.info('Running post-login step: ${step.name}');
      try {
        await step.execute(context);
      } catch (error, stackTrace) {
        _log.severe(
          'Failed to complete post-login step: ${step.name}',
          error,
          stackTrace,
        );
      }
    }
  }
}
