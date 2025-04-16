import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:acter/features/analytics/pages/analytics_opt_in_page.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart';
import 'package:acter/features/notifications/pages/notification_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/features/onboarding/pages/encrption_backup_page.dart';
import 'package:acter/features/onboarding/pages/link_email_page.dart';
import 'package:acter/features/onboarding/pages/upload_avatar_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:go_router/go_router.dart';

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
  bool _showNotificationPermission = false;
  bool _showCalendarPermission = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final showNotification = await isShowNotificationPermissionInfoPage();
    final showCalendar = await isShowCalendarPermissionInfoPage();
    setState(() {
      _showNotificationPermission = showNotification;
      _showCalendarPermission = showCalendar;
    });
  }

  void _nextPage() {
    if (_currentPage < _buildOnboardingScreens().length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  List<Widget> _buildOnboardingScreens() {
    return [
      if (!widget.isLoginOnboarding!) ...[
        SaveUsernamePage(
          username: widget.username ?? '',
          callNextPage: () => _nextPage(),
        ),
        RedeemInvitationsPage(callNextPage: () => _nextPage()),
        EncryptionBackupPage(callNextPage: () => _nextPage()),
        LinkEmailPage(callNextPage: () => _nextPage()),
        UploadAvatarPage(callNextPage: () => _nextPage()),
      ],
      if (_showNotificationPermission)
        NotificationPermissionWidget(callNextPage: () => _nextPage()),
      if (_showCalendarPermission)
        CalendarSyncPermissionWidget(callNextPage: () => _nextPage()),
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

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _buildOnboardingScreens().length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _currentPage == index
                      ? Theme.of(context).colorScheme.primary
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
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: _buildOnboardingScreens(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );
  }
}
