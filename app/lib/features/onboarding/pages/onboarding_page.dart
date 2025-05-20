import 'dart:io';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/analytics/pages/analytics_opt_in_page.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart';
import 'package:acter/features/desktop_setup/pages/desktop_setup_page.dart';
import 'package:acter/features/notifications/pages/notification_permission_page.dart';
import 'package:acter/features/onboarding/pages/customization_page.dart';
import 'package:acter/features/onboarding/pages/onboarding_space_creation_page.dart';
import 'package:acter/features/onboarding/pages/recommended_spaces_page.dart';
import 'package:acter/features/onboarding/widgets/onboarding_notification_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/features/onboarding/pages/encrption_backup_page.dart';
import 'package:acter/features/onboarding/pages/link_email_page.dart';
import 'package:acter/features/onboarding/pages/upload_avatar_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/onboarding/providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final String? username;
  final bool? isLoginOnboarding;

  const OnboardingPage({
    super.key,
    this.username,
    this.isLoginOnboarding = false,
  });

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<Widget> _screens;

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  List<Widget> _buildOnboardingScreens(OnboardingPermissions permissions) {
    final hasSpaceRedeemedInvites = ref.watch(hasSpaceRedeemedInInviteCodeProvider);
    final hasRecommendedSpaceJoined = ref.watch(hasRecommendedSpaceJoinedProvider);

    return [
      if (!widget.isLoginOnboarding!) ...[
        SaveUsernamePage(
          username: widget.username ?? '',
          callNextPage: () => _nextPage(),
        ),
        RedeemInvitationsPage(callNextPage: () => _nextPage()),
        EncryptionBackupPage(username: widget.username ?? '', callNextPage: () => _nextPage()),
        LinkEmailPage(callNextPage: () => _nextPage()),
        UploadAvatarPage(callNextPage: () => _nextPage()),
        CustomizationPage(callNextPage: () => _nextPage()),
        if (!hasSpaceRedeemedInvites)
          RecommendedSpacesPage(callNextPage: () => _nextPage()),
        if (!hasSpaceRedeemedInvites && !hasRecommendedSpaceJoined)
          OnboardingSpaceCreationPage(callNextPage: () => _nextPage()),
      ],
      
      if (permissions.showNotificationPermission)
        NotificationPermissionWidget(callNextPage: () => _nextPage()),
      if (permissions.showCalendarPermission)
        CalendarSyncPermissionWidget(callNextPage: () => _nextPage()),
      if (Platform.isWindows || Platform.isMacOS)
        DesktopLaunchAtStartupWidget(callNextPage: () => _nextPage()),
      AnalyticsOptInWidget(
        callNextPage: () {
          _nextPage();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.goNamed(Routes.main.name);
          });
        },
      ),
    ];
  }

  Widget _buildPageIndicator(int totalPages) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalPages,
              (index) =>
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                  _currentPage == index
                      ? Theme
                      .of(context)
                      .colorScheme
                      .primary
                      : Colors.grey,
                ),
              ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onBoardingPermissionsProvider = ref.watch(onboardingPermissionsProvider);

    return onBoardingPermissionsProvider.when(
      loading: () => const OnboardingSkeleton(),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (permissions) {
        _screens = _buildOnboardingScreens(permissions);
        return Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: _screens,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildPageIndicator(_screens.length),
              ),
            ],
          ),
        );
      },
    );
  }
}
