import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

typedef OnSelectedFn =
    void Function(
      PublicSearchResultItem spaceSearchResult,
      String? searchServerName,
    );

typedef OnSelectedInnerFn =
    void Function(PublicSearchResultItem spaceSearchResult);

class Next {
  final bool isStart;
  final String? next;

  const Next({this.isStart = false, this.next});
}
