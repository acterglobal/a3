import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

enum StreamTypes { news, stories }

class StreamTypesSelection extends StatefulWidget {
  const StreamTypesSelection({super.key});

  @override
  State<StreamTypesSelection> createState() => _StreamTypesSelectionState();
}

class _StreamTypesSelectionState extends State<StreamTypesSelection> {
  Set<StreamTypes> selection = <StreamTypes>{
    StreamTypes.news,
  };

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StreamTypes>(
      segments: const <ButtonSegment<StreamTypes>>[
        ButtonSegment<StreamTypes>(
          value: StreamTypes.news,
          icon: Icon(Atlas.newspaper_thin),
        ),
        ButtonSegment<StreamTypes>(
          value: StreamTypes.stories,
          icon: Icon(Atlas.image_message_thin),
        ),
      ],
      selected: selection,
      onSelectionChanged: (Set<StreamTypes> newSelection) {
        if (mounted) {
          setState(() => selection = newSelection);
        }
      },
      multiSelectionEnabled: true,
    );
  }
}
