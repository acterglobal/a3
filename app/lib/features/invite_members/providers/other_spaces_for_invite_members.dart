import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// List of spaces other than current space and it’s parent space
final otherSpacesForInviteMembersProvider = FutureProvider.autoDispose
    .family<List<Space>, String>((ref, spaceId) async {
      //GET LIST OF ALL SPACES
      final allSpaces = ref.watch(spacesProvider);

      //GET PARENT SPACE
      final parentSpaces = await ref.watch(parentIdsProvider(spaceId).future);

      //GET LIST OF SPACES EXCLUDING PARENT SPACES && EXCLUDING CURRENT SPACE
      final spacesExcludingParentSpacesAndCurrentSpace =
          allSpaces.where((space) {
            final roomId = space.getRoomIdStr();
            return !parentSpaces.any((p) => p == roomId) && roomId != spaceId;
          }).toList();

      return spacesExcludingParentSpacesAndCurrentSpace;
    });
