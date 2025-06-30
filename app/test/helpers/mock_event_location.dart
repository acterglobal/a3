import 'package:acter/features/events/providers/notifiers/event_location_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockEventDraftLocationsNotifier extends EventDraftLocationsNotifier {
  MockEventDraftLocationsNotifier() : super();
}

class MockEventLocationInfo extends Mock implements EventLocationInfo {
  final String? _name;
  final String _locationType;
  final String? _address;
  final String? _uri;
  final String? _notes;
  final TextMessageContent? _description;
  final String? _coordinates;

  MockEventLocationInfo({
    String? name,
    String? locationType,
    String? address,
    String? uri,
    String? notes,
    TextMessageContent? description,
    String? coordinates,
  })  : _name = name,
        _locationType = locationType ?? 'physical',
        _address = address,
        _uri = uri,
        _notes = notes,
        _description = description,
        _coordinates = coordinates;

  @override
  String? name() => _name;

  @override
  String locationType() => _locationType;

  @override
  String? address() => _address;

  @override
  String? uri() => _uri;

  @override
  String? notes() => _notes;

  @override
  TextMessageContent? description() => _description;

  @override
  String? coordinates() => _coordinates;
}

class MockFfiListEventLocationInfo extends Mock implements FfiListEventLocationInfo {
  final List<EventLocationInfo> items;

  MockFfiListEventLocationInfo({this.items = const []});

  @override
  List<EventLocationInfo> toList({bool growable = false}) => items;
}