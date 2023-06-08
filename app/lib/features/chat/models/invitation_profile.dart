import 'package:acter/common/models/profile_data.dart';

class InvitationProfile extends ProfileData {
  final String? roomName;
  final String roomId;
  InvitationProfile(
    super.displayName,
    super.avatar,
    this.roomName,
    this.roomId,
  );
}
