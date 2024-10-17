import 'package:flutter/material.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_acter_plugins/appflowy_acter_plugins.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LinkPreviewBlockKeys {
  const LinkPreviewBlockKeys._();

  static const String type = 'link_preview';
  static const String url = 'url';
}

Node linkPreviewNode({required String url}) => Node(
      type: LinkPreviewBlockKeys.type,
      attributes: {LinkPreviewBlockKeys.url: url},
    );

abstract class LinkPreviewDataCacheInterface {
  Future<LinkPreviewData?> get(String url);
  Future<void> set(String url, LinkPreviewData data);
}

typedef LinPreviewBlockComponentMenuBuilder = Widget Function(
  BuildContext context,
  Node node,
  LinkPreviewBlockComponentState state,
);

typedef LinkPreviewBlockPreviewBuilder = Widget Function(
  BuildContext context,
  Node node,
  String url,
  String? title,
  String? description,
  String? imageUrl,
);

class LinkPreviewBlockComponentBuilder extends BlockComponentBuilder {
  LinkPreviewBlockComponentBuilder({
    super.configuration,
    this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.showMenu = false,
    this.menuBuilder,
    this.cache,
  });

  /// The builder for the preview widget.
  final LinkPreviewBlockPreviewBuilder? builder;

  /// The builder for the error widget.
  final WidgetBuilder? errorBuilder;

  /// The builder for the loading widget.
  final WidgetBuilder? loadingBuilder;

  /// Whether to show the menu.
  final bool showMenu;

  /// The builder for the menu widget.
  final LinPreviewBlockComponentMenuBuilder? menuBuilder;

  /// customize your own cache if you don't want the link preview block refresh every time
  final LinkPreviewDataCacheInterface? cache;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return LinkPreviewBlockComponent(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
      builder: builder,
      errorBuilder: errorBuilder,
      showMenu: showMenu,
      menuBuilder: menuBuilder,
      cache: cache,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (Node node) => node.attributes[LinkPreviewBlockKeys.url]!.isNotEmpty;
}

class LinkPreviewBlockComponent extends BlockComponentStatefulWidget {
  const LinkPreviewBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.showMenu = false,
    this.menuBuilder,
    this.cache,
  });

  final LinkPreviewBlockPreviewBuilder? builder;
  final WidgetBuilder? errorBuilder;
  final WidgetBuilder? loadingBuilder;
  final bool showMenu;
  final LinPreviewBlockComponentMenuBuilder? menuBuilder;
  final LinkPreviewDataCacheInterface? cache;

  @override
  State<LinkPreviewBlockComponent> createState() =>
      LinkPreviewBlockComponentState();
}

class LinkPreviewBlockComponentState extends State<LinkPreviewBlockComponent>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  String get url => widget.node.attributes[LinkPreviewBlockKeys.url]!;

  late final LinkPreviewParser parser;
  late final Future<void> future;
  late final WidgetBuilder errorBuilder;
  late final WidgetBuilder loadingBuilder;

  final showActionsNotifier = ValueNotifier<bool>(false);
  bool alwaysShowMenu = false;

  @override
  void initState() {
    super.initState();

    errorBuilder = widget.errorBuilder ?? _defaultErrorWidget;
    loadingBuilder = widget.loadingBuilder ?? _defaultLoadingWidget;

    parser = LinkPreviewParser(url: url, cache: widget.cache);
    future = parser.start();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loadingBuilder(context);
        }

        final title = parser.getContent(LinkPreviewRegex.title);
        final description = parser.getContent(LinkPreviewRegex.description);
        final image = parser.getContent(LinkPreviewRegex.image);

        Widget child;
        if (title == null && description == null && image == null) {
          child = errorBuilder(context);
        } else {
          child = widget.builder?.call(
                context,
                widget.node,
                url,
                title,
                description,
                image,
              ) ??
              _LinkPreviewWidget(
                url: url,
                title: title,
                description: description,
                imageUrl: image,
              );
        }

        child = Padding(padding: padding, child: child);

        if (widget.showActions && widget.actionBuilder != null) {
          child = BlockComponentActionWrapper(
            node: node,
            actionBuilder: widget.actionBuilder!,
            child: child,
          );
        }

        if (widget.showMenu && widget.menuBuilder != null) {
          child = MouseRegion(
            onEnter: (_) => showActionsNotifier.value = true,
            onExit: (_) {
              if (!alwaysShowMenu) {
                showActionsNotifier.value = false;
              }
            },
            hitTestBehavior: HitTestBehavior.opaque,
            opaque: false,
            child: ValueListenableBuilder<bool>(
              valueListenable: showActionsNotifier,
              builder: (context, value, child) => Stack(
                children: [
                  child!,
                  if (value) widget.menuBuilder!(context, widget.node, this),
                ],
              ),
              child: child,
            ),
          );
        }

        return child;
      },
    );
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: Text('No preview available'),
        ),
      ),
    );
  }

  Widget _defaultLoadingWidget(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _LinkPreviewWidget extends StatelessWidget {
  const _LinkPreviewWidget({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => launchUrlString(url),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface),
          borderRadius: BorderRadius.circular(
            8.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                ),
                child: Image.network(
                  imageUrl!,
                  width: 180,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    Text(
                      url.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
