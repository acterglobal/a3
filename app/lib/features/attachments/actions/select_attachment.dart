import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_selection_options.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

Future<void> selectAttachment({
  required BuildContext context,
  required OnAttachmentSelected onSelected,
  OnLinkSelected? onLinkSelected,
}) async {
  await showModalBottomSheet(
    isDismissible: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    context: context,
    builder:
        (context) => AttachmentSelectionModal(
          onSelected: onSelected,
          onLinkSelected: onLinkSelected,
        ),
  );
}

class AttachmentSelectionModal extends StatelessWidget {
  final OnAttachmentSelected onSelected;
  final OnLinkSelected? onLinkSelected;

  const AttachmentSelectionModal({
    super.key,
    required this.onSelected,
    this.onLinkSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(context),
              const SizedBox(height: 12),
              AttachmentSelectionOptions(
                onSelected: onSelected,
                onLinkSelected: onLinkSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
