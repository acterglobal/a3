import 'package:mocktail/mocktail.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class MockUser extends Mock implements User {
  final String mockDisplayName;

  MockUser({required this.mockDisplayName});

  @override
  String get id => mockDisplayName;
}
