import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class SaveUsernamePage extends StatelessWidget {
  static const copyUsernameBtn = Key('reg-copy-username-btn');
  static const continueBtn = Key('reg-continue-btn');
  final String username;

  SaveUsernamePage({
    super.key,
    required this.username,
  });

  final ValueNotifier<bool> isCopied = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: kToolbarHeight),
              _buildHeadlineText(context),
              const SizedBox(height: 30),
              _buildDisplayUsername(context),
              const SizedBox(height: 30),
              _buildCopyActionButton(context),
              const SizedBox(height: 20),
              _buildContinueActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          lang.saveUsernameTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          lang.saveUsernameDescription1,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Text(
          lang.saveUsernameDescription2,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Text(
          lang.saveUsernameDescription3,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDisplayUsername(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        child: Column(
          children: [
            Text(
              L10n.of(context).acterUsername,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 15),
            Text(
              username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyActionButton(BuildContext context) {
    return ElevatedButton(
      key: copyUsernameBtn,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: username));
        isCopied.value = true;
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            L10n.of(context).copyToClip,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ValueListenableBuilder(
            valueListenable: isCopied,
            builder: (context, isCopiedValue, child) {
              if (!isCopiedValue) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(
                  Atlas.check_circle,
                  size: 18,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContinueActionButton(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isCopied,
      builder: (context, isCopiedValue, child) {
        return OutlinedButton(
          key: continueBtn,
          onPressed: isCopiedValue
              ? () => context.goNamed(Routes.linkEmail.name)
              : null,
          style: OutlinedButton.styleFrom(
            side: isCopiedValue
                ? null
                : BorderSide(color: Theme.of(context).disabledColor),
          ),
          child: Text(
            L10n.of(context).wizzardContinue,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isCopiedValue ? null : Theme.of(context).disabledColor,
                ),
          ),
        );
      },
    );
  }
}
