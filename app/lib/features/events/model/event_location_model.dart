enum LocationType { physical, virtual }

class EventLocationDraft {
  final String name;
  final LocationType type;
  final String? url;
  final String? address;
  final String? note;

  EventLocationDraft({
    required this.name,
    required this.type,
    this.url,
    this.address,
    this.note,
  });
}