import 'package:acter/features/deep_linking/types.dart';

class UriParseError extends Error {}

class SchemeNotSupported extends UriParseError {
  final String scheme;

  SchemeNotSupported({required this.scheme});
}

class ParsingFailed extends UriParseError {}

UriParseResult? parseUri(Uri uri) => switch (uri.scheme) {
      'matrix' => _parseMatrixUri(uri),
      _ => throw SchemeNotSupported(scheme: uri.scheme),
    };

UriParseResult? _parseMatrixUri(Uri uri) {
  final path = uri.pathSegments.first;
  return switch (path) {
    'r' => UriParseResult(
        type: LinkType.roomAlias,
        via: uri.queryParametersAll['via'] ?? [],
        target: '#${uri.pathSegments.last}',
      ),
    'u' => UriParseResult(
        type: LinkType.userId,
        via: uri.queryParametersAll['via'] ?? [],
        target: '@${uri.pathSegments.last}',
      ),
    'roomid' => _parseMatrixUriRoomId(uri),
    _ => throw ParsingFailed(),
  };
}

UriParseResult? _parseMatrixUriRoomId(Uri uri) {
  final path = uri.pathSegments;
  if (path.length == 4) {
    final roomId = path[1];
    final eventId = path[3];
    return UriParseResult(
      type: LinkType.chatEvent,
      via: uri.queryParametersAll['via'] ?? [],
      target: '\$$eventId',
      roomId: '!$roomId',
    );
  } else {
    return UriParseResult(
      type: LinkType.roomId,
      via: uri.queryParametersAll['via'] ?? [],
      target: '!${uri.pathSegments.last}',
    );
  }
}
