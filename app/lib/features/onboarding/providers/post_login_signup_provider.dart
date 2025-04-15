import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:acter/features/analytics/actions/telemetry_analytics.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::post_login_signup');

enum PostLoginSignupStep {
  saveUsername,
  redeemInvitations,
  encryptionBackup,
  linkEmail,
  uploadAvatar,
  notifications,
  calendar,
  analytics,
  completed,
}

class PostLoginSignupState {
  final PostLoginSignupStep currentStep;
  final Set<PostLoginSignupStep> completedSteps;

  const PostLoginSignupState({
    required this.currentStep,
    required this.completedSteps,
  });

  PostLoginSignupState copyWith({
    PostLoginSignupStep? currentStep,
    Set<PostLoginSignupStep>? completedSteps,
  }) {
    return PostLoginSignupState(
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

class PostLoginSignupNotifier extends StateNotifier<PostLoginSignupState> {
  PostLoginSignupNotifier()
      : super(
    const PostLoginSignupState(
      currentStep: PostLoginSignupStep.notifications,
      completedSteps: {},
    ),
  );

  Future<void> completeStep(BuildContext context, PostLoginSignupStep step) async {
    final newCompletedSteps = {...state.completedSteps, step};
    final nextStep = _getNextStep(newCompletedSteps);

    state = state.copyWith(
      completedSteps: newCompletedSteps,
      currentStep: nextStep,
    );

    if (nextStep == PostLoginSignupStep.completed) {
      context.goNamed(Routes.main.name);
    }
  }

  PostLoginSignupStep _getNextStep(Set<PostLoginSignupStep> completedSteps) {
    if (!completedSteps.contains(PostLoginSignupStep.saveUsername)) {
      return PostLoginSignupStep.saveUsername;
    }
    if (!completedSteps.contains(PostLoginSignupStep.redeemInvitations)) {
      return PostLoginSignupStep.redeemInvitations;
    }
    if (!completedSteps.contains(PostLoginSignupStep.encryptionBackup)) {
      return PostLoginSignupStep.encryptionBackup;
    }
    if (!completedSteps.contains(PostLoginSignupStep.linkEmail)) {
      return PostLoginSignupStep.linkEmail;
    }
    if (!completedSteps.contains(PostLoginSignupStep.uploadAvatar)) {
      return PostLoginSignupStep.uploadAvatar;
    }
    if (!completedSteps.contains(PostLoginSignupStep.notifications)) {
      return PostLoginSignupStep.notifications;
    }
    if (!completedSteps.contains(PostLoginSignupStep.calendar)) {
      return PostLoginSignupStep.calendar;
    }
    if (!completedSteps.contains(PostLoginSignupStep.analytics)) {
      return PostLoginSignupStep.analytics;
    }
    return PostLoginSignupStep.completed;
  }

  Future<void> handleStep(BuildContext context, PostLoginSignupStep step) async {
    _log.info('Running post-login step: ${step.name}');
    try {
      await switch (step) {
        PostLoginSignupStep.notifications => handleNotificationPermission(context),
        PostLoginSignupStep.calendar => handleCalendarPermission(context),
        PostLoginSignupStep.analytics => showAnalyticsOptIn(context),
        PostLoginSignupStep.saveUsername => Future.value(),
        PostLoginSignupStep.redeemInvitations => Future.value(),
        PostLoginSignupStep.encryptionBackup => Future.value(),
        PostLoginSignupStep.linkEmail => Future.value(),
        PostLoginSignupStep.uploadAvatar => Future.value(),
        PostLoginSignupStep.completed => Future.value(),
      };
      if (context.mounted) {
        await completeStep(context, step);
      }
    } catch (error, stackTrace) {
      _log.severe(
        'Failed to complete post-login step: ${step.name}',
        error,
        stackTrace,
      );
    }
  }
}

final postLoginSignupProvider =
  StateNotifierProvider<PostLoginSignupNotifier, PostLoginSignupState>((ref) {
  return PostLoginSignupNotifier();
});
