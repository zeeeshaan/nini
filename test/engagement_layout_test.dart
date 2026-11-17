import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/features/home/presentation/widgets/common/home_engagement_bar.dart';
import 'package:nini/features/home/presentation/widgets/common/home_engagement_layout.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_engagement_bar.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

void main() {
  for (final details in [false, true]) {
    for (final direction in TextDirection.values) {
      for (final width in [390.0, 600.0]) {
        testWidgets(
          'cart is rightmost on ${details ? 'Details' : 'Home'} at $width with $direction',
          (tester) async {
            final cubit = PostDetailCubit();
            addTearDown(cubit.close);
            await tester.pumpWidget(
              BlocProvider.value(
                value: cubit,
                child: MaterialApp(
                  home: Scaffold(
                    body: Directionality(
                      textDirection: direction,
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: details
                              ? PostEngagementBar(
                                  showSampleMetrics: false,
                                  onCartPressed: () {},
                                  onCommentsPressed: () {},
                                  onSharePressed: () {},
                                )
                              : HomeEngagementBar(
                                  isLiked: false,
                                  isBookmarked: false,
                                  showSampleMetrics: false,
                                  onLike: () {},
                                  onBookmark: () {},
                                  onAddToCart: () {},
                                  onCommentsPressed: () {},
                                  onSharePressed: () {},
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            Finder icon(String asset) => find.byWidgetPredicate(
              (widget) => widget is AppIcon && widget.asset == asset,
            );
            final order = [
              AppIcons.shoppingBag,
              AppIcons.postLike,
              AppIcons.postShare,
              AppIcons.postComment,
              AppIcons.bookmark,
              AppIcons.star,
            ];
            for (var index = 1; index < order.length; index++) {
              expect(
                tester.getCenter(icon(order[index - 1])).dx,
                greaterThan(tester.getCenter(icon(order[index])).dx),
              );
            }
            final bounds = tester.getRect(find.byType(HomeEngagementLayout));
            final cart = tester.getRect(icon(AppIcons.shoppingBag));
            expect(bounds.right - cart.right, lessThan(8));
            expect(cart.size, const Size(22, 22));
            expect(tester.getSize(icon(AppIcons.postLike)), const Size(24, 24));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
