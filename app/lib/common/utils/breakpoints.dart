import 'package:flutter/material.dart';


class ActerBreakpoints {
  // Current custom breakpoint from acter_build_context.dart
  static const double largeScreen = 770;
  
  // flutter_adaptive_scaffold breakpoints (for migration reference)
  // Based on Material Design 3 specifications:
  // https://m3.material.io/foundations/layout/applying-layout/window-size-classes
  static const double small = 600;        // 0-599px
  static const double medium = 840;       // 600-839px  
  static const double mediumLarge = 1200; // 840-1199px
  static const double large = 1600;       // 1200-1599px
  // extraLarge = 1600+px
  
  // Other breakpoints found in the codebase
  static const double dashboard = 770;    // InDashboard widget
  static const double chatBubble = 770;   // Used for chat message width
  static const double sideSheet = 300;    // Minimum side sheet width
  static const double maxSideSheet = 450; // Maximum side sheet width
  
  /// Check if screen size is small (mobile)
  static bool isSmall(BuildContext context) {
    return MediaQuery.of(context).size.width < small;
  }
  
  /// Check if screen size is medium (tablet portrait)
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= small && width < medium;
  }
  
  /// Check if screen size is medium-large (tablet landscape)
  static bool isMediumLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= medium && width < mediumLarge;
  }
  
  /// Check if screen size is large (desktop)
  static bool isLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mediumLarge && width < large;
  }
  
  /// Check if screen size is extra large
  static bool isExtraLarge(BuildContext context) {
    return MediaQuery.of(context).size.width >= large;
  }
  
  /// Current custom large screen check (matches existing acter_build_context.dart)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeScreen;
  }
  
  /// Check if we should show sidebar navigation
  /// Currently: mediumLarge and up (from primaryNavigationLayout)
  static bool shouldShowSidebar(BuildContext context) {
    return MediaQuery.of(context).size.width >= mediumLarge;
  }
  
  /// Check if we should show bottom navigation  
  /// Currently: small and medium breakpoints
  static bool shouldShowBottomNavigation(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < mediumLarge;
  }
  
  /// Get responsive chat message width
  static double getChatMessageWidth(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return isLargeScreen(context) ? size.width * 0.5 : size.width * 0.75;
  }
  
  /// Get responsive side sheet width
  static double getSideSheetWidth(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width;
    double width = totalWidth / 1.4;
    if (width < sideSheet) {
      width = totalWidth * 0.95;
    } else if (width > maxSideSheet) {
      width = maxSideSheet;
    }
    return width;
  }
}

/// Animation configurations matching flutter_adaptive_scaffold behavior
class ActerAnimations {
  static const Duration transitionDuration = Duration(milliseconds: 300);
  
  // Slide animations (matching AdaptiveScaffold.bottomToTop, etc.)
  static SlideTransition bottomToTop(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }
  
  static SlideTransition topToBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, 1.0),
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }
  
  static SlideTransition leftToRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }
} 