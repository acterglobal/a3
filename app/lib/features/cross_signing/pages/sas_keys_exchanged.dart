import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SasKeysExchangedPage extends StatelessWidget {
  final String sender;
  final bool isVerifier;
  final FfiListVerificationEmoji emojis;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onMatch;
  final Function(BuildContext) onMismatch;

  const SasKeysExchangedPage({
    super.key,
    required this.sender,
    required this.isVerifier,
    required this.emojis,
    required this.onCancel,
    required this.onMatch,
    required this.onMismatch,
  });

  @override
  Widget build(BuildContext context) {
    final title = isVerifier ? 'Verify Other Session' : 'Verify This Session';
    List<int> codes = emojis.map((e) => e.symbol()).toList();
    List<String> descriptions = emojis.map((e) => e.description()).toList();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: isDesktop
                        ? const Icon(Atlas.laptop)
                        : const Icon(Atlas.phone),
                  ),
                  const SizedBox(width: 5),
                  Text(title),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => onCancel(context),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Compare the unique emoji, ensuring they appear in the same order.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Spacer(flex: 1),
          Expanded(
            flex: isDesktop ? 2 : 7,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.neutral2,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.count(
                    crossAxisCount: isDesktop ? 7 : 4,
                    children: List.generate(emojis.length, (index) {
                      return GridTile(
                        child: Column(
                          children: <Widget>[
                            Text(
                              String.fromCharCode(codes[index]),
                              style: const TextStyle(fontSize: 32),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              descriptions[index],
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          Expanded(
            flex: isDesktop ? 1 : 2,
            child: buildBody(context),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: const Text('They don’t match'),
          onPressed: () => onMismatch(context),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          child: const Text('They match'),
          onPressed: () => onMatch(context),
        ),
      ],
    );
  }
}
