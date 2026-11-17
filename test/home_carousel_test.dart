import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/features/home/presentation/widgets/published/home_post_media_slider.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

const _post = PostItem(
  id: 'carousel-post',
  imageAsset: 'assets/img1.png',
  title: 'Carousel',
  category: 'Products',
  stockCount: 1,
  price: '100',
  originalPrice: '',
  media: [
    PostMedia(
      path: 'assets/img1.png',
      name: 'First',
      type: PostMediaType.image,
      source: PostMediaSource.asset,
    ),
    PostMedia(
      path: 'assets/img2.png',
      name: 'Second',
      type: PostMediaType.image,
      source: PostMediaSource.asset,
    ),
    PostMedia(
      path: 'assets/img3.png',
      name: 'Third',
      type: PostMediaType.image,
      source: PostMediaSource.asset,
    ),
  ],
);

Widget _app(
  PostDetailCubit detail, {
  bool active = true,
  bool show = true,
  VoidCallback? onTap,
  ThemeData? theme,
}) => BlocProvider.value(
  value: detail,
  child: MaterialApp(
    theme: theme,
    navigatorObservers: [entranceRouteObserver],
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: show
              ? HomePostMediaSlider(
                  post: _post,
                  active: active,
                  onTap: onTap ?? () {},
                )
              : const SizedBox.shrink(),
        ),
      ),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'starts on first image at right and swipes in order ($brightness)',
      (tester) async {
        final detail = PostDetailCubit();
        addTearDown(detail.close);
        await tester.pumpWidget(
          _app(detail, theme: ThemeData(brightness: brightness)),
        );
        await tester.pumpAndSettle();
        final pager = tester.widget<PageView>(find.byType(PageView));
        expect(pager.controller!.page, 0);
        expect(pager.controller!.keepPage, isFalse);
        expect(
          Directionality.of(tester.element(find.byType(PageView))),
          TextDirection.rtl,
        );
        final dot = find.byKey(const ValueKey('carousel-active-dot'));
        final firstX = tester.getCenter(dot).dx;
        await tester.drag(find.byType(PageView), const Offset(260, 0));
        await tester.pumpAndSettle();
        expect(detail.state.imageIndex, 1);
        expect(tester.getCenter(dot).dx, lessThan(firstX));
        await tester.drag(find.byType(PageView), const Offset(-260, 0));
        await tester.pumpAndSettle();
        expect(detail.state.imageIndex, 0);
        expect(tester.getCenter(dot).dx, closeTo(firstX, .1));
      },
    );
  }

  testWidgets('returning to Home tab resets retained carousel to image zero', (
    tester,
  ) async {
    final detail = PostDetailCubit();
    addTearDown(detail.close);
    await tester.pumpWidget(_app(detail));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 1);
    await tester.pumpWidget(_app(detail, active: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(detail, active: true));
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 0);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0);
  });

  testWidgets('returning from post route resets the Home carousel', (
    tester,
  ) async {
    final detail = PostDetailCubit();
    addTearDown(detail.close);
    await tester.pumpWidget(_app(detail));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 1);
    final navigator = Navigator.of(
      tester.element(find.byType(HomePostMediaSlider)),
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Post detail')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 0);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0);
  });

  testWidgets('a rebuilt feed card does not restore a previously saved page', (
    tester,
  ) async {
    final detail = PostDetailCubit();
    addTearDown(detail.close);
    await tester.pumpWidget(_app(detail));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 1);
    await tester.pumpWidget(_app(detail, show: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(detail));
    await tester.pumpAndSettle();
    expect(detail.state.imageIndex, 0);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0);
  });

  testWidgets('Home images fill the entire square media box', (tester) async {
    final detail = PostDetailCubit();
    addTearDown(detail.close);
    await tester.pumpWidget(_app(detail));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PageView)), const Size(300, 300));
    for (var index = 0; index < 3; index++) {
      final images = tester.widgetList<Image>(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(Image),
        ),
      );
      expect(images, isNotEmpty);
      expect(images.every((image) => image.fit == BoxFit.cover), isTrue);
      if (index < 2) {
        await tester.drag(find.byType(PageView), const Offset(260, 0));
        await tester.pumpAndSettle();
      }
    }
    expect(detail.state.imageIndex, 2);
  });
}
