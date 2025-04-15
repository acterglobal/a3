import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/features/onboarding/pages/encrption_backup_page.dart';
import 'package:acter/features/onboarding/pages/link_email_page.dart';
import 'package:acter/features/onboarding/pages/upload_avatar_page.dart';
import 'package:acter/features/onboarding/providers/post_login_signup_provider.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final String username;
  const OnboardingPage({super.key, required this.username});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() {
    final state = ref.read(postLoginSignupProvider);
    if (state.currentStep == PostLoginSignupStep.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed(Routes.main.name);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          SaveUsernamePage(
            username: widget.username,
            currentPage: _currentPage,
            totalPages: 5,
            onCopied: (copied) {
              if (copied) {
                ref
                    .read(postLoginSignupProvider.notifier)
                    .completeStep(context, PostLoginSignupStep.saveUsername);
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          RedeemInvitationsPage(
            currentPage: _currentPage,
            totalPages: 5,
            onRedeemed: (redeemed) {
              if (redeemed) {
                ref
                    .read(postLoginSignupProvider.notifier)
                    .completeStep(
                      context,
                      PostLoginSignupStep.redeemInvitations,
                    );
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          EncryptionBackupPage(
            currentPage: _currentPage,
            totalPages: 5,
            onEnabled: (enabled) {
              if (enabled) {
                ref
                    .read(postLoginSignupProvider.notifier)
                    .completeStep(
                      context,
                      PostLoginSignupStep.encryptionBackup,
                    );
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          LinkEmailPage(
            currentPage: _currentPage,
            totalPages: 5,
            onLinked: (linked) {
              if (linked) {
                ref
                    .read(postLoginSignupProvider.notifier)
                    .completeStep(context, PostLoginSignupStep.linkEmail);
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          UploadAvatarPage(
            currentPage: _currentPage,
            totalPages: 5,
            onUploaded: (uploaded) {
              if (uploaded) {
                ref
                    .read(postLoginSignupProvider.notifier)
                    .completeStep(context, PostLoginSignupStep.uploadAvatar);
              }
            },
          ),
        ],
      ),
    );
  }
}
