import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stories_editor/stories_editor.dart';

class NewsBuilderPage extends ConsumerStatefulWidget {
  const NewsBuilderPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _NewsBuilderPageState();
}

class _NewsBuilderPageState extends ConsumerState<NewsBuilderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: StoriesEditor(
            giphyKey: giphyKey,
            onDone: (uri) {
              debugPrint('Post URI:$uri');
              context.pushNamed(Routes.updatesPost.name, extra: uri);
            },
            middleBottomWidget: const BottomWidget(),
            onDoneButtonStyle: const DoneButton(),
          ),
        ),
      ),
    );
  }
}

class BottomWidget extends ConsumerWidget {
  const BottomWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
    );
  }
}

class DoneButton extends ConsumerWidget {
  const DoneButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 40,
      width: 65,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        shape: BoxShape.rectangle,
      ),
      child: Center(
        child: Text('Next', style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
