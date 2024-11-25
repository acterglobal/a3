import 'package:acter/common/widgets/html_editor/models/mention_type.dart';

class MentionAttributes {
  final String mentionId;
  final String? displayName;
  final MentionType type;

  const MentionAttributes({
    required this.mentionId,
    required this.type,
    this.displayName,
  });
}
