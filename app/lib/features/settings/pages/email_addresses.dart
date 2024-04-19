import 'package:acter/common/providers/common_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/widgets/email_address_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEmailAddr extends StatefulWidget {
  const AddEmailAddr({super.key});

  @override
  State<AddEmailAddr> createState() => _AddEmailAddrState();
}

class _AddEmailAddrState extends State<AddEmailAddr> {
  final TextEditingController newEmailAddress = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).pleaseProvideEmailAddressToAdd),
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
                decoration: InputDecoration(
                  hintText: L10n.of(context).emailAddress,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => onSubmit(context),
          child: Text(L10n.of(context).submit),
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
    final emailAddresses = ref.watch(emailAddressesProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).emailAddresses),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                ref.invalidate(emailAddressesProvider);
              },
              icon: const Icon(Atlas.refresh_account_arrows_thin),
            ),
            IconButton(
              onPressed: () => addEmailAddress(context, ref),
              icon: const Icon(
                Atlas.plus_circle_thin,
              ),
            ),
          ],
        ),
        body: emailAddresses.when(
          data: (addresses) => buildAddresses(context, addresses),
          error: (error, stack) {
            return Center(
              child: Text(L10n.of(context).errorLoadingEmailAddresses(error)),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget buildAddresses(BuildContext context, EmailAddresses addresses) {
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
                Text(
                  L10n.of(context).awaitingConfirmation,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
              L10n.of(context).awaitingConfirmationDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return EmailAddressCard(
              emailAddress: addresses.unconfirmed[index],
              isConfirmed: false,
            );
          },
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
                L10n.of(context).confirmedEmailAddresses,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder: (BuildContext context, int index) {
              return EmailAddressCard(
                emailAddress: addresses.confirmed[index],
                isConfirmed: true,
              );
            },
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
              L10n.of(context).confirmedEmailAddressesDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return EmailAddressCard(
              emailAddress: addresses.confirmed[index],
              isConfirmed: true,
            );
          },
          itemCount: addresses.confirmed.length,
        ),
      ],
    );
  }

  Future<void> addEmailAddress(BuildContext context, WidgetRef ref) async {
    final client = ref.read(alwaysClientProvider);
    final manager = client.threePidManager();
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const AddEmailAddr(),
    );
    if (newValue != null && context.mounted) {
      EasyLoading.show(status: L10n.of(context).addingEmailAddress);
      try {
        await manager.requestTokenViaEmail(newValue);
        ref.invalidate(emailAddressesProvider);
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showToast(L10n.of(context).pleaseCheckYourInbox);
      } catch (e) {
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          L10n.of(context).failedToSubmitEmail(e),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
