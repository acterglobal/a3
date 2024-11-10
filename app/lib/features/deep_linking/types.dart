enum LinkType {
  roomId,
  roomAlias,
  userId,
  chatEvent,
}

class UriParseResult {
  final LinkType type;
  final List<String> via;
  final String target;
  final String? roomId;

  UriParseResult({
    required this.type,
    required this.via,
    required this.target,
    this.roomId,
  });
}
