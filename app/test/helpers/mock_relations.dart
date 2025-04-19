import 'package:flutter_test/flutter_test.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_basics.dart';
import 'mock_tasks_providers.dart';

class MockFfiListSpaceRelation extends Mock
    implements FfiListSpaceRelation, Iterator<SpaceRelation> {
  final List<SpaceRelation> _items;

  MockFfiListSpaceRelation({List<SpaceRelation> items = const []})
    : _items = items;

  @override
  Iterator<SpaceRelation> get iterator => _items.iterator;

  @override
  Iterable<T> map<T>(T Function(SpaceRelation e) toElement) =>
      _items.map(toElement);
}

class MockSpaceRelation extends Mock implements SpaceRelation {
  final String _roomId;
  final bool _suggested;
  final String _targetType;
  final List<String> _via;

  MockSpaceRelation({
    required String roomId,
    bool suggested = false,
    String targetType = 'Space',
    List<String> via = const [],
  }) : _roomId = roomId,
       _suggested = suggested,
       _targetType = targetType,
       _via = via;

  @override
  MockRoomId roomId() => MockRoomId(_roomId);

  @override
  bool suggested() => _suggested;

  @override
  String targetType() => _targetType;

  @override
  MockFfiListFfiString via() => MockFfiListFfiString(items: _via);
}

class MockFfiListSpaceHierarchyRoomInfo extends Mock
    implements FfiListSpaceHierarchyRoomInfo {
  final List<SpaceHierarchyRoomInfo> _items;

  MockFfiListSpaceHierarchyRoomInfo({
    List<SpaceHierarchyRoomInfo> items = const [],
  }) : _items = items;

  @override
  Iterator<SpaceHierarchyRoomInfo> get iterator => _items.iterator;

  @override
  List<SpaceHierarchyRoomInfo> toList({bool growable = true}) =>
      List.from(_items, growable: growable);
}

class MockSpaceRelations extends Mock implements SpaceRelations {
  final String _roomId;
  final MockSpaceRelation? _mainParent;
  final List<MockSpaceRelation> _otherParents;
  final List<MockSpaceRelation> _children;
  final List<SpaceHierarchyRoomInfo> _hierarchy;

  MockSpaceRelations({
    required String roomId,
    MockSpaceRelation? mainParent,
    List<MockSpaceRelation> otherParents = const [],
    List<MockSpaceRelation> children = const [],
    List<SpaceHierarchyRoomInfo> hierarchy = const [],
  }) : _roomId = roomId,
       _mainParent = mainParent,
       _otherParents = otherParents,
       _children = children,
       _hierarchy = hierarchy;

  @override
  String roomIdStr() => _roomId;

  @override
  MockSpaceRelation? mainParent() => _mainParent;

  @override
  MockFfiListSpaceRelation otherParents() =>
      MockFfiListSpaceRelation(items: _otherParents);

  @override
  MockFfiListSpaceRelation children() =>
      MockFfiListSpaceRelation(items: _children);

  @override
  Future<FfiListSpaceHierarchyRoomInfo> queryHierarchy() async =>
      MockFfiListSpaceHierarchyRoomInfo(items: _hierarchy);
}
