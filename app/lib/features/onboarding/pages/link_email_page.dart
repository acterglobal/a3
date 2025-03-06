import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/validation_utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LinkEmailPage extends ConsumerWidget {
  static const emailField = Key('reg-email-txt');
  static const linkEmailBtn = Key('reg-link-email-btn');

  final formKey = GlobalKey<FormState>(debugLabel: 'link email page form');
  final ValueNotifier<bool> isLinked = ValueNotifier(false);
  final TextEditingController emailController = TextEditingController();

  LinkEmailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: _buildBody(context, ref));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
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
              _buildEmailInputField(context),
              const SizedBox(height: 30),
              _buildLinkEmailActionButton(context, ref),
              const SizedBox(height: 20),
              _buildSkipActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          lang.protectPrivacyTitle,
          style: textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(lang.protectPrivacyDescription1, style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        Text(lang.protectPrivacyDescription2, style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildEmailInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.emailOptional),
          const SizedBox(height: 10),
          TextFormField(
            key: LinkEmailPage.emailField,
            controller: emailController,
            decoration: InputDecoration(hintText: lang.hintEmail),
            style: Theme.of(context).textTheme.labelLarge,
            validator: (val) => validateEmail(context, val),
          ),
        ],
      ),
    );
  }

  Future<void> linkEmail(BuildContext context, WidgetRef ref) async {
    if (!formKey.currentState!.validate()) return;
    final lang = L10n.of(context);
    final account = await ref.read(accountProvider.future);
    EasyLoading.show(status: lang.linkingEmailAddress);
    try {
      final emailAddr = emailController.text.trim();
      await account.request3pidManagementTokenViaEmail(emailAddr);
      ref.invalidate(emailAddressesProvider);
      if (!context.mounted) return;
      EasyLoading.showSuccess(lang.pleaseCheckYourInbox);
      isLinked.value = true;
    } catch (e) {
      EasyLoading.showToast(
        lang.failedToSubmitEmail(e),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
    } finally {
      EasyLoading.dismiss();
      if (context.mounted) {
        context.goNamed(Routes.uploadAvatar.name);
      }
    }
  }

  Widget _buildLinkEmailActionButton(BuildContext context, WidgetRef ref) {
    final disabledColor = Theme.of(context).disabledColor;
    final textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: emailController,
      builder: (context, emailValue, child) {
        final isValidEmail = validateEmail(context, emailValue.text) == null;
        return OutlinedButton(
          key: LinkEmailPage.linkEmailBtn,
          onPressed: isValidEmail ? () => linkEmail(context, ref) : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isValidEmail ? whiteColor : disabledColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                L10n.of(context).linkEmailToProfile,
                style: textTheme.bodyMedium?.copyWith(
                  color: isValidEmail ? whiteColor : disabledColor,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: isLinked,
                builder: (context, isLinkedValue, child) {
                  if (!isLinkedValue) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Atlas.check_circle, size: 18),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkipActionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.goNamed(Routes.uploadAvatar.name),
      child: Text(
        L10n.of(context).skip,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
