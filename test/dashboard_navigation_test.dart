import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/core/network/api_client.dart';
import 'package:nini/features/cart/data/local_cart_repository.dart';
import 'package:nini/features/cart/domain/models/cart_snapshot.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/create_post/data/api_categories_repository.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/features/create_post/presentation/widgets/gallery/gallery_content.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_nav_item.dart';

class _EmptyCart extends Fake implements LocalCartRepository {
  @override
  Future<CartSnapshot?> load() async => CartSnapshot(items: []);
}

class _CategoriesApi extends ApiClient {
  @override
  Future<Map<String, dynamic>> getPublic(
    String endpoint, {
    String? token,
  }) async => {'success': true, 'data': <Object>[]};
}

void main() {
  Future<void> openDashboard(
    WidgetTester tester, {
    DashboardTab tab = DashboardTab.home,
  }) async {
    final cart = CartCubit(_EmptyCart());
    await cart.load();
    addTearDown(cart.close);
    await tester.pumpWidget(
      RepositoryProvider<ApiCategoriesRepository>(
        create: (_) => ApiCategoriesRepository(_CategoriesApi()),
        child: BlocProvider<CartCubit>.value(
          value: cart,
          child: MaterialApp(
            home: DashboardScreen(
              initialTab: tab,
              profilePage: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  DashboardTab selected(WidgetTester tester) => tester
      .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
      .selectedTab;
  final pager = find.byKey(const PageStorageKey<String>('dashboard_tabs'));
  Future<void> pumpCreateRoute(WidgetTester tester) async {
    // The gallery can keep a loading animation active without native plugins.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'swiping from Home through Cart opens Create and closing returns to Cart',
    (tester) async {
      await openDashboard(tester);
      await tester.drag(pager, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(selected(tester), DashboardTab.cart);
      await tester.drag(pager, const Offset(-500, 0));
      await pumpCreateRoute(tester);
      expect(find.byType(CreatePostGalleryScreen), findsOneWidget);
      await tester.tap(find.byTooltip(CreatePostStrings.close));
      await tester.pumpAndSettle();
      expect(selected(tester), DashboardTab.cart);
      expect(
        tester.widget<PageView>(pager).controller!.page,
        DashboardTab.cart.index,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('swiping from Search to Create returns to Search on close', (
    tester,
  ) async {
    await openDashboard(tester, tab: DashboardTab.search);
    await tester.drag(pager, const Offset(500, 0));
    await pumpCreateRoute(tester);
    expect(find.byType(CreatePostGalleryScreen), findsOneWidget);
    await tester.tap(find.byTooltip(CreatePostStrings.close));
    await tester.pumpAndSettle();
    expect(selected(tester), DashboardTab.search);
    expect(
      tester.widget<PageView>(pager).controller!.page,
      DashboardTab.search.index,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reversing a swipe before settling does not open Create', (
    tester,
  ) async {
    await openDashboard(tester, tab: DashboardTab.cart);
    final gesture = await tester.startGesture(tester.getCenter(pager));
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(500, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(CreatePostGalleryScreen), findsNothing);
    expect(selected(tester), DashboardTab.cart);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a partial swipe shows the gallery layout without requesting media access',
    (tester) async {
      await openDashboard(tester, tab: DashboardTab.cart);
      final gesture = await tester.startGesture(tester.getCenter(pager));
      await gesture.moveBy(const Offset(-500, 0));
      await tester.pump();
      final preview = find.byWidgetPredicate(
        (widget) => widget is CreatePostGalleryScreen && widget.previewOnly,
      );
      expect(preview, findsOneWidget);
      final gallery = find.descendant(
        of: preview,
        matching: find.byType(GalleryContent),
      );
      expect(gallery, findsOneWidget);
      expect(
        tester.element(gallery).read<GalleryCubit>().state.status,
        GalleryStatus.initial,
      );
      expect(find.text('Create Post'), findsNothing);
      await gesture.up();
      await pumpCreateRoute(tester);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is CreatePostGalleryScreen && !widget.previewOnly,
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip(CreatePostStrings.close));
      await tester.pumpAndSettle();
      expect(selected(tester), DashboardTab.cart);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bottom navigation can cross Create and tapping Create keeps the current tab',
    (tester) async {
      await openDashboard(tester);
      Finder tab(DashboardTab value) => find.byWidgetPredicate(
        (widget) => widget is DashboardNavItem && widget.tab == value,
      );
      await tester.tap(tab(DashboardTab.search));
      await tester.pumpAndSettle();
      expect(selected(tester), DashboardTab.search);
      expect(find.byType(CreatePostGalleryScreen), findsNothing);
      await tester.tap(tab(DashboardTab.create));
      await pumpCreateRoute(tester);
      expect(find.byType(CreatePostGalleryScreen), findsOneWidget);
      await tester.tap(find.byTooltip(CreatePostStrings.close));
      await tester.pumpAndSettle();
      expect(selected(tester), DashboardTab.search);
      expect(tester.takeException(), isNull);
    },
  );
}
