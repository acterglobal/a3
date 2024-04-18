import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/validation_utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LinkEmailPage extends ConsumerStatefulWidget {
  static const emailField = Key('reg-email-txt');
  static const linkEmailBtn = Key('reg-link-email-btn');
  const LinkEmailPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LinkEmailPageState();
}

class _LinkEmailPageState extends ConsumerState<LinkEmailPage> {
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isLinked = ValueNotifier(false);
  final TextEditingController emailController = TextEditingController();
  final _statesController = MaterialStatesController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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
              _buildEmailInputField(context),
              const SizedBox(height: 30),
              _buildLinkEmailActionButton(context),
              const SizedBox(height: 20),
              _buildSkipActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          L10n.of(context).protectPrivacyTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: greenColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          L10n.of(context).protectPrivacyDescription1,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Text(
          L10n.of(context).protectPrivacyDescription2,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEmailInputField(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).emailOptional),
          const SizedBox(height: 10),
          TextFormField(
            key: LinkEmailPage.emailField,
            controller: emailController,
            decoration: InputDecoration(
              hintText: L10n.of(context).hintEmail,
            ),
            style: Theme.of(context).textTheme.labelLarge,
            validator: (val) => validateEmail(context, val),
          ),
        ],
      ),
    );
  }

  Future<void> linkEmail() async {
    if (!formKey.currentState!.validate()) return;
    final client = ref.read(alwaysClientProvider);
    final manager = client.threePidManager();
    EasyLoading.show(status: L10n.of(context).linkingEmailAddress);
    try {
      await manager.requestTokenViaEmail(emailController.text.trim());
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).pleaseCheckYourInbox);
      isLinked.value = true;
    } catch (e) {
      EasyLoading.showToast(
        L10n.of(context).failedToSubmitEmail(e),
        toastPosition: EasyLoadingToastPosition.bottom,
      );
    } finally {
      EasyLoading.dismiss();
      context.goNamed(Routes.userAvatar.name);
    }
  }

  Widget _buildLinkEmailActionButton(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: emailController,
      builder: (context, emailValue, child) {
        _statesController.update(
          emailValue.text.isNotEmpty
              ? MaterialState.pressed
              : MaterialState.disabled,
          emailValue.text.isNotEmpty,
        );
        return OutlinedButton(
          key: LinkEmailPage.linkEmailBtn,
          onPressed: emailValue.text.isNotEmpty ? linkEmail : null,
          statesController: _statesController,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                L10n.of(context).linkEmailToProfile,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: emailValue.text.isNotEmpty
                          ? whiteColor
                          : Theme.of(context).disabledColor,
                    ),
              ),
              ValueListenableBuilder(
                valueListenable: isLinked,
                builder: (context, isLinkedValue, child) {
                  if (!isLinkedValue) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(left: 10.0),
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
      onPressed: () => context.goNamed(Routes.userAvatar.name),
      child: Text(
        L10n.of(context).skip,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
