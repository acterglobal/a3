import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void logoutConfirmationDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Atlas.warning,color: Colors.red,),
            const SizedBox(height:10,),
            Text(AppLocalizations.of(context)!.logOut),
          ],
        ),
        content: RichText(
          textAlign: TextAlign.left,
          text: const TextSpan(
            text: 'Attention: ',
            style: TextStyle(color: Colors.white, fontSize: 15),
            children: <TextSpan>[
              TextSpan(
                text:
                    'Logging out removes the local data, including encryption keys. If this is your last signed-in device you might no be able to decrypt any previous content.',
              ),
              TextSpan(text: 'Are you sure you want to log out?'),
            ],
          ),
        ),
        actions: <Widget>[
          Row(
            children: [
               Expanded(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),),
              child: TextButton(
                onPressed: () => ctx.pop(),
                child: const Text(
                  'No',
                  style: TextStyle(color: Colors.white,fontSize: 17),
                ),
              ),
            ),
          ),
           const SizedBox(width: 10),
            Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),),
              child: TextButton(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout(ctx);
                },
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.white,fontSize: 17),
                ),
              ),
            ),
          ),
            ],
          ),
         
        
        ],
      );
    },
  );
}
