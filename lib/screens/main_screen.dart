import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:trackord/l10n/l10n.dart';
import 'package:trackord/screens/categories.dart';
import 'package:trackord/screens/multi_chart.dart';
import 'package:trackord/screens/settings.dart';
import 'package:trackord/utils/defines.dart';
import 'package:trackord/utils/styling.dart';

class MainScreen extends StatelessWidget {
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  MainScreen({super.key});

  List<Widget> _buildScreens() {
    return [
      const CategoriesPage(),
      const MultiChartPage(),
      const SettingsPage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.list),
        title: context.l10n.categoriesPageDefaultTitle,
        activeColorPrimary: Theme.of(context).colorScheme.onSecondaryContainer,
        inactiveColorPrimary: Theme.of(context).colorScheme.inverseSurface,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.bar_chart),
        title: context.l10n.multiChartTitle,
        activeColorPrimary: Theme.of(context).colorScheme.onSecondaryContainer,
        inactiveColorPrimary: Theme.of(context).colorScheme.inverseSurface,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: context.l10n.settingsTitle,
        activeColorPrimary: Theme.of(context).colorScheme.onSecondaryContainer,
        inactiveColorPrimary: Theme.of(context).colorScheme.inverseSurface,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(context),
      confineToSafeArea: false,
      backgroundColor: getPersistentNavColor(context),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      navBarHeight: kNavBarHeight,
      padding: const EdgeInsets.only(bottom: 15),
      hideNavigationBarWhenKeyboardAppears: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          // Navigation Bar's items animation properties.
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          // Screen transition animation on change of selected tab.
          animateTabTransition: true,
          duration: Duration(milliseconds: 200),
          screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
        ),
        onNavBarHideAnimation: OnHideAnimationSettings(
          duration: Duration(milliseconds: 100),
          curve: Curves.bounceInOut,
        ),
      ),
      navBarStyle: NavBarStyle.style1,
    );
  }
}
