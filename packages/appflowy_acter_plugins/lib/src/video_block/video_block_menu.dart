import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_acter_plugins/appflowy_acter_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

const _leftAlignKey = 'left';
const _centerAlignKey = 'center';
const _rightAlignKey = 'right';

class VideoBlockMenu extends StatefulWidget {
  const VideoBlockMenu({
    super.key,
    required this.node,
    required this.state,
  });

  final Node node;
  final VideoBlockComponentState state;

  @override
  State<VideoBlockMenu> createState() => _VideoBlockMenuState();
}

class _VideoBlockMenuState extends State<VideoBlockMenu> {
  late final String? src = widget.node.attributes[VideoBlockKeys.url];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _MenuButton(
            tooltip: 'Copy video source',
            icon: const Icon(Icons.copy),
            onPressed: copySrc,
          ),
          const SizedBox(width: 4),
          _AlignButton(
            node: widget.node,
            state: widget.state,
          ),
          const _Divider(),
          _MenuButton(
            tooltip: 'Delete video',
            icon: const Icon(Icons.delete),
            onPressed: deleteVideo,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void copySrc() {
    if (src != null) {
      Clipboard.setData(ClipboardData(text: src!));
    }
  }

  Future<void> deleteVideo() async {
    final node = widget.node;
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.afterSelection = null;
    await editorState.apply(transaction);
  }
}

class _AlignButton extends StatefulWidget {
  const _AlignButton({
    required this.node,
    required this.state,
  });

  final Node node;
  final VideoBlockComponentState state;

  @override
  State<_AlignButton> createState() => _AlignButtonState();
}

const interceptorKey = 'video-align';

class _AlignButtonState extends State<_AlignButton> {
  final gestureInterceptor = SelectionGestureInterceptor(
    key: interceptorKey,
    canTap: (_) => false,
  );

  String get align =>
      widget.node.attributes[VideoBlockKeys.alignment] ?? _centerAlignKey;

  late final EditorState editorState;
  final FocusNode childFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    editorState = context.read<EditorState>();
  }

  @override
  void dispose() {
    allowMenuClose();
    childFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listener is a workaround for:
    //  https://docs.flutter.dev/development/ui/advanced/gestures#gesture-disambiguation
    //  https://github.com/AppFlowy-IO/AppFlowy/issues/1290
    return Listener(
      onPointerDown: (event) {},
      onPointerSignal: (event) {},
      onPointerMove: (event) {},
      onPointerUp: (event) {},
      onPointerHover: (event) {},
      onPointerPanZoomStart: (event) {},
      onPointerPanZoomUpdate: (event) {},
      onPointerPanZoomEnd: (event) {},
      child: MenuAnchor(
        childFocusNode: childFocusNode,
        menuChildren: [_AlignButtons(onAlignChanged: onAlignChanged)],
        builder: (context, controller, _) => _MenuButton(
          focusNode: childFocusNode,
          tooltip: 'Change alignment of video',
          icon: Icon(_iconFor(align)),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              preventMenuClose();
              controller.open();
            }
          },
        ),
      ),
    );
  }

  void onAlignChanged(String align) {
    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {VideoBlockKeys.alignment: align});
    editorState.apply(transaction);

    if (!UniversalPlatform.isMobile) {
      allowMenuClose();
    }
  }

  void preventMenuClose() {
    widget.state.preventClose = true;
    editorState.service.selectionService.registerGestureInterceptor(
      gestureInterceptor,
    );
  }

  void allowMenuClose() {
    widget.state.preventClose = false;
    editorState.service.selectionService.unregisterGestureInterceptor(
      interceptorKey,
    );
  }
}

class _AlignButtons extends StatelessWidget {
  const _AlignButtons({required this.onAlignChanged});

  final Function(String align) onAlignChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          _MenuButton(
            icon: Icon(_iconFor(_leftAlignKey)),
            tooltip: 'Align video left',
            onPressed: () => onAlignChanged(_leftAlignKey),
          ),
          const _Divider(),
          _MenuButton(
            icon: Icon(_iconFor(_centerAlignKey)),
            tooltip: 'Align video center',
            onPressed: () => onAlignChanged(_centerAlignKey),
          ),
          const _Divider(),
          _MenuButton(
            icon: Icon(_iconFor(_rightAlignKey)),
            tooltip: 'Align video right',
            onPressed: () => onAlignChanged(_rightAlignKey),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    this.focusNode,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final FocusNode? focusNode;
  final Icon icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        focusNode: focusNode,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 1,
        color: Colors.grey,
      ),
    );
  }
}

IconData _iconFor(String alignment) {
  switch (alignment) {
    case _rightAlignKey:
      return Icons.align_horizontal_right;
    case _leftAlignKey:
      return Icons.align_horizontal_left;
    case _centerAlignKey:
    default:
      return Icons.align_horizontal_center;
  }
}
