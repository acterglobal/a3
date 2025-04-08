import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements User {
  final String? mockFirstName;
  final String? mockLastName;

  MockUser({this.mockFirstName, this.mockLastName});
}
