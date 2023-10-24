import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/widgets/email_address_card.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEmailAddr extends StatefulWidget {
  const AddEmailAddr({Key? key}) : super(key: key);

  @override
  State<AddEmailAddr> createState() => _AddEmailAddrState();
}

class _AddEmailAddrState extends State<AddEmailAddr> {
  final TextEditingController newEmailAddress = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Please provide the email address you'd like to add",
      ), // The token-reset path is just the process by which control over that email address is confirmed.
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
                decoration: const InputDecoration(hintText: 'Email Address'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => onSubmit(context),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      customMsgSnackbar(context, 'Email or password seems to be not valid.');
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
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Email Addresses'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                ref.invalidate(emailAddressesProvider);
              },
              icon: Icon(
                Atlas.refresh_account_arrows_thin,
                color: Theme.of(context).colorScheme.neutral5,
              ),
            ),
            IconButton(
              onPressed: () => addEmailAddress(context, ref),
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
              ),
            ),
          ],
        ),
        body: emailAddresses.when(
          data: (addresses) => buildAddresses(context, addresses),
          error: (error, stack) {
            return Center(
              child: Text('Error loading email addresses: $error'),
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
                  'Awaiting confirmation',
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
              'These email addresses have not yet been confirmed. Please go to your inbox and check for the confirmation link.',
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
                'Confirmed Email Addresses',
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
              'Confirmed emails addresses connected to your account:',
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
    final client = ref.read(clientProvider);
    final manager = client!.threePidManager();
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const AddEmailAddr(),
    );
    if (newValue != null) {
      EasyLoading.show(status: 'Adding email address');
      try {
        await manager.requestTokenViaEmail(newValue);
        ref.invalidate(emailAddressesProvider);
        EasyLoading.showSuccess(
          'Please check your inbox for the validation email',
        );
      } catch (e) {
        EasyLoading.showSuccess(
          'Failed to submit email: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
