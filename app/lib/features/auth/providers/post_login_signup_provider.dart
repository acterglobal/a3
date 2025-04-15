import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:acter/features/analytics/actions/telemetry_analytics.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::post_login_signup');

enum PostLoginStep {
  notifications,
  calendar,
  analytics,
  completed,
}

class PostLoginSignupState {
  final PostLoginStep currentStep;
  final Set<PostLoginStep> completedSteps;

  const PostLoginSignupState({
    required this.currentStep,
    required this.completedSteps,
  });

  PostLoginSignupState copyWith({
    PostLoginStep? currentStep,
    Set<PostLoginStep>? completedSteps,
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
      currentStep: PostLoginStep.notifications,
      completedSteps: {},
    ),
  );

  Future<void> completeStep(BuildContext context, PostLoginStep step) async {
    final newCompletedSteps = {...state.completedSteps, step};
    final nextStep = _getNextStep(newCompletedSteps);

    state = state.copyWith(
      completedSteps: newCompletedSteps,
      currentStep: nextStep,
    );

    if (nextStep == PostLoginStep.completed) {
      context.goNamed(Routes.main.name);
    }
  }

  PostLoginStep _getNextStep(Set<PostLoginStep> completedSteps) {
    if (!completedSteps.contains(PostLoginStep.notifications)) {
      return PostLoginStep.notifications;
    }
    if (!completedSteps.contains(PostLoginStep.calendar)) {
      return PostLoginStep.calendar;
    }
    if (!completedSteps.contains(PostLoginStep.analytics)) {
      return PostLoginStep.analytics;
    }
    return PostLoginStep.completed;
  }

  Future<void> handleStep(BuildContext context, PostLoginStep step) async {
    _log.info('Running post-login step: ${step.name}');
    try {
      await switch (step) {
        PostLoginStep.notifications => handleNotificationPermission(context),
        PostLoginStep.calendar => handleCalendarPermission(context),
        PostLoginStep.analytics => showAnalyticsOptIn(context),
        PostLoginStep.completed => Future.value(),
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
