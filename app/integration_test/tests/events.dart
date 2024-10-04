import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/pages/create_event_page.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';

extension ActerNews on ConvenientTest {
  Future<void> openCreateEvent() async {
    await navigateTo([
      Keys.mainNav,
      MainNavKeys.quickJump,
      QuickJumpKeys.createEventAction,
    ]);
  }

  Future<void> addEditEventName(String eventName) async {
    // Event name text field
    final eventNameTextFieldKey = find.byKey(EventsKeys.eventNameTextField);
    await eventNameTextFieldKey.should(findsOneWidget);
    await eventNameTextFieldKey.enterTextWithoutReplace(eventName);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await find.text(eventName).should(findsOneWidget);
  }

  Future<void> selectDate() async {
    await find.byType(DatePickerDialog).should(findsOneWidget);
    final currentDate = DateTime.now().day;
    final date = find.text(currentDate.toString());
    await date.tap();
    final okBtn = find.text('OK');
    await okBtn.tap();
  }

  Future<void> selectTime() async {
    await find.byType(TimePickerDialog).should(findsOneWidget);
    final okBtn = find.text('OK');
    await okBtn.tap();
  }

  Future<void> addEditDescriptionText(String descriptionText) async {
    await trigger(EventsKeys.eventDescriptionTextField);

    final createEditEventFinder = find.byKey(createEditEventKey);
    await createEditEventFinder.should(findsOneWidget);
    final editorState = (tester.firstState(createEditEventFinder)
            as CreateEventPageConsumerState)
        .textEditorState;
    assert(editorState.editable, 'Not editable');
    assert(editorState.selection != null, 'No selection');

    await editorState.insertTextAtPosition(descriptionText);

    await editorState.insertNewLine();
    await editorState.insertTextAtCurrentSelection(
      'This is a second line of text with some ',
    );
    final lastSelectable = editorState.getLastSelectable()!;
    final transaction = editorState.transaction;
    transaction.insertText(
      lastSelectable.$1,
      40,
      'bold text',
      attributes: {'bold': true},
    );
    await editorState.apply(transaction);
  }

  Future<void> createNewEvent() async {
    // Create account and create space
    final spaceId = await freshAccountWithSpace();

    // Event Name
    const eventName = 'New Test Event';

    // Open create event page
    await openCreateEvent();

    // Event name text field
    await addEditEventName(eventName);

    // Select date
    await trigger(EventsKeys.eventStartDate);
    await selectDate();

    // Select time
    await trigger(EventsKeys.eventStartTime);
    await selectTime();

    // Add description
    await addEditDescriptionText('Test event description');

    // Select space for event
    await selectSpace(spaceId, SelectSpaceFormField.openKey);

    // Create new event button
    await trigger(EventsKeys.eventCreateEditBtn);

    // Find event name
    await find.text(eventName).should(findsOneWidget);
  }

  Future<void> changeRsvpType() async {
    // Trigger RSVP Going
    await trigger(EventsKeys.eventRsvpGoingBtn);

    await Future.delayed(const Duration(seconds: 2), () {});

    // Trigger RSVP Not Going
    await trigger(EventsKeys.eventRsvpNotGoingBtn);

    await Future.delayed(const Duration(seconds: 2), () {});

    // Trigger RSVP Maybe
    await trigger(EventsKeys.eventRsvpMaybeBtn);
  }

  Future<void> editEvent() async {
    // Trigger appbar menu action button
    await trigger(EventsKeys.appbarMenuActionBtn);

    // Find edit btn and tap on it
    await trigger(EventsKeys.eventEditBtn);

    // Select date
    await trigger(EventsKeys.eventStartDate);
    await selectDate();

    // Select time
    await trigger(EventsKeys.eventStartTime);
    await selectTime();

    // Edit event button
    await trigger(EventsKeys.eventCreateEditBtn);
  }

  Future<void> deleteEvent() async {
    // Trigger appbar menu action button
    await trigger(EventsKeys.appbarMenuActionBtn);

    // Find delete btn and tap on it
    await trigger(EventsKeys.eventDeleteBtn);

    // Find remove btn and tap on it
    await trigger(EventsKeys.eventRemoveBtn);
  }
}

void eventsTests() {
  acterTestWidget('Create Event', (t) async {
    // Create new event
    await t.createNewEvent();
  });

  acterTestWidget('Change Event RSVP Types', (t) async {
    // Create new event
    await t.createNewEvent();

    // Change event RSVP types
    await t.changeRsvpType();
  });

  acterTestWidget('Edit Event', (t) async {
    // Create new event
    await t.createNewEvent();

    // Edit Event
    await t.editEvent();
  });

  acterTestWidget('Delete Event', (t) async {
    // Create new event
    await t.createNewEvent();

    // Delete Event
    await t.deleteEvent();
  });
}
