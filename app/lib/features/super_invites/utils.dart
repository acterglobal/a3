import 'dart:math';

String generateInviteCodeName(String? roomName) {
  String prefix =
      roomName?.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase() ?? '';

  final rng = Random();

  int end = 5;
  if (prefix.isEmpty) {
    end = 8;
  } else if (prefix.length > 8) {
    prefix = prefix.substring(0, 8);
    end = 3;
  } else if (prefix.length > 4) {
    end = 3;
  }

  List<String> name = [prefix];
  for (var i = 0; i < end; i++) {
    name.add(rng.nextInt(10).toString());
  }
  return name.join('');
}
