import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateEditEventPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  final String? calendarId;

  const CreateEditEventPage({
    super.key,
    this.initialSelectedSpace,
    this.calendarId,
  });

  @override
  ConsumerState<CreateEditEventPage> createState() =>
      _CreateEditEventPageConsumerState();
}

class _CreateEditEventPageConsumerState
    extends ConsumerState<CreateEditEventPage> {
  final _eventFromKey = GlobalKey<FormState>();
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
      body: _buildBody(),
    );
  }

  // Appbar
  AppBar _buildAppbar() {
    return AppBar(
      title: Text(
        widget.calendarId != null ? 'Edit event' : 'Create new event',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  // Body
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _eventFromKey,
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
              const SelectSpaceFormField(canCheck: 'CanPostEvent'),
              const SizedBox(height: 20),
              _eventActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Event name field
  Widget _eventNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Event Name'),
        const SizedBox(height: 10),
        TextFormField(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _eventNameController,
          decoration: const InputDecoration(
            hintText: 'Name of the event',
          ),
          validator: (value) {
            if (value != null && value.isEmpty) {
              return 'Please enter event name';
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
                  const Text('Start Date'),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      hintText: 'Select date',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: true),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Start date required!';
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
                  const Text('Start Time'),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startTimeController,
                    decoration: const InputDecoration(
                      hintText: 'Select time',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: true),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'End date required!';
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
                  const Text('End Date'),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      hintText: 'Select date',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: false),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Start time required!';
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
                  const Text('End Time'),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endTimeController,
                    decoration: const InputDecoration(
                      hintText: 'Select time',
                      suffixIcon: Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: false),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'End time required!';
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
    if (date != null) {
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
          EasyLoading.showToast(
            'Please select valid end date',
            toastPosition: EasyLoadingToastPosition.bottom,
          );
        }
      }
      setState(() {});
    }
  }

  // Selecting Time
  Future<void> _selectTime({required bool isStartTime}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
    );
    if (time != null) {
      if (!mounted) return;
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
          EasyLoading.showToast(
            'Please select valid end time',
            toastPosition: EasyLoadingToastPosition.bottom,
          );
        } else {
          _selectedEndTime = time;
          _endTimeController.text = _selectedEndTime.format(context);
        }
      }
      setState(() {});
    }
  }

  // Description field
  Widget _eventDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description'),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: HtmlEditor(
            editorState: textEditorState,
            editable: true,
            autoFocus: false,
            // we manage the auto focus manually
            shrinkWrap: true,
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
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: widget.calendarId != null
              ? _handleUpdateEvent
              : _handleCreateEvent,
          child:
              Text(widget.calendarId != null ? 'Update Event' : 'Create Event'),
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
    if (!(_eventFromKey.currentState!.validate())) return;

    EasyLoading.show(status: 'Creating Calendar Event', dismissOnTap: false);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      if (spaceId == null) {
        EasyLoading.showError(
          'Please select space',
          duration: const Duration(seconds: 2),
        );
        return;
      }

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
      final rsvpManager = await calendarEvent.rsvpManager();
      final rsvpDraft = rsvpManager.rsvpDraft();
      rsvpDraft.status('yes');
      await rsvpDraft.send();
      debugPrint('Created Calendar Event: ${eventId.toString()}');
      EasyLoading.dismiss();
      if (context.mounted) {
        ref.invalidate(calendarEventProvider);
        context.pop();
        context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': eventId.toString()},
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error Creating Calendar Event: $e');
      return;
    }
  }

  // Edit event handler
  Future<void> _handleUpdateEvent() async {
    if (!(_eventFromKey.currentState!.validate())) return;

    EasyLoading.show(status: 'Updating Event', dismissOnTap: false);
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
      debugPrint('Calendar Event updated $eventId');

      EasyLoading.dismiss();
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error updating event: $e');
      return;
    }
  }
}
