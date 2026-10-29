import 'package:flutter/widgets.dart';

enum AppScreenType { compact, medium, expanded }

@immutable
class AppResponsive {
  const AppResponsive._(this.width);

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;
  static const double maxContentWidth = 1120;

  final double width;

  factory AppResponsive.fromWidth(double width) {
    assert(width >= 0 && width.isFinite);
    return AppResponsive._(width);
  }

  AppScreenType get screenType {
    if (width < mediumBreakpoint) {
      return AppScreenType.compact;
    }

    if (width < expandedBreakpoint) {
      return AppScreenType.medium;
    }

    return AppScreenType.expanded;
  }

  bool get isCompact => screenType == AppScreenType.compact;

  bool get isMedium => screenType == AppScreenType.medium;

  bool get isExpanded => screenType == AppScreenType.expanded;

  double get horizontalPadding => switch (screenType) {
    AppScreenType.compact => 16,
    AppScreenType.medium => 24,
    AppScreenType.expanded => 32,
  };

  double get verticalSpacing => switch (screenType) {
    AppScreenType.compact => 16,
    AppScreenType.medium => 24,
    AppScreenType.expanded => 32,
  };

  double get gridSpacing => switch (screenType) {
    AppScreenType.compact => 4,
    AppScreenType.medium => 8,
    AppScreenType.expanded => 12,
  };

  int get gridColumns => switch (screenType) {
    AppScreenType.compact => 3,
    AppScreenType.medium => 4,
    AppScreenType.expanded => 5,
  };

  double get constrainedWidth =>
      width < maxContentWidth ? width : maxContentWidth;

  T adaptive<T>({required T compact, required T medium, required T expanded}) {
    return switch (screenType) {
      AppScreenType.compact => compact,
      AppScreenType.medium => medium,
      AppScreenType.expanded => expanded,
    };
  }
}

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  AppResponsive responsive,
);

class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({super.key, required this.builder});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final responsive = AppResponsive.fromWidth(width);

        return builder(context, responsive);
      },
    );
  }
}
