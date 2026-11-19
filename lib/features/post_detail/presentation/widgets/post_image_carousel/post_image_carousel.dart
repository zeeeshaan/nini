import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_carousel_image.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/presentation/widgets/published/home_post_media_indicator.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/models/post/post_media.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';

class PostImageCarousel extends StatefulWidget {
  const PostImageCarousel({
    super.key,
    this.images = const [],
    this.media = const [],
    this.mediaFit = BoxFit.contain,
    this.showIndicators = true,
    this.active = true,
    this.resetOnReturn = false,
  });

  final List<String> images;
  final List<PostMedia> media;
  final BoxFit mediaFit;
  final bool showIndicators;
  final bool active;
  final bool resetOnReturn;

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> with RouteAware {
  late final PageController _pageController;
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: false);
    context.read<PostDetailCubit>().changeImage(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) return;
    entranceRouteObserver.unsubscribe(this);
    _route = route is PageRoute<dynamic> ? route : null;
    if (_route != null) entranceRouteObserver.subscribe(this, _route!);
  }

  @override
  void didUpdateWidget(covariant PostImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && widget.resetOnReturn) {
      _resetToFirst();
    }
  }

  @override
  void didPopNext() {
    if (widget.resetOnReturn && widget.active) _resetToFirst();
  }

  void _resetToFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      context.read<PostDetailCubit>().changeImage(0);
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  @override
  void dispose() {
    entranceRouteObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.media.isNotEmpty
        ? widget.media.length
        : widget.images.length;
    final images = Directionality(
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 1,
        child: PageView.builder(
          controller: _pageController,
          itemCount: count,
          onPageChanged: (index) {
            context.read<PostDetailCubit>().changeImage(index);
          },
          itemBuilder: (context, index) {
            if (widget.media.isNotEmpty) {
              return PostMediaView(
                media: widget.media[index],
                fit: widget.mediaFit,
              );
            }
            return PostCarouselImage(
              path: widget.images[index],
              fit: widget.mediaFit,
            );
          },
        ),
      ),
    );
    if (!widget.showIndicators || count < 2) return images;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        images,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: IgnorePointer(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: HomePostMediaIndicator(
                  count: count,
                  controller: _pageController,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
