// Mock class for the avatar info if needed
import 'package:acter_avatar/acter_avatar.dart';
import 'package:mocktail/mocktail.dart';

class MockAvatarInfo extends Mock implements AvatarInfo {
  @override
  String get uniqueId => 'mockUniqueId';

  @override
  TooltipStyle get tooltip => TooltipStyle.Combined;

}
