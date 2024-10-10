import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable dialog widget
class DefaultDialog extends ConsumerWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? description;
  final double? height;
  final double? minHeight;
  final double? width;
  final bool isLoader;
  final List<Widget> actions;

  const DefaultDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.height,
    this.minHeight,
    this.width,
    this.isLoader = false,
    required this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width ?? MediaQuery.of(context).size.width * 0.5,
            maxHeight: height ?? MediaQuery.of(context).size.height * 0.8,
            minHeight: minHeight ?? 0.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                title,
                const SizedBox(height: 15),
                subtitle ?? const SizedBox.shrink(),
                const SizedBox(height: 15),
                description ?? const SizedBox.shrink(),
                isLoader
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : actions.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: actions,
                            ),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
