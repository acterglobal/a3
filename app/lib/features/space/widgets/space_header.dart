import 'package:acter/features/space/widgets/space_header_profile.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceHeader extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;

  const SpaceHeader({
    super.key,
    required this.spaceIdOrAlias,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceHeaderState();
}

class _SpaceHeaderState extends ConsumerState<SpaceHeader> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SpaceToolbar(spaceId: widget.spaceIdOrAlias),
        SpaceHeaderProfile(widget.spaceIdOrAlias),
        TopNavBar(spaceId: widget.spaceIdOrAlias),
      ],
    );
  }
}
