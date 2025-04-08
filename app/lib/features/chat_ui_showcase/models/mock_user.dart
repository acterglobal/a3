import 'package:mocktail/mocktail.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class MockUser extends Mock implements User {
  final String mockUserId;

  MockUser({required this.mockUserId});

  @override
  String get id => mockUserId;
}
