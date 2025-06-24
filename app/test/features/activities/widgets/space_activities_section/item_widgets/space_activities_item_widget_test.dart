import 'package:acter/common/widgets/dashed_line_vertical.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/space_activities_item_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';
import '../../../../../helpers/mock_chat_providers.dart';
import '../../../../activity/mock_data/mock_activity.dart';

void main() {
  group('SpaceActivitiesItemWidget Tests', () {
    late DateTime testDate;
    late Map<String, AvatarInfo> mockAvatarData;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      mockAvatarData = {
        'test-room-id': AvatarInfo(
          uniqueId: 'test-room-id',
          displayName: 'Test Space Name',
        ),
        'custom-room-id': AvatarInfo(
          uniqueId: 'custom-room-id',
          displayName: 'Custom Room Name',
        ),
        'no-name-room-id': AvatarInfo(uniqueId: 'no-name-room-id'),
      };
    });

    Future<void> pumpSpaceActivitiesItemWidget(
      WidgetTester tester, {
      DateTime? date,
      String? roomId,
      List<Activity>? activities,
      Map<String, AvatarInfo>? avatarData,
    }) async {
      final testRoomId = roomId ?? 'test-room-id';
      final testDate = date ?? DateTime(2024, 1, 15);
      final testActivities =
          activities ??
          [
            MockActivity(
              mockType: 'comment',
              mockRoomId: testRoomId,
              mockOriginServerTs: testDate.millisecondsSinceEpoch,
            ),
          ];

      await tester.pumpProviderWidget(
        overrides: mockChatRoomProviders(avatarData ?? mockAvatarData),
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: SpaceActivitiesItemWidget(
              date: testDate,
              roomId: testRoomId,
              activities: testActivities,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders basic widget structure correctly', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester);

      expect(find.byType(SpaceActivitiesItemWidget), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Test Space Name'), findsOneWidget);
    });

    testWidgets('displays room name from avatar info', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester, roomId: 'custom-room-id');

      expect(find.text('Custom Room Name'), findsOneWidget);
    });

    testWidgets('falls back to roomId when display name is null', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester, roomId: 'no-name-room-id');

      expect(find.text('no-name-room-id'), findsOneWidget);
    });

    testWidgets('renders single activity correctly', (
      WidgetTester tester,
    ) async {
      final singleActivity = [
        MockActivity(
          mockType: 'comment',
          mockRoomId: 'test-room-id',
          mockOriginServerTs: testDate.millisecondsSinceEpoch,
        ),
      ];

      await pumpSpaceActivitiesItemWidget(tester, activities: singleActivity);

      expect(find.byType(ActivityItemWidget), findsOneWidget);
      expect(find.byType(DashedLineVertical), findsOneWidget);
    });

    testWidgets('renders multiple activities correctly', (
      WidgetTester tester,
    ) async {
      final multipleActivities = [
        MockActivity(
          mockType: 'comment',
          mockRoomId: 'test-room-id',
          mockOriginServerTs: testDate.millisecondsSinceEpoch,
        ),
        MockActivity(
          mockType: 'reaction',
          mockRoomId: 'test-room-id',
          mockOriginServerTs: testDate.millisecondsSinceEpoch + 1000,
        ),
        MockActivity(
          mockType: 'attachment',
          mockRoomId: 'test-room-id',
          mockOriginServerTs: testDate.millisecondsSinceEpoch + 2000,
        ),
      ];

      await pumpSpaceActivitiesItemWidget(
        tester,
        activities: multipleActivities,
      );

      expect(find.byType(ActivityItemWidget), findsNWidgets(3));
      expect(find.byType(DashedLineVertical), findsNWidgets(3));
    });

    testWidgets('handles empty activities list', (WidgetTester tester) async {
      await pumpSpaceActivitiesItemWidget(tester, activities: []);

      expect(find.byType(SpaceActivitiesItemWidget), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.byType(ActivityItemWidget), findsNothing);
      expect(find.byType(DashedLineVertical), findsNothing);
    });

    testWidgets('ExpansionTile has correct properties', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester);

      final expansionTile = tester.widget<ExpansionTile>(
        find.byType(ExpansionTile),
      );
      expect(expansionTile.initiallyExpanded, true);
      expect(expansionTile.collapsedBackgroundColor, Colors.transparent);
      expect(expansionTile.tilePadding, EdgeInsets.zero);
      expect(expansionTile.shape, const Border());
      expect(expansionTile.showTrailingIcon, false);
    });

    testWidgets('activity items have correct padding', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester);

      final paddingWidgets = tester.widgetList<Padding>(find.byType(Padding));

      // Find padding widgets with horizontal padding of 4
      final activityPadding = paddingWidgets.where((padding) {
        return padding.padding == const EdgeInsets.symmetric(horizontal: 4);
      });

      expect(activityPadding.length, greaterThan(0));
    });

    testWidgets('SizedBox has correct width between dashed line and activity', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesItemWidget(tester);

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));

      // Find SizedBox with width 12
      final spacingSizedBox = sizedBoxes.where((sizedBox) {
        return sizedBox.width == 12;
      });

      expect(spacingSizedBox.length, greaterThan(0));
    });

    testWidgets('passes correct activity to ActivityItemWidget', (
      WidgetTester tester,
    ) async {
      final testActivity = MockActivity(
        mockType: 'test-activity',
        mockRoomId: 'test-room-id',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      await pumpSpaceActivitiesItemWidget(tester, activities: [testActivity]);

      final activityItemWidget = tester.widget<ActivityItemWidget>(
        find.byType(ActivityItemWidget),
      );

      expect(activityItemWidget.activity, testActivity);
    });
  });

  group('SpaceActivitiesSkeleton Tests', () {
    Future<void> pumpSpaceActivitiesSkeleton(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SpaceActivitiesSkeleton())),
      );
      await tester.pump();
    }

    testWidgets('renders skeleton widget correctly', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesSkeleton(tester);

      expect(find.byType(SpaceActivitiesSkeleton), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ListView has correct properties in skeleton', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesSkeleton(tester);

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
      expect(listView.shrinkWrap, true);
    });

    testWidgets('skeleton renders correct number of list items', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesSkeleton(tester);

      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('skeleton list items have correct structure', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesSkeleton(tester);

      // Check for bell icons in skeleton
      expect(find.byIcon(Atlas.bell), findsNWidgets(5));

      // Check for skeleton text content
      expect(find.text('Title Title Title Title Title'), findsNWidgets(5));
      expect(
        find.text(
          'Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title Sub-title',
        ),
        findsNWidgets(5),
      );
    });

    testWidgets('skeleton icons have correct size', (
      WidgetTester tester,
    ) async {
      await pumpSpaceActivitiesSkeleton(tester);

      final icons = tester.widgetList<Icon>(find.byIcon(Atlas.bell));
      for (final icon in icons) {
        expect(icon.size, 60);
      }
    });
  });
}
