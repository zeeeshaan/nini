import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:nini/features/home/presentation/pages/home_screen.dart';
import 'package:nini/shared/models/post/post_item.dart';

class DashboardShellScreen extends StatelessWidget {
  const DashboardShellScreen({
    super.key,
    this.initialTab = DashboardTab.home,
    this.profilePage,
    this.profileImage,
  });

  final DashboardTab initialTab;
  final Widget? profilePage;
  final ImageProvider? profileImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardNavigationCubit(initialTab: initialTab),
      child: _DashboardShellView(
        initialTab: initialTab,
        profilePage: profilePage,
        profileImage: profileImage,
      ),
    );
  }
}

class _DashboardShellView extends StatefulWidget {
  const _DashboardShellView({
    required this.initialTab,
    required this.profilePage,
    required this.profileImage,
  });

  final DashboardTab initialTab;
  final Widget? profilePage;
  final ImageProvider? profileImage;

  @override
  State<_DashboardShellView> createState() => _DashboardShellViewState();
}

class _DashboardShellViewState extends State<_DashboardShellView> {
  late final PageController _pageController;

  DashboardTab? _targetTab;

  static const Duration _transitionDuration = Duration(milliseconds: 300);

  static const Curve _transitionCurve = Curves.easeInOutCubic;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: widget.initialTab.index);
  }

  // Open Create Post as a separate full-screen route.
  Future<void> _openCreatePost() async {
    final published = await Navigator.of(context).push<PostItem>(
      MaterialPageRoute<PostItem>(
        builder: (_) => const CreatePostGalleryScreen(),
      ),
    );
    if (mounted && published != null) await _onTabSelected(DashboardTab.home);
  }

  Future<void> _onTabSelected(DashboardTab tab) async {
    // The Create (+) button opens the gallery instead
    // of changing the selected dashboard tab.
    if (tab == DashboardTab.create) {
      await _openCreatePost();
      return;
    }

    final navigationCubit = context.read<DashboardNavigationCubit>();

    if (navigationCubit.state == tab) return;

    navigationCubit.selectTab(tab);

    if (!_pageController.hasClients) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _targetTab = null;
      _pageController.jumpToPage(tab.index);
      return;
    }

    _targetTab = tab;

    await _pageController.animateToPage(
      tab.index,
      duration: _transitionDuration,
      curve: _transitionCurve,
    );

    if (mounted && _targetTab == tab) {
      _targetTab = null;
    }
  }

  void _onPageChanged(int index) {
    // Crossing intermediate pages must not activate
    // their entrance animations.
    if (_targetTab != null && index != _targetTab!.index) {
      return;
    }

    context.read<DashboardNavigationCubit>().selectPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, responsive) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<DashboardNavigationCubit, DashboardTab>(
              builder: (context, selectedTab) {
                final pages = <Widget>[
                  const HomeScreen(),

                  const StaggeredEntrance(
                    child: _PendingPage(title: AppStrings.cart),
                  ),

                  // This placeholder is retained for
                  // PageView index compatibility.
                  // Tapping (+) opens the gallery route.
                  const StaggeredEntrance(
                    child: _PendingPage(title: AppStrings.create),
                  ),

                  const StaggeredEntrance(
                    child: _PendingPage(title: AppStrings.search),
                  ),

                  StaggeredEntrance(
                    child:
                        widget.profilePage ??
                        const _PendingPage(title: AppStrings.profile),
                  ),
                ];

                return NotificationListener<ScrollStartNotification>(
                  onNotification: (notification) {
                    if (notification.depth == 0 &&
                        notification.dragDetails != null) {
                      _targetTab = null;
                    }

                    return false;
                  },
                  child: PageView(
                    key: const PageStorageKey<String>('dashboard_pages'),
                    controller: _pageController,
                    physics: const PageScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    children: [
                      for (final tab in DashboardTab.values)
                        ScreenEntrance(
                          key: ValueKey(tab),
                          active: selectedTab == tab,
                          child: pages[tab.index],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          bottomNavigationBar:
              BlocBuilder<DashboardNavigationCubit, DashboardTab>(
                builder: (context, selectedTab) {
                  return ScreenEntrance(
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
                  );
                },
              ),
        );
      },
    );
  }
}

class _PendingPage extends StatelessWidget {
  const _PendingPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
