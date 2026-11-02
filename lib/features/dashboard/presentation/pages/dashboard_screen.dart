import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/cart/presentation/pages/cart_screen.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:nini/features/home/presentation/pages/home_screen.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/profile/presentation/page/profile_screen/profile_screen.dart';
import 'package:nini/features/search/presentation/page/search_screen/search_screen.dart';
import 'package:nini/shared/models/post/post_item.dart';

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

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;
  late final DashboardNavigationCubit _navigation;
  DashboardTab? _targetTab;

  @override
  void initState() {
    super.initState();
    _navigation = DashboardNavigationCubit(initialTab: widget.initialTab);
    _pageController = PageController(initialPage: widget.initialTab.index);
  }

  Future<void> _onTabSelected(DashboardTab tab) async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (tab == DashboardTab.create) {
      final published = await Navigator.of(context).push<PostItem>(
        MaterialPageRoute<PostItem>(
          builder: (_) => const CreatePostGalleryScreen(),
        ),
      );
      if (mounted && published != null) {
        context.read<ProfileCategoriesCubit>().select(
          published.profileCategoryId,
        );
        await _onTabSelected(DashboardTab.profile);
      }
      return;
    }
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
    if (mounted && _targetTab == tab) _targetTab = null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navigation.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardNavigationCubit, DashboardTab>(
      bloc: _navigation,
      builder: (context, selectedTab) {
        final pages = [
          HomeScreen(onViewCart: () => _onTabSelected(DashboardTab.cart)),
          CartScreen(
            active: selectedTab == DashboardTab.cart,
            onBack: () => _onTabSelected(DashboardTab.home),
          ),
          // Create opens a separate route; retain its slot for swipe indexes.
          const Center(
            child: Text(AppStrings.create, style: TextStyle(fontSize: 22)),
          ),
          SearchScreen(active: selectedTab == DashboardTab.search),
          widget.profilePage ?? const ProfileScreen(),
        ];
        return AppResponsiveBuilder(
          builder: (context, responsive) => Scaffold(
            body: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 &&
                      notification.dragDetails != null) {
                    _targetTab = null;
                  }
                  return false;
                },
                child: PageView(
                  key: const PageStorageKey<String>('dashboard_tabs'),
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (_targetTab == null || index == _targetTab!.index) {
                      _navigation.selectPage(index);
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
                  profileImage: widget.profileImage,
                  maxContentWidth: responsive.isExpanded
                      ? 720
                      : double.infinity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
