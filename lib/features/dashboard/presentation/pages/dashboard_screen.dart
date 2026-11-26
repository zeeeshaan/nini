import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/animations/staggered_animation/staggered_animation.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'package:hywork/features/cart/presentation/pages/cart_screen.dart';
import 'package:hywork/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:hywork/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:hywork/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:hywork/features/home/presentation/pages/home_screen.dart';
import 'package:hywork/features/profile/presentation/pages/profile_screen.dart';
import 'package:hywork/features/profile/presentation/helpers/open_account_profile.dart';
import 'package:hywork/features/search/presentation/pages/search_screen.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/shared/widgets/app_images/profile_image_provider.dart';

// dart format width=100

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialTab = DashboardTab.profile,
    this.profilePage,
    this.profileImage,
  });

  final DashboardTab initialTab;
  final Widget? profilePage;
  final ImageProvider? profileImage;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  late final DashboardNavigationCubit _navigation;

  DashboardTab? _targetTab;
  bool _createRouteOpen = false;
  bool _createSwipeScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _navigation = DashboardNavigationCubit(initialTab: widget.initialTab);

    _pageController = PageController(initialPage: widget.initialTab.index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final notifications = context.read<NotificationsCubit?>();
      if (notifications != null) {
        unawaited(notifications.refreshUnreadCount());
      }
    }
  }

  Future<void> _onTabSelected(DashboardTab tab) async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (tab == DashboardTab.create) {
      await _openCreatePost();
      return;
    }

    await _changeTab(tab);
  }

  Future<void> _openCreatePost() async {
    if (_createRouteOpen) return;
    _createRouteOpen = true;
    try {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const CreatePostGalleryScreen(),
        ),
      );
      if (created == true && mounted) {
        unawaited(context.read<OwnPostsCubit?>()?.refresh());
      }
    } finally {
      _createRouteOpen = false;
    }
  }

  void _openCreateAfterSwipe() {
    if (_createSwipeScheduled || _createRouteOpen) return;
    final previous = _navigation.state;
    _createSwipeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createSwipeScheduled = false;
      if (!mounted ||
          _createRouteOpen ||
          _targetTab != null ||
          _navigation.state != previous ||
          !_pageController.hasClients ||
          _pageController.page?.round() != DashboardTab.create.index) {
        return;
      }
      // Create is a route, so keep the originating page selected underneath.
      _pageController.jumpToPage(previous.index);
      _openCreatePost();
    });
  }

  Future<void> _changeTab(DashboardTab tab) async {
    if (_navigation.state == tab) return;

    _navigation.selectTab(tab);

    if (!_pageController.hasClients) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _targetTab = null;
      _pageController.jumpToPage(tab.index);
      return;
    }

    _targetTab = tab;

    await _pageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    if (mounted && _targetTab == tab) {
      _targetTab = null;
    }
  }

  void _openAccountProfileTab() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context).popUntil((current) => current == route);
    }
    _onTabSelected(DashboardTab.profile);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _navigation.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileCubit?>()?.state.profile;
    final profileImage = profile == null
        ? widget.profileImage
        : profileImageProvider(profile.avatarPath);
    return AccountProfileNavigation(
      onOpenProfile: _openAccountProfileTab,
      child: BlocBuilder<DashboardNavigationCubit, DashboardTab>(
        bloc: _navigation,
        builder: (context, selectedTab) {
          final pages = [
            HomeScreen(
              active: selectedTab == DashboardTab.home,
              onViewCart: () => _onTabSelected(DashboardTab.cart),
              onProfilePressed: _openAccountProfileTab,
            ),
            CartScreen(
              active: selectedTab == DashboardTab.cart,
              onBack: () => _onTabSelected(DashboardTab.home),
            ),
            // Show the actual gallery layout while swiping; media access starts
            // only when the Create route opens after the swipe settles.
            const CreatePostGalleryScreen(previewOnly: true),
            SearchScreen(
              active: selectedTab == DashboardTab.search,
              emptyStateTextAlign: TextAlign.center,
            ),
            widget.profilePage ?? const ProfileScreen(),
          ];

          return AppResponsiveBuilder(
            builder: (context, responsive) {
              return Scaffold(
                body: SafeArea(
                  bottom: false,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.depth != 0) return false;
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _targetTab = null;
                      }
                      if (notification is ScrollEndNotification &&
                          notification.metrics is PageMetrics &&
                          (notification.metrics as PageMetrics).page?.round() ==
                              DashboardTab.create.index &&
                          _targetTab == null) {
                        _openCreateAfterSwipe();
                      }
                      return false;
                    },
                    child: PageView(
                      key: const PageStorageKey<String>('dashboard_tabs'),
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (index != DashboardTab.create.index &&
                            (_targetTab == null ||
                                index == _targetTab!.index)) {
                          _navigation.selectPage(index);
                          if (index == DashboardTab.profile.index) {
                            context.read<OwnPostsCubit?>()?.refresh();
                          }
                        }
                      },
                      children: [
                        for (final tab in DashboardTab.values)
                          ScreenEntrance(
                            key: ValueKey(tab),
                            active: selectedTab == tab,
                            child: tab == DashboardTab.search
                                ? pages[tab.index]
                                : StaggeredEntrance(child: pages[tab.index]),
                          ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: ScreenEntrance(
                  child: StaggeredEntrance(
                    distance: 10,
                    child: DashboardBottomNav(
                      selectedTab: selectedTab,
                      onTabSelected: _onTabSelected,
                      profileImage: profileImage,
                      maxContentWidth: responsive.isExpanded
                          ? 720
                          : double.infinity,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
