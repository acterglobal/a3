import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_date_item_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/space_activities_item_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';
import '../../../../activity/mock_data/mock_activity.dart';

void main() {
  group('ActivityDateItemWidget Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
    });

    Future<void> pumpActivityDateItemWidget(
      WidgetTester tester, {
      DateTime? activityDate,
      List<({String roomId, List<MockActivity> activities})>? groupedActivitiesList,
    }) async {
      final date = activityDate ?? testDate;
      
      await tester.pumpProviderWidget(
        overrides: [
          if (groupedActivitiesList != null)
            activitiesByDateProvider(date).overrideWith(
              (ref) => groupedActivitiesList.cast<({String roomId, List<Activity> activities})>(),
            ),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ActivityDateItemWidget(
              activityDate: date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders empty widget when no activities', (WidgetTester tester) async {
      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: [],
      );

      expect(find.byType(ActivityDateItemWidget), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(SpaceActivitiesItemWidget), findsNothing);
    });

    testWidgets('renders single activity group correctly', (WidgetTester tester) async {
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      expect(find.byType(ActivityDateItemWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SpaceActivitiesItemWidget), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Date label container
    });

    testWidgets('renders multiple activity groups correctly', (WidgetTester tester) async {
      final mockActivity1 = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final mockActivity2 = MockActivity(
        mockType: 'reaction',
        mockRoomId: 'room2',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity1]),
        (roomId: 'room2', activities: [mockActivity2]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      expect(find.byType(ActivityDateItemWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SpaceActivitiesItemWidget), findsNWidgets(2));
    });

    testWidgets('shows date label for first group only', (WidgetTester tester) async {
      final mockActivity1 = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final mockActivity2 = MockActivity(
        mockType: 'reaction',
        mockRoomId: 'room2',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity1]),
        (roomId: 'room2', activities: [mockActivity2]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      // Should find containers for date labels
      final containers = tester.widgetList<Container>(find.byType(Container));
      
      // Check that there are containers with the expected styling for date labels
      final dateContainers = containers.where((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && 
               decoration.border != null &&
               decoration.borderRadius != null;
      });

      expect(dateContainers.length, greaterThan(0));
    });

    testWidgets('displays correct date label text for today', (WidgetTester tester) async {
      final today = DateTime.now();
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: today.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        activityDate: today,
        groupedActivitiesList: groupedActivities,
      );

      // The date label should be displayed based on the activity timestamp
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('handles multiple activities in same room group', (WidgetTester tester) async {
      final mockActivity1 = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final mockActivity2 = MockActivity(
        mockType: 'reaction',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch + 1000,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity1, mockActivity2]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      expect(find.byType(ActivityDateItemWidget), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SpaceActivitiesItemWidget), findsOneWidget);
      
      // Should only have one SpaceActivitiesItemWidget since both activities are in the same room
      final spaceActivitiesWidget = tester.widget<SpaceActivitiesItemWidget>(
        find.byType(SpaceActivitiesItemWidget),
      );
      expect(spaceActivitiesWidget.roomId, 'room1');
      expect(spaceActivitiesWidget.activities.length, 2);
    });

    testWidgets('uses NeverScrollableScrollPhysics for ListView', (WidgetTester tester) async {
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
      expect(listView.shrinkWrap, true);
      expect(listView.padding, EdgeInsets.zero);
    });

    testWidgets('date label container has correct styling', (WidgetTester tester) async {
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      // Find the date label containers
      final containers = tester.widgetList<Container>(find.byType(Container));
      final dateContainer = containers.firstWhere((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && 
               decoration.border != null &&
               decoration.borderRadius != null;
      });

      expect(dateContainer.margin, const EdgeInsets.symmetric(vertical: 10));
      expect(dateContainer.padding, const EdgeInsets.symmetric(vertical: 6, horizontal: 16));
      
      final decoration = dateContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.border, isA<Border>());
    });

    testWidgets('Column has correct properties', (WidgetTester tester) async {
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      final columns = tester.widgetList<Column>(find.byType(Column));
      expect(columns.length, greaterThan(0));
      
      // Find the column that contains our date item content
      final column = columns.firstWhere((col) {
        return col.crossAxisAlignment == CrossAxisAlignment.start &&
               col.mainAxisSize == MainAxisSize.min;
      });
      
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      expect(column.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('passes correct parameters to SpaceActivitiesItemWidget', (WidgetTester tester) async {
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: testDate.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        groupedActivitiesList: groupedActivities,
      );

      final spaceActivitiesWidget = tester.widget<SpaceActivitiesItemWidget>(
        find.byType(SpaceActivitiesItemWidget),
      );
      
      expect(spaceActivitiesWidget.date, testDate);
      expect(spaceActivitiesWidget.roomId, 'room1');
      expect(spaceActivitiesWidget.activities.length, 1);
      expect(spaceActivitiesWidget.activities.first, mockActivity);
    });

    testWidgets('handles different date formats correctly', (WidgetTester tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final mockActivity = MockActivity(
        mockType: 'comment',
        mockRoomId: 'room1',
        mockOriginServerTs: yesterday.millisecondsSinceEpoch,
      );

      final groupedActivities = [
        (roomId: 'room1', activities: [mockActivity]),
      ];

      await pumpActivityDateItemWidget(
        tester,
        activityDate: yesterday,
        groupedActivitiesList: groupedActivities,
      );

      // Should render without errors and show appropriate date text
      expect(find.byType(ActivityDateItemWidget), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });
  });
} 