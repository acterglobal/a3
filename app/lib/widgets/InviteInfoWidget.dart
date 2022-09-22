// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables,

import 'package:effektio/widgets/AppCommon.dart';
import 'package:flutter/material.dart';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InviteInfoWidget extends StatelessWidget {
  const InviteInfoWidget({
    Key? key,
    required this.avatarColor,
    required this.inviter,
    required this.groupName,
  }) : super(key: key);
  final Color avatarColor;
  final String inviter;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppCommonTheme.darkShade,
      margin: const EdgeInsets.only(top: 1, bottom: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: avatarColor,
            ),
            title: Text(
              inviter,
              style: AppCommonTheme.appBarTitleStyle
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: RichText(
              text: TextSpan(
                text: AppLocalizations.of(context)!.invitationText2,
                style: AppCommonTheme.appBarTitleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppCommonTheme.dividerColor,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: groupName,
                    style: AppCommonTheme.appBarTitleStyle
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            color: AppCommonTheme.dividerColor,
            indent: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.46,
                child: elevatedButton(
                  AppLocalizations.of(context)!.accept,
                  AppCommonTheme.greenButtonColor,
                  () => {},
                  AppCommonTheme.appBarTitleStyle
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.46,
                child: elevatedButton(
                  AppLocalizations.of(context)!.decline,
                  AppCommonTheme.primaryColor,
                  () => {},
                  AppCommonTheme.appBarTitleStyle
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
