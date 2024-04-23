import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::event::createOrEdit');

const createEditEventKey = Key('create-edit-event');

class CreateEditEventPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  final String? calendarId;

  const CreateEditEventPage({
    super.key = createEditEventKey,
    this.initialSelectedSpace,
    this.calendarId,
  });

  @override
  ConsumerState<CreateEditEventPage> createState() =>
      CreateEditEventPageConsumerState();
}

class CreateEditEventPageConsumerState
    extends ConsumerState<CreateEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  DateTime _selectedEndDate = DateTime.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();
  EditorState textEditorState = EditorState.blank();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      // if calendarId is not null that means Edit Event
      if (widget.calendarId != null) {
        _setEditEventData();
      }
      // if calendarId is null that means Create Event
      else if (widget.initialSelectedSpace != null) {
        final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
        parentNotifier.state = widget.initialSelectedSpace;
      }
    });
  }

  // Apply existing data to fields
  void _setEditEventData() async {
    final calendarEvent =
        await ref.read(calendarEventProvider(widget.calendarId!).future);
    if (!mounted) return;
    // setting data to variables
    _eventNameController.text = calendarEvent.title();
    final document = calendarEvent.description() != null &&
            calendarEvent.description()!.formatted() != null
        ? ActerDocumentHelpers.fromHtml(
            calendarEvent.description()!.formatted()!,
          )
        : ActerDocumentHelpers.fromMarkdown(
            calendarEvent.description()!.body(),
          );
    textEditorState = EditorState(document: document);

    // Getting start and end date time
    final dartStartTime = toDartDatetime(calendarEvent.utcStart());
    final dartEndTime = toDartDatetime(calendarEvent.utcEnd());

    // Setting data to variables for start date
    _selectedStartDate = dartStartTime.toLocal();
    _selectedStartTime = TimeOfDay.fromDateTime(_selectedStartDate);
    _startDateController.text = eventDateFormat(_selectedStartDate);
    _startTimeController.text = _selectedStartTime.format(context);

    // Setting data to variables for end date
    _selectedEndDate = dartEndTime.toLocal();
    _selectedEndTime = TimeOfDay.fromDateTime(_selectedEndDate);
    _endDateController.text = eventDateFormat(_selectedEndDate);
    _endTimeController.text = _selectedEndTime.format(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: BaseBody(child: _buildBody()),
    );
  }

  // Appbar
  AppBar _buildAppbar() {
    return AppBar(
      title: Text(
        widget.calendarId != null
            ? L10n.of(context).eventEdit
            : L10n.of(context).eventCreate,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  // Body
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _eventNameField(),
            const SizedBox(height: 10),
            _eventDateAndTime(),
            const SizedBox(height: 10),
            _eventDescriptionField(),
            const SizedBox(height: 10),
            if (widget.calendarId == null)
              const SelectSpaceFormField(canCheck: 'CanPostEvent'),
            const SizedBox(height: 20),
            _eventActionButtons(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Event name field
  Widget _eventNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).eventName),
        const SizedBox(height: 10),
        TextFormField(
          key: EventsKeys.eventNameTextField,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _eventNameController,
          decoration: InputDecoration(
            hintText: L10n.of(context).nameOfTheEvent,
          ),
          validator: (value) {
            if (value != null && value.isEmpty) {
              return L10n.of(context).pleaseEnterEventName;
            }
            return null;
          },
        ),
      ],
    );
  }

  // Event date and time field
  Widget _eventDateAndTime() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context).startDate),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventStartDate,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startDateController,
                    decoration: InputDecoration(
                      hintText: L10n.of(context).selectDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: true),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return L10n.of(context).startDateRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context).startTime),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventStartTime,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startTimeController,
                    decoration: InputDecoration(
                      hintText: L10n.of(context).selectTime,
                      suffixIcon: const Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: true),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return L10n.of(context).startTimeRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context).endDate),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventEndDate,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endDateController,
                    decoration: InputDecoration(
                      hintText: L10n.of(context).selectDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: false),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return L10n.of(context).endDateRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context).endTime),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventEndTime,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endTimeController,
                    decoration: InputDecoration(
                      hintText: L10n.of(context).selectTime,
                      suffixIcon: const Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: false),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return L10n.of(context).endTimeRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Selecting date
  Future<void> _selectDate({required bool isStartDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().addYears(1),
    );
    if (date == null || !mounted) return;
    if (isStartDate) {
      _selectedStartDate = date;
      _startDateController.text = eventDateFormat(date);
      // if end date is empty and if start date is same or after end date
      if (_endDateController.text.isEmpty ||
          date.isSameOrAfter(_selectedEndDate)) {
        _selectedEndDate = date;
        _endDateController.text = eventDateFormat(date);
      }
    } else {
      // if date is same or after start date
      if (date.isSameOrAfter(_selectedStartDate)) {
        _selectedEndDate = date;
        _endDateController.text = eventDateFormat(date);
        // When user change date that time end time is reset
        _endTimeController.text = '';
      } else {
        EasyLoading.showToast(L10n.of(context).pleaseSelectValidEndDate);
      }
    }
    setState(() {});
  }

  // Selecting Time
  Future<void> _selectTime({required bool isStartTime}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
    );
    if (time == null || !mounted) return;
    if (isStartTime) {
      _selectedStartTime = time;
      _startTimeController.text = _selectedStartTime.format(context);
      // select end time after one of start time
      if (_endTimeController.text.isEmpty) {
        _selectedEndTime = time.replacing(hour: _selectedStartTime.hour + 1);
        _endTimeController.text = _selectedEndTime.format(context);
      }
    } else {
      // Checking if end time is before start time
      final double startTime = _selectedStartTime.toDouble();
      final double endTime = time.toDouble();
      if (_selectedStartDate.isSameDay(_selectedEndDate) &&
          startTime > endTime) {
        EasyLoading.showToast(L10n.of(context).pleaseSelectValidEndTime);
      } else {
        _selectedEndTime = time;
        _endTimeController.text = _selectedEndTime.format(context);
      }
    }
    setState(() {});
  }

  // Description field
  Widget _eventDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).description),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: HtmlEditor(
            key: EventsKeys.eventDescriptionTextField,
            editorState: textEditorState,
            editable: true,
            autoFocus: false,
            onChanged: (body, html) {
              final document = html != null
                  ? ActerDocumentHelpers.fromHtml(html)
                  : ActerDocumentHelpers.fromMarkdown(body);
              textEditorState = EditorState(document: document);
            },
          ),
        ),
      ],
    );
  }

  // Action buttons
  Widget _eventActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: context.pop,
          child: Text(L10n.of(context).cancel),
        ),
        const SizedBox(width: 10),
        ActerPrimaryActionButton(
          key: EventsKeys.eventCreateEditBtn,
          onPressed: widget.calendarId != null
              ? _handleUpdateEvent
              : _handleCreateEvent,
          child: Text(
            widget.calendarId != null
                ? L10n.of(context).eventUpdate
                : L10n.of(context).eventCreate,
          ),
        ),
      ],
    );
  }

  DateTime _calculateStartDate() {
    // Replacing hours and minutes from DateTime
    return _selectedStartDate.copyWith(
      hour: _selectedStartTime.hour,
      minute: _selectedStartTime.minute,
    );
  }

  DateTime _calculateEndDate() {
    // Replacing hours and minutes from DateTime
    return _selectedEndDate.copyWith(
      hour: _selectedEndTime.hour,
      minute: _selectedEndTime.minute,
    );
  }

  // Create event handler
  Future<void> _handleCreateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final spaceId = ref.read(selectedSpaceIdProvider);
    if (spaceId == null) {
      EasyLoading.showError(
        L10n.of(context).pleaseSelectSpace,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    EasyLoading.show(status: L10n.of(context).creatingCalendarEvent);
    try {
      // Replacing hours and minutes from DateTime
      // Start Date
      final startDateTime = _calculateStartDate();
      // End Date
      final endDateTime = _calculateEndDate();

      // Convert utc time zone
      final utcStartDateTime = startDateTime.toUtc().toIso8601String();
      final utcEndDateTime = endDateTime.toUtc().toIso8601String();

      // Creating calendar event
      final space = await ref.read(spaceProvider(spaceId).future);
      final draft = space.calendarEventDraft();
      final title = _eventNameController.text;
      // Description text
      final plainDescription = textEditorState.intoMarkdown();
      final htmlBodyDescription = textEditorState.intoHtml();
      draft.title(title);
      draft.utcStartFromRfc3339(utcStartDateTime);
      draft.utcEndFromRfc3339(utcEndDateTime);
      draft.descriptionHtml(plainDescription, htmlBodyDescription);
      final eventId = await draft.send();
      final client = ref.read(alwaysClientProvider);
      final calendarEvent =
          await client.waitForCalendarEvent(eventId.toString(), null);

      /// Event is created, set RSVP status to `Yes` by default for host.
      final rsvpManager = await calendarEvent.rsvps();
      final rsvpDraft = rsvpManager.rsvpDraft();
      rsvpDraft.status('yes');
      await rsvpDraft.send();
      _log.info('Created Calendar Event: ${eventId.toString()}');

      EasyLoading.dismiss();

      ref.invalidate(calendarEventProvider(eventId.toString())); // edit page
      ref.invalidate(spaceEventsProvider(spaceId)); // events page in space

      if (mounted) {
        context.pop();
        context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': eventId.toString()},
        );
      }
    } catch (e, st) {
      _log.severe('Failed to create calendar event', e, st);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).errorCreatingCalendarEvent(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Edit event handler
  Future<void> _handleUpdateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    EasyLoading.show(status: L10n.of(context).updatingEvent);
    try {
      // We always have calendar object at this stage.
      final calendarEvent =
          await ref.read(calendarEventProvider(widget.calendarId!).future);

      // Replacing hours and minutes from DateTime
      // Start Date
      final startDateTime = _calculateStartDate();
      // End Date
      final endDateTime = _calculateEndDate();

      // Convert UTC time zone
      final utcStartDateTime = startDateTime.toUtc().toIso8601String();
      final utcEndDateTime = endDateTime.toUtc().toIso8601String();

      // Updating calender event
      final title = _eventNameController.text;
      final plainDescription = textEditorState.intoMarkdown();
      final htmlBodyDescription = textEditorState.intoHtml();
      final updateBuilder = calendarEvent.updateBuilder();
      updateBuilder.title(title);
      updateBuilder.utcStartFromRfc3339(utcStartDateTime);
      updateBuilder.utcEndFromRfc3339(utcEndDateTime);
      updateBuilder.descriptionHtml(plainDescription, htmlBodyDescription);
      final eventId = await updateBuilder.send();
      _log.info('Calendar Event updated $eventId');

      EasyLoading.dismiss();

      ref.invalidate(calendarEventProvider(eventId.toString())); // edit page
      final spaceId = calendarEvent.roomIdStr();
      ref.invalidate(spaceEventsProvider(spaceId)); // events page in space

      if (mounted) context.pop();
    } catch (e, st) {
      _log.severe('Failed to update calendar event', e, st);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).errorUpdatingEvent(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
