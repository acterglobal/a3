import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/src/paged_notifier_mixin.dart';
import 'package:riverpod_infinite_scroll/src/paged_state.dart';

typedef PagedBuilder<PageKeyType, ItemType> = Widget Function(
    PagingController<PageKeyType, ItemType> controller,
    PagedChildBuilderDelegate<ItemType> builder);

typedef InfiniteScrollProvider<PageKeyType, ItemType> = StateNotifierProvider<
    PagedNotifierMixin<PageKeyType, ItemType,
        PagedState<PageKeyType, ItemType>>,
    PagedState<PageKeyType, ItemType>>;
typedef InfiniteScrollAutoDisposeProvider<PageKeyType, ItemType>
    = AutoDisposeStateNotifierProvider<
        PagedNotifierMixin<PageKeyType, ItemType,
            PagedState<PageKeyType, ItemType>>,
        PagedState<PageKeyType, ItemType>>;

/// [RiverPagedBuilder] will build your infinite, scrollable list.
/// It expects a Riverpod [StateNotifierProvider]
class RiverPagedBuilder<PageKeyType, ItemType> extends ConsumerStatefulWidget {
  final InfiniteScrollProvider<PageKeyType, ItemType>? _provider;
  final InfiniteScrollAutoDisposeProvider<PageKeyType, ItemType>?
      _autoDisposeProvider;

  final PageKeyType firstPageKey;
  final int limit;

  /// Choose if to add a Pull to refresh functionality
  /// This wil call `ref.refresh(provider)` internally
  /// Default [false]
  final bool pullToRefresh;

  /// Choose if infinite scrolling functionality should be enabled
  /// Default [true]
  final bool enableInfiniteScroll;

  /// The number of remaining invisible items that should trigger a new fetch.
  final int? invisibleItemsThreshold;

  final ItemWidgetBuilder<ItemType> itemBuilder;
  final PagedBuilder<PageKeyType, ItemType> pagedBuilder;

  final Widget Function(BuildContext context, PagingController controller)?
      firstPageErrorIndicatorBuilder;
  final Widget Function(BuildContext context, PagingController controller)?
      firstPageProgressIndicatorBuilder;
  final Widget Function(BuildContext context, PagingController controller)?
      noItemsFoundIndicatorBuilder;
  final Widget Function(BuildContext context, PagingController controller)?
      newPageErrorIndicatorBuilder;
  final Widget Function(BuildContext context, PagingController controller)?
      newPageProgressIndicatorBuilder;
  final Widget Function(BuildContext context, PagingController controller)?
      noMoreItemsIndicatorBuilder;

  const RiverPagedBuilder(
      {required InfiniteScrollProvider<PageKeyType, ItemType> provider,
      required this.pagedBuilder,
      required this.itemBuilder,
      required this.firstPageKey,
      this.limit = 20,
      this.pullToRefresh = false,
      this.enableInfiniteScroll = true,
      this.firstPageErrorIndicatorBuilder,
      this.firstPageProgressIndicatorBuilder,
      this.noItemsFoundIndicatorBuilder,
      this.newPageErrorIndicatorBuilder,
      this.newPageProgressIndicatorBuilder,
      this.noMoreItemsIndicatorBuilder,
      this.invisibleItemsThreshold,
      Key? key})
      : _provider = provider,
        _autoDisposeProvider = null,
        super(key: key);

  const RiverPagedBuilder.autoDispose(
      {required InfiniteScrollAutoDisposeProvider<PageKeyType, ItemType>
          provider,
      required this.pagedBuilder,
      required this.itemBuilder,
      required this.firstPageKey,
      this.limit = 20,
      this.pullToRefresh = false,
      this.enableInfiniteScroll = true,
      this.firstPageErrorIndicatorBuilder,
      this.firstPageProgressIndicatorBuilder,
      this.noItemsFoundIndicatorBuilder,
      this.newPageErrorIndicatorBuilder,
      this.newPageProgressIndicatorBuilder,
      this.noMoreItemsIndicatorBuilder,
      this.invisibleItemsThreshold,
      Key? key})
      : _provider = null,
        _autoDisposeProvider = provider,
        super(key: key);

  @override
  ConsumerState<RiverPagedBuilder<PageKeyType, ItemType>> createState() =>
      _RiverPagedBuilderState<PageKeyType, ItemType>();
}

class _RiverPagedBuilderState<PageKeyType, ItemType>
    extends ConsumerState<RiverPagedBuilder<PageKeyType, ItemType>> {
  late final PagingController<PageKeyType, ItemType> _pagingController;

  get _provider => widget._provider ?? widget._autoDisposeProvider!;

  @override
  void initState() {
    // Instantiate the [PagingController]
    _pagingController = PagingController<PageKeyType, ItemType>(
        firstPageKey: widget.firstPageKey,
        invisibleItemsThreshold: widget.invisibleItemsThreshold);

    // Redirect every page request to the [StateNotifier]
    _pagingController.addPageRequestListener(_loadFromProvider);

    super.initState();
  }

  void _loadFromProvider(PageKeyType pageKey) {
    if (pageKey != widget.firstPageKey && !widget.enableInfiniteScroll) {
      return _updatePagingState(
        ref
            .read<PagedState<PageKeyType, ItemType>>(_provider)
            .copyWith(nextPageKey: null),
      );
    }
    ref.read((_provider).notifier).load(pageKey, widget.limit);
  }

  void _updatePagingState(PagedState<PageKeyType, ItemType> state) {
    _pagingController.value = PagingState(
      error: state.error,
      itemList: state.records,
      nextPageKey: state.nextPageKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This listen to [StateNotiefer] change and reflect those changes to the [PagingController]
    ref.listen<PagedState<PageKeyType, ItemType>>(
      _provider,
      (_, next) => _updatePagingState(next),
    );

    // Allow possibility to customize indicators
    final itemBuilder = PagedChildBuilderDelegate<ItemType>(
      itemBuilder: widget.itemBuilder,
      firstPageErrorIndicatorBuilder:
          widget.firstPageErrorIndicatorBuilder != null
              ? (ctx) =>
                  widget.firstPageErrorIndicatorBuilder!(ctx, _pagingController)
              : null,
      firstPageProgressIndicatorBuilder: widget
                  .firstPageProgressIndicatorBuilder !=
              null
          ? (ctx) =>
              widget.firstPageProgressIndicatorBuilder!(ctx, _pagingController)
          : null,
      noItemsFoundIndicatorBuilder: widget.noItemsFoundIndicatorBuilder != null
          ? (ctx) =>
              widget.noItemsFoundIndicatorBuilder!(ctx, _pagingController)
          : null,
      newPageErrorIndicatorBuilder: widget.newPageErrorIndicatorBuilder != null
          ? (ctx) =>
              widget.newPageErrorIndicatorBuilder!(ctx, _pagingController)
          : null,
      newPageProgressIndicatorBuilder: widget.newPageProgressIndicatorBuilder !=
              null
          ? (ctx) =>
              widget.newPageProgressIndicatorBuilder!(ctx, _pagingController)
          : null,
      noMoreItemsIndicatorBuilder: widget.noMoreItemsIndicatorBuilder != null
          ? (ctx) => widget.noMoreItemsIndicatorBuilder!(ctx, _pagingController)
          : null,
    );

    // return a [PagedBuilder]
    var pagedBuilder = widget.pagedBuilder(_pagingController, itemBuilder);

    // Add pull to refresh functionality if specified
    if (widget.pullToRefresh) {
      pagedBuilder = RefreshIndicator(
          onRefresh: () async => ref.refresh(_provider), child: pagedBuilder);
    }

    return pagedBuilder;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
