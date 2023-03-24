import 'dart:typed_data';

class ProfileData {
  final String displayName;
  final Uint8List? avatar;
  const ProfileData(this.displayName, this.avatar);
}
