import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final convoProvider =
    AsyncNotifierProvider.family<AsyncConvoNotifier, Convo?, Convo>(
  () => AsyncConvoNotifier(),
);

// Chat Providers
final chatProfileDataProvider =
    FutureProvider.family<ProfileData, Convo>((ref, convo) async {
  // this ensure we are staying up to dates on updates to convo
  final chat = await ref.watch(convoProvider(convo).future);
  if (chat == null) {
    throw 'Chat not accessible';
  }
  final profile = chat.getProfile();
  final displayName = await profile.getDisplayName();
  final isDm = chat.isDm();
  if (!profile.hasAvatar()) {
    return ProfileData(displayName.text(), null, isDm: isDm);
  }
  final sdk = await ref.watch(sdkProvider.future);
  final size = sdk.api.newThumbSize(48, 48);
  final avatar = await profile.getAvatar(size);
  return ProfileData(displayName.text(), avatar.data(), isDm: isDm);
});

final latestMessageProvider =
    StateNotifierProvider.family<LatestMsgNotifier, RoomMessage?, Convo>(
        (ref, convo) {
  return LatestMsgNotifier(ref, convo);
});

final chatProfileDataProviderById =
    FutureProvider.family<ProfileData, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  return await ref.watch(chatProfileDataProvider(chat).future);
});

/// Provider the profile data of a the given space, keeps up to date with underlying client
final chatsProvider =
    StateNotifierProvider<ChatRoomsListNotifier, List<Convo>>((ref) {
  final client = ref.watch(alwaysClientProvider);
  return ChatRoomsListNotifier(ref: ref, client: client);
});

final chatProvider =
    FutureProvider.family<Convo, String>((ref, roomIdOrAlias) async {
  final client = ref.watch(alwaysClientProvider);
  // FIXME: fallback to fetching a public data, if not found
  return await client.convo(roomIdOrAlias);
});

final chatMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, roomIdOrAlias) async {
  final chat = await ref.watch(chatProvider(roomIdOrAlias).future);
  final members = await chat.activeMembers();
  return members.toList();
});

final relatedChatsProvider = FutureProvider.autoDispose
    .family<List<Convo>, String>((ref, spaceId) async {
  return (await ref.watch(spaceRelationsOverviewProvider(spaceId).future))
      .knownChats;
});

final selectedChatIdProvider =
    NotifierProvider<SelectedChatIdNotifier, String?>(
  () => SelectedChatIdNotifier(),
);

// Member Providers
final memberProfileByInfoProvider =
    FutureProvider.family<ProfileData, MemberInfo>((ref, memberInfo) async {
  final member = await ref.read(memberProvider(memberInfo).future);
  if (member == null) {
    throw 'Member not found';
  }
  return await ref.watch(memberProfileProvider(member).future);
});

final memberProfileProvider =
    FutureProvider.family<ProfileData, Member>((ref, member) async {
  UserProfile profile = member.getProfile();
  final displayName = profile.getDisplayName();
  final sdk = await ref.watch(sdkProvider.future);
  final size = sdk.api.newThumbSize(62, 60);
  final avatar = await profile.getAvatar(size);
  return ProfileData(displayName, avatar.data());
});

final memberProvider =
    FutureProvider.family<Member?, MemberInfo>((ref, memberInfo) async {
  try {
    final convo = await ref.watch(chatProvider((memberInfo.roomId!)).future);
    return await convo.getMember(memberInfo.userId);
  } catch (e) {
    throw e.toString();
  }
});
