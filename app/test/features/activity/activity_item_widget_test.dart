import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/attachment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/comment.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/reaction.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/type_widgets/references.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';
import 'mock_data/mock_activity.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    MockActivity? mockActivity,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [],
      child: Material(
        child: ActivityItemWidget(activity: mockActivity!),
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('Activity item widget displays ActivityCommentItemWidget',
      (tester) async {
    MockActivity mockActivity = MockActivity(mockType: PushStyles.comment.name);
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify the comment widget is displayed
    expect(find.byType(ActivityCommentItemWidget), findsOneWidget);
  });

  testWidgets('Activity item widget displays ActivityReactionItemWidget',
      (tester) async {
    MockActivity mockActivity =
        MockActivity(mockType: PushStyles.reaction.name);
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify the comment widget is displayed
    expect(find.byType(ActivityReactionItemWidget), findsOneWidget);
  });

  testWidgets('Activity item widget displays ActivityAttachmentItemWidget',
      (tester) async {
    MockActivity mockActivity =
        MockActivity(mockType: PushStyles.attachment.name);
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify the comment widget is displayed
    expect(find.byType(ActivityAttachmentItemWidget), findsOneWidget);
  });

  testWidgets('Activity item widget displays ActivityReferencesItemWidget',
      (tester) async {
    MockActivity mockActivity =
        MockActivity(mockType: PushStyles.references.name);
    await createWidgetUnderTest(tester: tester, mockActivity: mockActivity);

    // Verify the comment widget is displayed
    expect(find.byType(ActivityReferencesItemWidget), findsOneWidget);
  });
}
