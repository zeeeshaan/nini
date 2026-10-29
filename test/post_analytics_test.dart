import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/responsive_config/config.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/post_analytics/data/post_analytics_repository.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:nini/features/post_analytics/presentation/pages/post_analytics_screen.dart';
import 'package:nini/features/post_analytics/presentation/widgets/activity_tracking/post_activity_tracking.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_chart/analytics_charts.dart';
import 'package:nini/features/post_analytics/presentation/widgets/analytics_controls/analytics_controls.dart';
import 'package:nini/features/post_analytics/presentation/widgets/clicks_interactions/clicks_interactions.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/posts/data/demo_posts.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

PostItem publishedPost() => PostItem(
  id: 'published',
  imageAsset: 'assets/img1.png',
  title: 'My post',
  category: AppStrings.product,
  stockCount: 0,
  price: '',
  originalPrice: '',
  publishedAt: DateTime(2026, 10, 1),
);

Widget host(PostAnalyticsCubit cubit, Widget child, {bool dark = false}) =>
    ResponsiveConfig(
      child: BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          navigatorObservers: [entranceRouteObserver],
          home: child,
        ),
      ),
    );

void main() {
  test(
    'Analytics storage round-trips events and serializes concurrent updates',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nini_analytics_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = LocalPostAnalyticsRepository(
        directoryProvider: () async => directory,
      );
      final cubit = PostAnalyticsCubit(
        repository,
        clock: () => DateTime(2026, 10, 29),
      );
      addTearDown(cubit.close);
      await Future.wait(
        List.generate(20, (_) => cubit.record('one', AnalyticsEventType.view)),
      );
      final restored = await repository.load();
      expect(restored, hasLength(20));
      expect(restored.map((e) => e.id).toSet(), hasLength(20));
      expect(restored.first.postId, 'one');
      expect(restored.first.type, AnalyticsEventType.view);
      expect(restored.first.at, DateTime(2026, 10, 29));
    },
  );

  test(
    'Unreadable analytics are preserved when recording a new event',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nini_analytics_corrupt_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/post_analytics.json');
      await file.writeAsString('{bad data');
      final cubit = PostAnalyticsCubit(
        LocalPostAnalyticsRepository(directoryProvider: () async => directory),
      );
      addTearDown(cubit.close);
      await cubit.record('one', AnalyticsEventType.view);
      expect(cubit.state.storageError, isTrue);
      expect(cubit.state.events, hasLength(1));
      expect(await file.readAsString(), '{bad data');
    },
  );

  test('Reports filter dates and calculate watch averages per session', () {
    final now = DateTime(2026, 10, 29);
    var id = 0;
    PostAnalyticsEvent event(
      AnalyticsEventType type, {
      DateTime? date,
      double value = 1,
      String source = 'other',
    }) => PostAnalyticsEvent(
      id: '${id++}',
      postId: 'one',
      type: type,
      at: date ?? now,
      value: value,
      source: source,
    );
    final report = PostAnalyticsReport.fromEvents(
      [
        event(AnalyticsEventType.view),
        event(AnalyticsEventType.view, date: DateTime(2026, 11)),
        event(AnalyticsEventType.view, date: DateTime(2025)),
        event(AnalyticsEventType.impression, value: 3, source: 'home'),
        event(AnalyticsEventType.interaction, source: 'like'),
        event(AnalyticsEventType.interaction, source: 'save'),
        event(AnalyticsEventType.watch, value: 10, source: 'sessionA'),
        event(AnalyticsEventType.watch, value: 20, source: 'sessionA'),
        event(AnalyticsEventType.watch, value: 30, source: 'sessionB'),
        event(
          AnalyticsEventType.watch,
          value: 90,
          source: 'previous',
          date: DateTime(2026, 4),
        ),
      ],
      AnalyticsPeriod.halfYear,
      now,
    );
    expect(report.totalViews, 1);
    expect(report.totalImpressions, 3);
    expect(report.totalInteractions, 2);
    expect(report.averageWatch, 30);
    expect(report.averageSeconds.last, 30);
    expect(report.previousSeconds.last, 90);
    expect(report.dailyOrders, everyElement(0));
  });

  testWidgets('Home impressions count visibility transitions once', (
    tester,
  ) async {
    final cubit = PostAnalyticsCubit(MemoryPostAnalyticsRepository());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      host(
        cubit,
        Scaffold(
          body: ListView(
            children: [
              PostImpressionTracker(
                post: publishedPost(),
                child: const SizedBox(height: 200),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await cubit.pendingWrites;
    expect(
      cubit
          .eventsFor('published')
          .where((e) => e.type == AnalyticsEventType.impression),
      hasLength(1),
    );
    await tester.pump();
    expect(cubit.eventsFor('published'), hasLength(1));
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await cubit.pendingWrites;
    expect(
      cubit
          .eventsFor('published')
          .where((e) => e.type == AnalyticsEventType.impression),
      hasLength(2),
    );
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets('Analytics layout and controls at $width, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = PostAnalyticsCubit(MemoryPostAnalyticsRepository());
        addTearDown(cubit.close);
        await tester.pumpWidget(
          host(cubit, PostAnalyticsScreen(post: demoPosts.first), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.sampleData), findsOneWidget);
        expect(find.byType(AnalyticsLineChart), findsNWidgets(2));
        expect(find.byType(AnalyticsRadarChart), findsOneWidget);
        expect(find.byType(AnalyticsPolarChart), findsOneWidget);
        expect(find.byType(AnalyticsOrdersChart), findsOneWidget);
        expect(
          Theme.of(tester.element(find.text(AppStrings.analytics)))
              .scaffoldBackgroundColor,
          dark ? Colors.black : Colors.white,
        );
        final chart = find.byType(AnalyticsLineChart).first;
        final tooltip = find.descendant(
          of: chart,
          matching: find.byType(AnalyticsTooltip),
        );
        final initialValues = tester.widget<AnalyticsTooltip>(tooltip).values;
        await tester.tapAt(tester.getTopLeft(chart) + const Offset(20, 30));
        await tester.pumpAndSettle();
        expect(
          tester.widget<AnalyticsTooltip>(tooltip).values,
          isNot(initialValues),
        );
        await tester.tap(
          find.byTooltip(AppStrings.analyticsPeriod(AppStrings.totalViews)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.threeMonths));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.threeMonths), findsOneWidget);
        expect(find.text(AppStrings.sixMonths), findsNWidgets(3));
        final legend = find
            .descendant(
              of: find.byType(ClicksInteractionsSection),
              matching: find.byType(AnalyticsLegend),
            )
            .first;
        await tester.ensureVisible(legend);
        await tester.tap(legend);
        await tester.pumpAndSettle();
        expect(tester.widget<AnalyticsLegend>(legend).selected, isFalse);
        await tester.ensureVisible(find.byType(AnalyticsOrdersChart));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.sampleHours), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Published post uses its own metrics and analytics navigation keeps likes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = PostAnalyticsCubit(MemoryPostAnalyticsRepository());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        host(cubit, PostDetailScreen(post: publishedPost())),
      );
      await tester.pumpAndSettle();
      Finder icon(String asset) =>
          find.byWidgetPredicate((w) => w is AppIcon && w.asset == asset);
      await tester.ensureVisible(icon(AppIcons.heart));
      await tester.tap(icon(AppIcons.heart));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.viewAnalytics));
      await tester.pumpAndSettle();
      expect(find.byType(PostAnalyticsScreen), findsOneWidget);
      expect(find.text(AppStrings.onThisDevice), findsOneWidget);
      expect(find.text(AppStrings.sampleData), findsNothing);
      expect(find.text(AppStrings.sampleRevenue), findsNothing);
      expect(find.text(AppStrings.sampleHours), findsNothing);
      await cubit.pendingWrites;
      expect(
        cubit
            .eventsFor('published')
            .where((e) => e.type == AnalyticsEventType.view),
        hasLength(1),
      );
      expect(
        cubit
            .eventsFor('published')
            .where(
              (e) =>
                  e.type == AnalyticsEventType.interaction &&
                  e.source == 'like',
            ),
        hasLength(1),
      );
      await tester.tap(find.byTooltip(AppStrings.back));
      await tester.pumpAndSettle();
      expect(tester.widget<AppIcon>(icon(AppIcons.heart)).selected, isTrue);
      expect(
        cubit
            .eventsFor('published')
            .where((e) => e.type == AnalyticsEventType.view),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
