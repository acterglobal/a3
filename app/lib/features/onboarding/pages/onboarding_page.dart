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

  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _redirectIfCompleted();
  }

  void _redirectIfCompleted() {
    final state = ref.read(postLoginSignupProvider);
    if (state.currentStep == PostLoginSignupStep.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.goNamed(Routes.main.name);
      });
    }
  }

  void _completeStepAndNext(PostLoginSignupStep step) {
    ref.read(postLoginSignupProvider.notifier).completeStep(context, step);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildOnboardingPages() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentPage = index),
      children: [
        SaveUsernamePage(
          username: widget.username,
          currentPage: _currentPage,
          totalPages: _totalPages,
          onCopied: (copied) {
            if (copied) _completeStepAndNext(PostLoginSignupStep.saveUsername);
          },
        ),
        RedeemInvitationsPage(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onRedeemed: (redeemed) {
            if (redeemed) _completeStepAndNext(PostLoginSignupStep.redeemInvitations);
          },
        ),
        EncryptionBackupPage(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onEnabled: (enabled) {
            if (enabled) _completeStepAndNext(PostLoginSignupStep.encryptionBackup);
          },
        ),
        LinkEmailPage(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onLinked: (linked) {
            if (linked) _completeStepAndNext(PostLoginSignupStep.linkEmail);
          },
        ),
        UploadAvatarPage(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onUploaded: (uploaded) {
            if (uploaded) {
              ref.read(postLoginSignupProvider.notifier).completeStep(
                    context,
                    PostLoginSignupStep.uploadAvatar,
                  );
              // Optionally go to main route or show a done message here
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildOnboardingPages(),
    );
  }
}
