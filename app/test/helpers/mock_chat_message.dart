import 'package:flutter_chat_types/flutter_chat_types.dart';

int id = 0;

TextMessage buildMockTextMessage() {
  id += 1;
  return TextMessage(
    author: User(id: '$id-user'),
    id: '$id-msg',
    text: 'text of $id',
  );
}
