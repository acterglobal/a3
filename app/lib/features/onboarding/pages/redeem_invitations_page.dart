import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/dotted_border_widget.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:acter_avatar/acter_avatar.dart';
import 'dart:async';

class RedeemInvitationsPage extends ConsumerStatefulWidget {
  final CallNextPage? callNextPage;

  const RedeemInvitationsPage({super.key, required this.callNextPage});

  @override
  ConsumerState<RedeemInvitationsPage> createState() =>
      _RedeemInvitationsPageState();
}

class _RedeemInvitationsPageState extends ConsumerState<RedeemInvitationsPage> {
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<String> validTokens = [];
  Timer? _debounceTimer;
  bool hasRedeemedAnyToken = false;

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

  Future<void> _fetchAndValidateToken(String token) async {
    if (!mounted) return;

    try {
      EasyLoading.show(status: L10n.of(context).loading);
      await ref.watch(superInviteInfoProvider(token).future);
      if (!validTokens.contains(token)) {
        setState(() {
          validTokens.insert(0, token);
        });
      }
      _tokenController.clear();
      EasyLoading.dismiss();
      
    } catch (e) {
      if (mounted) {
        EasyLoading.showError(
          e.toString(),
          duration: const Duration(seconds: 2),
          dismissOnTap: true,
        );
      }
    }
  }

  Future<void> _loadToken() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('invitation_token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        _tokenController.text = token;
      });
      await _fetchAndValidateToken(token);
    }
  }

  void _onTokenChanged(String token) {
    // Cancel any previous timer
    _debounceTimer?.cancel();

    // Start a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_formKey.currentState!.validate()) {
        if (!inCI && !ref.read(hasNetworkProvider)) {
          if (mounted) {
            showNoInternetNotification(L10n.of(context));
          }
          return;
        }

        final currentToken = token.trim();
        await _fetchAndValidateToken(currentToken);
      }
    });
  }

  Future<void> _scanQR(BuildContext context) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(L10n.of(context).scanQrCode),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: QRCodeDartScanView(
                scanInvertedQRCode: true,
                intervalScan: const Duration(milliseconds: 300),
                typeScan: TypeScan.live,
                onCapture: (r) => _onCapture(context, r),
                onCameraError: (error) {
                  if (mounted) {
                    EasyLoading.showError(
                      'Failed to open camera: $error',
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
            ),
      ),
    );
  }

  Future<void> _onCapture(BuildContext context, Result result) async {
    if (context.mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      await _fetchAndValidateToken(result.text);
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
                  _buildInviteInfo(context),
                ],
              ),
            ),
            _buildNavigationButtons(context, lang),
            const SizedBox(height: 30),
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
    return Expanded(
      child: ListView.builder(
        itemCount: validTokens.length,
        itemBuilder: (context, index) {
          final token = validTokens[index];
          final info = ref.watch(superInviteInfoProvider(token)).value;
          if (info == null) return const SizedBox.shrink();

          return _buildInviteInfoItem(context, token, info, index);
        },
      ),
    );
  }

  Widget _buildInviteInfoItem(
    BuildContext context,
    String token,
    SuperInviteInfo info,
    int index,
  ) {
    final displayName = info.inviterDisplayNameStr();
    final userId = info.inviterUserIdStr();
    final inviter = displayName ?? userId;
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              title: Text(inviter),
              subtitle: Text(lang.youInvited(info.roomsCount())),
              leading: ActerAvatar(
                options: AvatarOptions.DM(
                  AvatarInfo(uniqueId: userId, displayName: displayName),
                  size: 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DottedBorderWidget(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 6,
                      ),
                      child: Text(token),
                    ),
                  ),
                  ActerPrimaryActionButton(
                    key: Key('redeem-code-$index'),
                    onPressed:
                        info.hasRedeemed()
                            ? null
                            : () async {
                              if (!inCI && !ref.read(hasNetworkProvider)) {
                                showNoInternetNotification(L10n.of(context));
                                return;
                              }
                              redeemToken(context, ref, token);
                            },
                    child: Text(
                      info.hasRedeemed() ? lang.redeemed : lang.redeem,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...[
          const SizedBox(height: 5),
          _buildActionButton(context, lang),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, L10n lang) {
    if (hasRedeemedAnyToken) {
      return ActerPrimaryActionButton(
        onPressed: () {
          EasyLoading.dismiss();
          widget.callNextPage?.call();
        },
        child: Text(lang.wizzardContinue, style: const TextStyle(fontSize: 16)),
      );
    }

    return OutlinedButton(
      onPressed: () {
        EasyLoading.dismiss();
        widget.callNextPage?.call();
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
      EasyLoading.showSuccess(lang.addedToSpacesAndChats(rooms.length));
     
      // Set the flag indicating token redemption
      final preferences = await sharedPrefs();
      await preferences.setBool('has_redeemed_any_token', true);
      
      // Remove redeemed token from list
      setState(() {
        validTokens.remove(token);
        hasRedeemedAnyToken = true;
      });
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
