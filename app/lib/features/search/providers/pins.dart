import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/search/model/search_term_delegate.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

class PinDetails extends SearchTermDelegate {
  final Icon icon;

  const PinDetails(
    String name,
    String navigationTargetId, {
    required this.icon,
  }) : super(name: name, navigationTargetId: navigationTargetId);
}

final AutoDisposeFutureProvider<List<PinDetails>> pinsFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final pins = await ref.watch(pinsProvider.future);
  final List<PinDetails> finalPins = [];
  final searchValue = ref.watch(searchValueProvider).toLowerCase();

  for (final pin in pins) {
    final pinTitle = pin.title();
    final pinId = pin.eventIdStr();
    final isLink = pin.isLink();
    if (searchValue.isNotEmpty) {
      if (!(pinTitle.toLowerCase()).contains(searchValue)) {
        continue;
      }
    }
    finalPins.add(
      PinDetails(
        pinTitle,
        pinId,
        icon: isLink
            ? const Icon(Atlas.link_chain_thin, size: 12)
            : const Icon(Atlas.document_thin, size: 12),
      ),
    );
  }

  finalPins.sort((a, b) {
    return a.name.compareTo(b.name);
  });
  return finalPins;
});
