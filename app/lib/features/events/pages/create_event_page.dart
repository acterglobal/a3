import 'package:acter/common/actions/select_space.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/widgets/add_event_location_widget.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:acter/features/events/widgets/event_location_list_widget.dart';
import 'package:acter/features/events/providers/event_location_provider.dart';

final _log = Logger('a3::cal_event::create');

const createEditEventKey = Key('create-edit-event');

class CreateEventPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  final CalendarEvent? templateEvent;

  const CreateEventPage({
    super.key = createEditEventKey,
    this.initialSelectedSpace,
    this.templateEvent,
  });

  @override
  ConsumerState<CreateEventPage> createState() =>
      CreateEventPageConsumerState();
}

class CreateEventPageConsumerState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'event form key');
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

  bool _isJitsiEnabled = false;

  void _setFromTemplate(CalendarEvent event) {
    // title
    _eventNameController.text = event.title();
    // description
    final desc = event.description();
    if (desc != null) {
      textEditorState = EditorState(
        document: ActerDocumentHelpers.parse(
          desc.body(),
          htmlContent: desc.formatted(),
        ),
      );
    } else {
      textEditorState = EditorState.blank();
    }

    // Getting start and end date time
    final dartStartTime = toDartDatetime(event.utcStart());
    final dartEndTime = toDartDatetime(event.utcEnd());

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
    _setSpaceId(event.roomIdStr());
    setState(() {});
  }

  void _setSpaceId(String spaceId) {
    ref.read(selectedSpaceIdProvider.notifier).state = spaceId;
  }

  @override
  void initState() {
    super.initState();
    widget.templateEvent.map(
      (p0) => WidgetsBinding.instance.addPostFrameCallback((Duration dur) {
        _setFromTemplate(p0);
      }),
      orElse: () {
        widget.initialSelectedSpace.map((p0) {
          WidgetsBinding.instance.addPostFrameCallback((Duration dur) {
            _setSpaceId(p0);
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppbar(), body: _buildBody());
  }

  // Appbar
  AppBar _buildAppbar() {
    return AppBar(
      title: Text(
        L10n.of(context).eventCreate,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  // Body
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _eventNameField(),
              const SizedBox(height: 10),
              _eventDateAndTime(),
              const SizedBox(height: 10),
              _buildEventLocationWidget(),
              const SizedBox(height: 10),
              _eventDescriptionField(),
              const SizedBox(height: 10),
              SelectSpaceFormField(
                canCheck: (m) => m?.canString('CanPostEvent') == true,
              ),
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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.eventName),
        const SizedBox(height: 10),
        TextFormField(
          key: EventsKeys.eventNameTextField,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _eventNameController,
          decoration: InputDecoration(hintText: lang.nameOfTheEvent),
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterEventName
                      : null,
        ),
      ],
    );
  }

  // Event location field
  Widget _buildEventLocationWidget() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.map_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
            title: Text(L10n.of(context).eventLocations),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              tooltip: L10n.of(context).addLocation,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: true,
                  showDragHandle: true,
                  useSafeArea: true,
                  builder:
                      (context) => EventLocationListWidget(
                        onAdd: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            isDismissible: true,
                            enableDrag: true,
                            showDragHandle: true,
                            useSafeArea: true,
                            builder:
                                (context) => AddEventLocationWidget(
                                  onAdd: (location) {
                                    ref
                                        .read(eventLocationsProvider.notifier)
                                        .addLocation(location);
                                    Navigator.pop(context);
                                  },
                                ),
                          );
                        },
                      ),
                );
              },
            ),
          ),
          _buildJitsiCallLinkWidget(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Jitsi call link field
  Widget _buildJitsiCallLinkWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: _isJitsiEnabled,
            onChanged: (value) {
        setState(() {
          _isJitsiEnabled = value;
            });
          },
        ),
      ),
      Text(L10n.of(context).createJitsiCallLink),
      const SizedBox(width: 10),
        
    ]);
  }

  // Create Jitsi call link
  String _createJitsiCallLink(String title) {   
    // Generate a random 10-digit number
    final random = DateTime.now().millisecondsSinceEpoch % 10000000000;
    // Format the number to ensure it's 10 digits by padding with zeros if needed
    final formattedNumber = random.toString().padLeft(10, '0');
    // Clean the title by removing spaces and special characters
    final cleanTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'https://meet.jit.si/$cleanTitle$formattedNumber';
  }

  // Event date and time field
  Widget _eventDateAndTime() {
    final lang = L10n.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.startDate),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventStartDate,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startDateController,
                    decoration: InputDecoration(
                      hintText: lang.selectDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: true),
                    // required field, space not allowed
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
                                ? lang.startDateRequired
                                : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.startTime),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventStartTime,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _startTimeController,
                    decoration: InputDecoration(
                      hintText: lang.selectTime,
                      suffixIcon: const Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: true),
                    // required field, space not allowed
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
                                ? lang.startTimeRequired
                                : null,
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
                  Text(lang.endDate),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventEndDate,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endDateController,
                    decoration: InputDecoration(
                      hintText: lang.selectDate,
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    onTap: () => _selectDate(isStartDate: false),
                    // required field, space not allowed
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
                                ? lang.endDateRequired
                                : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.endTime),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: EventsKeys.eventEndTime,
                    readOnly: true,
                    keyboardType: TextInputType.text,
                    controller: _endTimeController,
                    decoration: InputDecoration(
                      hintText: lang.selectTime,
                      suffixIcon: const Icon(Icons.access_time_outlined),
                    ),
                    onTap: () => _selectTime(isStartTime: false),
                    // required field, space not allowed
                    validator:
                        (val) =>
                            val == null || val.trim().isEmpty
                                ? lang.endTimeRequired
                                : null,
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
    DateTime initialDate = isStartDate ? _selectedStartDate : _selectedEndDate;
    DateTime firstDate = DateTime.now();
    if (initialDate < firstDate) {
      initialDate = firstDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: HtmlEditor(
            key: EventsKeys.eventDescriptionTextField,
            editorState: textEditorState,
            editable: true,
            onChanged: (body, html) {
              textEditorState = EditorState(
                document: ActerDocumentHelpers.parse(body, htmlContent: html),
              );
            },
          ),
        ),
      ],
    );
  }

  // Action buttons
  Widget _eventActionButtons() {
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: context.pop, child: Text(lang.cancel)),
        const SizedBox(width: 10),
        ActerPrimaryActionButton(
          key: EventsKeys.eventCreateEditBtn,
          onPressed: _handleCreateEvent,
          child: Text(lang.eventCreate),
        ),
      ],
    );
  }

  // Create event handler
  Future<void> _handleCreateEvent() async {
    final lang = L10n.of(context);
    String? spaceId = ref.read(selectedSpaceIdProvider);
    spaceId ??= await selectSpace(
      context: context,
      ref: ref,
      canCheck: (m) => m?.canString('CanPostEvent') == true,
    );
    if (!mounted) return;

    if (spaceId == null) {
      EasyLoading.showError(
        lang.pleaseSelectSpace,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    EasyLoading.show(status: lang.creatingCalendarEvent);
    try {
      // Replacing hours and minutes from DateTime
      // Start Date
      final startDateTime = calculateDateTimeWithHours(
        _selectedStartDate,
        _selectedStartTime,
      );
      // End Date
      final endDateTime = calculateDateTimeWithHours(
        _selectedEndDate,
        _selectedEndTime,
      );

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

      // Add locations to the event
      final locations = ref.read(eventLocationsProvider);
      for (final location in locations) {
        if (location.type == LocationType.physical) {
          draft.physicalLocation(location.name, '', '', '', '',location.address,location.note);
        }
        if (location.type == LocationType.virtual) {
          draft.virtualLocation(location.name, '', '',location.url ?? '',location.note);
        }
      }
      
      // Add Jitsi link if enabled
      if (_isJitsiEnabled) {
        final jitsiLink = _createJitsiCallLink(title);
        draft.virtualLocation(lang.jitsiMeeting, '', '', jitsiLink, '');
      }

      final eventId = (await draft.send()).toString();
      final client = await ref.read(alwaysClientProvider.future);
      final calendarEvent = await client.waitForCalendarEvent(eventId, null);
      await autosubscribe(ref: ref, objectId: eventId, lang: lang);

      /// Event is created, set RSVP status to `Yes` by default for host.
      final rsvpManager = await calendarEvent.rsvps();
      final rsvpDraft = rsvpManager.rsvpDraft();
      rsvpDraft.status('yes');
      await rsvpDraft.send();
      _log.info('Created Calendar Event: $eventId');

      // Clear event locations after successful creation
      ref.read(eventLocationsProvider.notifier).clearLocations();

      EasyLoading.dismiss();

      if (mounted) {
        Navigator.pop(context);
        context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': eventId},
        );
      }
    } catch (e, s) {
      _log.severe('Failed to create calendar event', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorCreatingCalendarEvent(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
