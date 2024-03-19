import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/widgets/quick_jump.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const Map<String, String> empty = {};

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: QuickJump(
        navigateTo: (
          Routes route, {
          Future<bool> Function(BuildContext)? prepare,
          bool? push = false,
          Map<String, String>? pathParameters,
          Map<String, String>? queryParameters,
          Object? extra,
        }) async {
          if (prepare != null) {
            if (await prepare(context)) {
              // true means we should stop processing
              return;
            }
          }
          if (context.mounted) {
            if (push ?? false) {
              await context.pushNamed(
                route.name,
                pathParameters: pathParameters ?? empty,
                queryParameters: queryParameters ?? empty,
                extra: extra,
              );
            } else {
              context.goNamed(
                route.name,
                pathParameters: pathParameters ?? empty,
                queryParameters: queryParameters ?? empty,
                extra: extra,
              );
            }
          }
        },
        expand: true,
      ),
    );
  }
}
