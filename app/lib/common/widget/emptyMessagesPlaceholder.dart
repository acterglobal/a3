import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: MediaQuery.of(context).size.height / 6),
        SvgPicture.asset('assets/images/emptyPlaceholder.svg'),
        const SizedBox(height: 10),
       Text(
          '${AppLocalizations.of(context)!.noMessages} ...',
          style: ChatTheme01.emptyMsgTitle,
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.startConvo,
          style: ChatTheme01.chatBodyStyle,
        ),
      ],
    );
  }
}
