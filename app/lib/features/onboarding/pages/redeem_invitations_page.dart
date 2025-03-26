import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

final tokenField = GlobalKey<FormFieldState>();

class RedeemInvitationsPage extends ConsumerStatefulWidget {
  final String username;

  const RedeemInvitationsPage({super.key, required this.username});

  @override
  ConsumerState<RedeemInvitationsPage> createState() =>
      _RedeemInvitationsPageState();
}

class _RedeemInvitationsPageState extends ConsumerState<RedeemInvitationsPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool showInviteInfo = false;
  bool showRedeemButton = false;
  bool showGetDetailsButton = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  // Handle text changes in the token field
  void _onTokenChanged(String token) {
    setState(() {
      showInviteInfo = false;
      showRedeemButton = false;
      showGetDetailsButton = true;
    });
  }

  Future<void> _loadToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('invitation_token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _tokenController.text = token;
      });
    }
  }

  Future<void> _scanQR(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(title: Text(L10n.of(context).scanQrCode)),
              body: QRCodeDartScanView(
                scanInvertedQRCode: true,
                intervalScan: const Duration(milliseconds: 300),
                typeScan: TypeScan.live,
                onCapture: (result) {
                  if (context.mounted) {
                    Navigator.of(context).pop(result.text);
                  }
                },
              ),
            ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _tokenController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, lang),
                  const SizedBox(height: 16),
                  _buildDescription(context, lang),
                  const SizedBox(height: 20),
                  _buildInviteCodeInput(context, lang),
                  const SizedBox(height: 10),
                  showInviteInfo
                      ? _buildInviteInfo(context)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            _buildNavigationButtons(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, L10n lang) {
    return Text(
      lang.redeemInvitation,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context, L10n lang) {
    return Text(
      lang.redeemInvitationDescription,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 15),
    );
  }

  Widget _buildInviteCodeInput(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.inviteCode),
        const SizedBox(height: 5),
        Form(
          key: _formKey,
          child: TextFormField(
            key: tokenField,
            controller: _tokenController,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            validator:
                (val) =>
                    val == null || val.trim().isEmpty ? lang.emptyToken : null,
            decoration: InputDecoration(
              hintText: lang.inviteCode,
              suffixIcon:
                  (Platform.isAndroid || Platform.isIOS)
                      ? IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: () => _scanQR(context),
                      )
                      : null,
            ),
            onChanged: _onTokenChanged, // Handle changes
          ),
        ),
      ],
    );
  }

  Widget _buildInviteInfo(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final errorStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: errorColor);
    final lang = L10n.of(context);
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      return const SizedBox.shrink();
    }

    return ref
        .watch(superInviteInfoProvider(token))
        .when(
          data: (info) {
            EasyLoading.dismiss();
            setState(() {
              showRedeemButton = true;
              showGetDetailsButton = false;
            });
            return _renderInfo(context, info);
          },
          error: (e, s) {
            EasyLoading.dismiss();
            setState(() {
              showRedeemButton = false;
              showGetDetailsButton = true;
            });
            final errorStr = e.toString();
            if (errorStr.contains('error: [404]')) {
              return Text(
                lang.superInvitesPreviewMissing(token),
                style: errorStyle,
              );
            }
            if (errorStr.contains('error: [403]')) {
              return Text(lang.superInvitesDeleted(token), style: errorStyle);
            }
            return Text(lang.loadingFailed(e), style: errorStyle);
          },
          loading: () {
            setState(() {
              showRedeemButton = false;
              showGetDetailsButton = true;
            });
            EasyLoading.show(status: lang.loading);
            return const SizedBox.shrink();
          },
        );
  }

  Widget _renderInfo(BuildContext context, SuperInviteInfo info) {
    final lang = L10n.of(context);
    final displayName = info.inviterDisplayNameStr();
    final userId = info.inviterUserIdStr();
    final inviter = displayName ?? userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(inviter),
            subtitle: Text(lang.youInvited(info.roomsCount())),
            leading: ActerAvatar(
              options: AvatarOptions.DM(
                AvatarInfo(uniqueId: userId, displayName: displayName),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        showGetDetailsButton
            ? _buildGetDetailsButton(context, lang)
            : const SizedBox.shrink(),
        const SizedBox(height: 16),
        showRedeemButton
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRedeemButton(context, lang),
                const SizedBox(height: 16),
              ],
            )
            : const SizedBox.shrink(),
        if (!showRedeemButton) _buildSkipButton(context, lang),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGetDetailsButton(BuildContext context, L10n lang) {
    return ElevatedButton(
      onPressed:
          _tokenController.text.isNotEmpty
              ? () {
                if (!_formKey.currentState!.validate()) return;
                if (!inCI && !ref.read(hasNetworkProvider)) {
                  showNoInternetNotification(context);
                  return;
                }
                setState(() {
                  showInviteInfo = true;
                });
              }
              : null,
      child: Text(lang.getDetails, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildRedeemButton(BuildContext context, L10n lang) {
    return ActerPrimaryActionButton(
      onPressed:
          _tokenController.text.isNotEmpty
              ? () {
                if (!_formKey.currentState!.validate()) return;
                if (!inCI && !ref.read(hasNetworkProvider)) {
                  showNoInternetNotification(context);
                  return;
                }
                redeemToken(context, ref, _tokenController.text.trim());
              }
              : null,
      child: Text(lang.redeem, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSkipButton(BuildContext context, L10n lang) {
    return OutlinedButton(
      onPressed: () {
        EasyLoading.dismiss();
        context.goNamed(
          Routes.saveUsername.name,
          queryParameters: {'username': widget.username},
        );
      },
      child: Text(lang.skip),
    );
  }

  void redeemToken(BuildContext context, WidgetRef ref, String token) async {
    final lang = L10n.of(context);
    final superInvites = await ref.read(superInvitesProvider.future);

    EasyLoading.show(status: lang.redeeming(token));
    try {
      final rooms = (await superInvites.redeem(token)).toList();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.addedToSpacesAndChats(rooms.length));
      context.goNamed(
          Routes.saveUsername.name,
          queryParameters: {'username': widget.username},
        );
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.redeemingFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
