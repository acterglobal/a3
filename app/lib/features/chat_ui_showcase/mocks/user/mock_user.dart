import 'package:mocktail/mocktail.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class MockUser extends Mock implements User {
  final String mockUserId;
  final String mockDisplayName;

  MockUser({required this.mockUserId, required this.mockDisplayName});

  @override
  String get id => mockUserId;

  String get displayName => mockDisplayName;
}
