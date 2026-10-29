import 'package:flutter/material.dart';

/// Shared by the app navigator so entrances replay when a screen is revealed.
final entranceRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// One controller per screen, shared by its staggered entrance widgets.
class ScreenEntrance extends StatefulWidget {
  const ScreenEntrance({super.key, this.active = true, required this.child});

  static const duration = Duration(milliseconds: 760);

  final bool active;
  final Widget child;

  @override
  State<ScreenEntrance> createState() => _ScreenEntranceState();
}

class _ScreenEntranceState extends State<ScreenEntrance>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _controller;
  PageRoute<dynamic>? _route;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ScreenEntrance.duration,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      entranceRouteObserver.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      if (_route != null) {
        entranceRouteObserver.subscribe(this, _route!);
      }
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant ScreenEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _play();
    }
  }

  void _play() {
    if (!widget.active || (_reduceMotion ?? true)) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void didPopNext() => _play();

  @override
  void dispose() {
    entranceRouteObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenEntranceScope(animation: _controller, child: widget.child);
  }
}

class ScreenEntranceScope extends InheritedWidget {
  const ScreenEntranceScope({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScreenEntranceScope>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(ScreenEntranceScope oldWidget) {
    return animation != oldWidget.animation;
  }
}
