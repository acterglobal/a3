import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activity_ui_showcase/mocks/general/mock_activity.dart';
import 'package:acter/features/activity_ui_showcase/mocks/showcase/data/biggervisual_usecases.dart';
import 'package:acter/features/activity_ui_showcase/mocks/showcase/data/individual_actions_usecases.dart';
import 'package:acter/features/activity_ui_showcase/mocks/showcase/data/membership_usecases.dart';
import 'package:acter/features/activity_ui_showcase/mocks/showcase/data/social_usecases.dart';
import 'package:acter/features/activity_ui_showcase/mocks/showcase/data/space_core_usecases.dart';
import 'package:riverpod/riverpod.dart';

final List<ActivityMock> mockActivitiesListGenerator = [
  pinCommentActivity1,
  documentAttachmentActivity1,
  reactionActivity2,
  eventReferenceActivity1,
  kickedActivity1,
  bannedActivity1,
  unbannedActivity1,
  taskAddActivity1,
  taskTitleChangeActivity1,
  roomTopicChangeActivity1,
  descriptionChangeActivity1,
  eventCreationActivity1,
  reactionActivity3,
  rsvpYesActivity1,
  rsvpMaybeActivity1,
  knockAcceptedActivity1,
  knockRetractedActivity1,
  knockDeniedActivity1,
  taskCompleteActivity1,
  taskReopenActivity1,
  joinedActivity1,
  invitationAcceptedActivity1,
  invitedActivity1,
  leftActivity1,
  invitationRejectedActivity1,
  reactionActivity1,
  roomNameActivity1,
  roomAvatarActivity1,
];

final mockActivitiesProvider = Provider<List<ActivityMock>>((ref) {
  return mockActivitiesListGenerator;
});

final mockActivitiesDatesProvider = Provider<List<DateTime>>((ref) {
  final mockActivities = ref.watch(mockActivitiesProvider);
  return mockActivities.map((e) => getActivityDate(e.originServerTs())).toSet().toList();
});