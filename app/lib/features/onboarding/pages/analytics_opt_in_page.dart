import 'dart:io';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class AnalyticsOptInPage extends ConsumerWidget {
  static const skipBtn = Key('analytics-skip-btn');

  const AnalyticsOptInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    // ensure we are triggering a sync and do not delay this process
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    final _syncState = ref.read(syncStateProvider);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                lang.analyticsTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(lang.analyticsDescription1, style: textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text(lang.analyticsDescription2, style: textTheme.bodyMedium),
              _buildCrashAnalytics(context, ref),
              const SizedBox(height: 40),
              _buildSkipActionButton(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrashAnalytics(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final allowReportSending =
        ref.watch(allowSentryReportingProvider).valueOrNull ?? isNightly;

    void toggle(bool? input) {
      setCanReportToSentry(input ?? !allowReportSending);
      ref.invalidate(allowSentryReportingProvider);
    }

    return ListTile(
      onTap: () => toggle(null),
      title: Text(lang.sendCrashReportsTitle),
      subtitle: Text(lang.sendCrashReportsInfo),
      leading: Switch(
        value: allowReportSending,
        onChanged: (value) => toggle(value),
      ),
    );
  }

  Widget _buildSkipActionButton(BuildContext context) {
    return ActerPrimaryActionButton(                
      key: AnalyticsOptInPage.skipBtn,
      onPressed: () => _onSkipPressed(context),
      child: Text(
        L10n.of(context).done,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Future<void> _onSkipPressed(BuildContext context) async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        if (context.mounted) {
          await _handleAndroidNotificationPermission(context);
        }
      } else {
        if (context.mounted) {
          // Handle successful login, navigate as needed
          context.goNamed(Routes.main.name);
        }
      }
    } else {
      if (context.mounted) {
        // Handle successful login, navigate as needed
        context.goNamed(Routes.main.name);
      }
    }
  }

  Future<void> _handleAndroidNotificationPermission(
    BuildContext context,
  ) async {
    bool notificationPermissionGranted = await _checkNotificationPermission();

    if (!notificationPermissionGranted) {
      if (context.mounted) {
        // Navigate to the custom NotificationPermissionPage
        context.goNamed(Routes.notificationPermission.name);
      }
    } else {
      if (context.mounted) {
        // Handle successful login, navigate as needed
        context.goNamed(Routes.main.name);
      }
    }
  }

  Future<bool> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
