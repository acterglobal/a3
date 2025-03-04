import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Size? size;
  final bool withBoarder;
  final OnEmojiSelected? onEmojiSelected;
  final OnBackspacePressed? onBackspacePressed;
  final VoidCallback onClosePicker;

  const EmojiPickerWidget({
    super.key,
    this.size,
    this.onEmojiSelected,
    this.onBackspacePressed,
    required this.onClosePicker,
    this.withBoarder = false,
  });

  @override
  Widget build(BuildContext context) {
    final height =
        size.map((val) => val.height) ?? MediaQuery.of(context).size.height / 3;
    final width =
        size.map((val) => val.width) ?? MediaQuery.of(context).size.width;
    final cols = min(width / (EmojiConfig.emojiSizeMax * 2), 12).floor();

    final emojiConfig = EmojiViewConfig(
      backgroundColor: Theme.of(context).colorScheme.surface,
      columns: cols,
      emojiSizeMax: EmojiConfig.emojiSizeMax,
    );
    final catConfig = CategoryViewConfig(
      customCategoryView:
          (config, state, tab, page) =>
              actionBar(context, emojiConfig, state, tab, page),
    );

    final searchConfig = SearchViewConfig(
      customSearchView:
          (_, state, showEmojiView) => _CustomSearchView(
            Config(
              emojiViewConfig: emojiConfig,
              searchViewConfig: SearchViewConfig(
                backgroundColor: Theme.of(context).colorScheme.surface,
                buttonIconColor: Theme.of(context).colorScheme.onPrimary,
                hintText: L10n.of(context).search,
              ),
              checkPlatformCompatibility:
                  EmojiConfig.checkPlatformCompatibility,
              emojiTextStyle: EmojiConfig.emojiTextStyle,
            ),
            state,
            showEmojiView,
            onClosePicker,
          ),
    );
    return Container(
      padding:
          withBoarder
              ? const EdgeInsets.only(top: 10, left: 15, right: 15)
              : null,
      decoration:
          withBoarder
              ? BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              )
              : null,
      height: height,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            width: 35,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: onEmojiSelected,
              onBackspacePressed: onBackspacePressed,
              config: Config(
                emojiViewConfig: emojiConfig,
                categoryViewConfig: catConfig,
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
                searchViewConfig: searchConfig,
                skinToneConfig: const SkinToneConfig(),
                checkPlatformCompatibility:
                    EmojiConfig.checkPlatformCompatibility,
                emojiTextStyle: EmojiConfig.emojiTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget actionBar(
    BuildContext context,
    EmojiViewConfig emojiConfig,
    EmojiViewState state,
    TabController tabController,
    PageController pageController,
  ) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      IconButton(
        onPressed: state.onShowSearchView,
        icon: Icon(PhosphorIcons.magnifyingGlass()),
      ),
      Expanded(
        child: DefaultCategoryView(
          Config(
            emojiViewConfig: emojiConfig,
            categoryViewConfig: CategoryViewConfig(
              backgroundColor: Theme.of(context).colorScheme.surface,
              initCategory: Category.RECENT,
            ),
          ),
          state,
          tabController,
          pageController,
        ),
      ),
      if (onBackspacePressed != null)
        IconButton(
          onPressed: onBackspacePressed,
          icon: Icon(PhosphorIcons.backspace()),
        ),
      IconButton(onPressed: onClosePicker, icon: Icon(PhosphorIcons.xCircle())),
    ],
  );
}

/// Default Search implementation
class _CustomSearchView extends SearchView {
  final VoidCallback closePicker;

  /// Constructor
  const _CustomSearchView(
    super.config,
    super.state,
    super.showEmojiView,
    this.closePicker,
  );

  @override
  _CustomSearchViewState createState() => _CustomSearchViewState();
}

/// Default Search View State
class _CustomSearchViewState extends SearchViewState<_CustomSearchView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emojiSize = widget.config.emojiViewConfig.getEmojiSize(
          constraints.maxWidth,
        );
        final emojiBoxSize = widget.config.emojiViewConfig.getEmojiBoxSize(
          constraints.maxWidth,
        );

        return Container(
          color: widget.config.searchViewConfig.backgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: emojiBoxSize + 8.0,
                  child: _renderResultRow(emojiSize, emojiBoxSize),
                ),
              ),
              _renderSearchBox(),
            ],
          ),
        );
      },
    );
  }

  Widget _renderResultRow(double emojiSize, double emojiBoxSize) => Row(
    children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          scrollDirection: Axis.horizontal,
          itemCount: results.length,
          itemBuilder: (context, index) {
            return buildEmoji(results[index], emojiSize, emojiBoxSize);
          },
        ),
      ),
      IconButton(
        onPressed: () {
          widget.closePicker();
        },
        color: widget.config.searchViewConfig.buttonIconColor,
        icon: Icon(PhosphorIcons.xCircle()),
      ),
    ],
  );

  Widget _renderSearchBox() => Row(
    children: [
      IconButton(
        onPressed: () {
          widget.showEmojiView();
        },
        color: widget.config.searchViewConfig.buttonIconColor,
        icon: const Icon(Icons.arrow_back),
      ),
      Expanded(
        child: TextField(
          onChanged: onTextInputChanged,
          focusNode: focusNode,
          style: widget.config.searchViewConfig.inputTextStyle,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.config.searchViewConfig.hintText,
            hintStyle: widget.config.searchViewConfig.hintTextStyle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    ],
  );
}
