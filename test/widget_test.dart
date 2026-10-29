import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:nini/features/dashboard/presentation/widgets/bottom_navbar/dashboard_bottom_nav.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/engagement_bar/post_engagement_bar.dart';
import 'package:nini/main.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'support/empty_posts_repository.dart';

Finder clientIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All client icons are bundled; reference sheets are excluded', () async {
    final entries = [
      ...jsonDecode(File('tool/client_icons.json').readAsStringSync()) as List,
      ...jsonDecode(File('tool/supplemental_vectors.json').readAsStringSync())
          as List,
    ];
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    expect(entries, hasLength(1078));
    for (final entry in entries) {
      final asset = entry['asset'] as String;
      expect(assets, contains(asset), reason: 'Missing bundled client icon');
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
      expect(assets, isNot(contains(entry['source'])));
      if (entry['reference_crop'] != null) {
        expect(assets, isNot(contains(entry['reference_crop'])));
        final svg = utf8.decode(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        expect(svg, contains('<svg'));
        expect(
          svg,
          isNot(contains('<image')),
          reason: 'Vector must not embed a bitmap: $asset',
        );
      }
    }
  });

  testWidgets('Home uses client icons and tab navigation still works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ResponsiveConfig(
        child: MyApp(postsRepository: EmptyPostsRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(clientIcon(AppIcons.home), findsOneWidget);
    expect(clientIcon(AppIcons.cart), findsOneWidget);
    expect(clientIcon(AppIcons.chat), findsOneWidget);
    expect(clientIcon(AppIcons.more), findsOneWidget);
    expect(clientIcon(AppIcons.add), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.tap(clientIcon(AppIcons.search));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
          .selectedTab,
      DashboardTab.search,
    );
    expect(find.text(AppStrings.search), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(clientIcon(AppIcons.home));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DashboardBottomNav>(find.byType(DashboardBottomNav))
          .selectedTab,
      DashboardTab.home,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Post icon actions work at width $width', (tester) async {
      final cubit = PostDetailCubit();
      addTearDown(cubit.close);
      var shares = 0;
      var comments = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: BlocProvider.value(
                  value: cubit,
                  child: PostEngagementBar(
                    onSharePressed: () => shares++,
                    onCommentsPressed: () => comments++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(clientIcon(AppIcons.heart));
      await tester.pumpAndSettle();
      expect(cubit.state.isLiked, isTrue);
      expect(
        tester.widget<AppIcon>(clientIcon(AppIcons.heart)).selected,
        isTrue,
      );

      await tester.tap(clientIcon(AppIcons.bookmark));
      await tester.pumpAndSettle();
      expect(cubit.state.isBookmarked, isTrue);
      expect(
        tester.widget<AppIcon>(clientIcon(AppIcons.bookmark)).selected,
        isTrue,
      );

      await tester.tap(clientIcon(AppIcons.share));
      await tester.tap(find.byTooltip(AppStrings.comments));
      expect(shares, 1);
      expect(comments, 1);

      await tester.tap(clientIcon(AppIcons.heart));
      await tester.tap(clientIcon(AppIcons.bookmark));
      await tester.pumpAndSettle();
      expect(cubit.state.isLiked, isFalse);
      expect(cubit.state.isBookmarked, isFalse);
      expect(
        tester.widget<AppIcon>(clientIcon(AppIcons.heart)).selected,
        isFalse,
      );
      expect(
        tester.widget<AppIcon>(clientIcon(AppIcons.bookmark)).selected,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
