import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/search/model/base_delegate.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinDetails extends BaseDelegate {
  final Icon icon;
  const PinDetails(String navigationTarget, String name, {required this.icon})
      : super(navigationTarget: navigationTarget, name: name);
}

final AutoDisposeFutureProvider<List<PinDetails>> pinsFoundProvider =
    FutureProvider.autoDispose((ref) async {
  final pins = await ref.watch(pinsProvider.future);
  final List<PinDetails> finalPins = [];
  final searchValue = ref.watch(searchValueProvider).toLowerCase();

  for (final pin in pins) {
    final title = pin.title();
    final pinId = pin.eventIdStr();
    if (searchValue.isNotEmpty) {
      if (!(title.toLowerCase()).contains(searchValue)) {
        continue;
      }
    }
    finalPins.add(
      PinDetails(
        '/pins/$pinId',
        title,
        icon: pin.isLink()
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
