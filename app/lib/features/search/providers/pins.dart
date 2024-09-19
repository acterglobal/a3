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
  final pins = await ref.watch(pinListProvider(null).future);
  final search = ref.watch(searchValueProvider).toLowerCase();
  final List<PinDetails> finalPins = pins
      .where((pin) {
        if (search.isEmpty) return true;
        return pin.title().toLowerCase().contains(search);
      })
      .map(
        (pin) => PinDetails(
          pin.title(),
          pin.eventIdStr(),
          icon: Icon(
            pin.isLink() ? Atlas.link_chain_thin : Atlas.document_thin,
            size: 12,
          ),
        ),
      )
      .toList();
  finalPins.sort((a, b) => a.name.compareTo(b.name));
  return finalPins;
});
