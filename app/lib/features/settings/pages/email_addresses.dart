import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/widgets/email_address_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::email_addresses');

class AddEmailAddr extends StatefulWidget {
  const AddEmailAddr({super.key});

  @override
  State<AddEmailAddr> createState() => _AddEmailAddrState();
}

class _AddEmailAddrState extends State<AddEmailAddr> {
  final TextEditingController newEmailAddress = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'ask eamil addr form',
  );

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.pleaseProvideEmailAddressToAdd),
      // The token-reset path is just the process by which control over that email address is confirmed.
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newEmailAddress,
                // FIXME: should have an email-addres-validator ,
                decoration: InputDecoration(hintText: lang.emailAddress),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(lang.cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => onSubmit(context),
          child: Text(lang.submit),
        ),
      ],
    );
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      EasyLoading.showError(
        L10n.of(context).emailOrPasswordSeemsNotValid,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    Navigator.pop(context, newEmailAddress.text);
  }
}

class EmailAddressesPage extends ConsumerWidget {
  const EmailAddressesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final addressesLoader = ref.watch(emailAddressesProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(lang.emailAddresses),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                ref.invalidate(emailAddressesProvider);
                EasyLoading.showToast(lang.refreshing);
              },
              icon: const Icon(Atlas.refresh_account_arrows_thin),
            ),
            IconButton(
              onPressed: () => addEmailAddress(context, ref),
              icon: const Icon(Atlas.plus_circle_thin),
            ),
          ],
        ),
        body: addressesLoader.when(
          data: (addresses) => buildAddresses(context, addresses),
          error: (e, s) {
            _log.severe('Failed to load email addresses', e, s);
            return Center(child: Text(lang.errorLoadingEmailAddresses(e)));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget buildAddresses(BuildContext context, EmailAddresses addresses) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (addresses.unconfirmed.isNotEmpty) {
      final slivers = [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Atlas.envelope_question_thin),
                ),
                Text(lang.awaitingConfirmation, style: textTheme.headlineSmall),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Text(
              lang.awaitingConfirmationDescription,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder:
              (context, index) => EmailAddressCard(
                emailAddress: addresses.unconfirmed[index],
                isConfirmed: false,
              ),
          itemCount: addresses.unconfirmed.length,
        ),
      ];
      if (addresses.confirmed.isNotEmpty) {
        slivers.addAll([
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              child: Text(
                lang.confirmedEmailAddresses,
                style: textTheme.headlineSmall,
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder:
                (context, index) => EmailAddressCard(
                  emailAddress: addresses.confirmed[index],
                  isConfirmed: true,
                ),
            itemCount: addresses.confirmed.length,
          ),
        ]);
      }
      return CustomScrollView(slivers: slivers);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Text(
              lang.confirmedEmailAddressesDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder:
              (context, index) => EmailAddressCard(
                emailAddress: addresses.confirmed[index],
                isConfirmed: true,
              ),
          itemCount: addresses.confirmed.length,
        ),
      ],
    );
  }

  Future<void> addEmailAddress(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const AddEmailAddr(),
    );
    if (newValue != null && context.mounted) {
      EasyLoading.show(status: lang.addingEmailAddress);
      final account = await ref.read(accountProvider.future);
      try {
        await account.request3pidManagementTokenViaEmail(newValue);
        ref.invalidate(emailAddressesProvider);
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showToast(lang.pleaseCheckYourInbox);
      } catch (e, s) {
        _log.severe('Failed to submit email address', e, s);
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.failedToSubmitEmail(e),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
