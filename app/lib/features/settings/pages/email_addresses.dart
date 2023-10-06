import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/widgets/email_address_card.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailPassword {
  String emailAddress;
  String password;

  EmailPassword(this.emailAddress, this.password);
}

class RequestTokenViaEmail extends StatefulWidget {
  const RequestTokenViaEmail({Key? key}) : super(key: key);

  @override
  State<RequestTokenViaEmail> createState() => _RequestTokenViaEmailState();
}

class _RequestTokenViaEmailState extends State<RequestTokenViaEmail> {
  final TextEditingController newEmailAddress = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your token via email address'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newEmailAddress,
                decoration: const InputDecoration(hintText: 'Email Address'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: togglePassword,
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !passwordVisible,
                enableSuggestions: false,
                autocorrect: false,
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

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // user can reset password under the same email address
    final result = EmailPassword(newEmailAddress.text, newPassword.text);
    Navigator.pop(context, result);
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
              onPressed: () => onAddEmailAddress(context, ref),
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
            return const Center(
              child: Text("Couldn't load all email addresses"),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget buildAddresses(
    BuildContext context,
    EmailAddresses addresses,
  ) {
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
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Atlas.shield_exclamation_thin,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Text(
                  'Unconfirmed Email Addresses',
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
              "You have email addresses that requested password reset but aren't confirmed. This can be a security risk. Please ensure this is okay.",
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
              'All your email addresses are confirmed.',
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

  Future<void> onAddEmailAddress(BuildContext context, WidgetRef ref) async {
    final account = await ref.read(accountProvider.future);
    if (!context.mounted) {
      return;
    }
    final manager = account.passwordResetManager();
    final newValue = await showDialog<EmailPassword>(
      context: context,
      builder: (BuildContext context) => const RequestTokenViaEmail(),
    );
    if (newValue != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Requesting token via email',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      await manager.requestTokenViaEmail(
        newValue.emailAddress,
        newValue.password,
      );
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(
        context,
        'Requested token via email. If you get email for confirmation, please submit token from email to finish this process.',
      );
    }
  }
}
