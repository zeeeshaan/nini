import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class AnalyticsSectionHeading extends StatelessWidget {
  const AnalyticsSectionHeading({
    super.key,
    required this.title,
    required this.period,
    required this.onPeriodChanged,
    this.leftInset = 0,
  });
  final String title;
  final AnalyticsPeriod period;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;
  final double leftInset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: leftInset, bottom: 14),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        PopupMenuButton<AnalyticsPeriod>(
          tooltip: AppStrings.analyticsPeriod(title),
          initialValue: period,
          onSelected: onPeriodChanged,
          itemBuilder: (context) => [
            for (final value in AnalyticsPeriod.values)
              PopupMenuItem(value: value, child: Text(value.label)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .07),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(period.label, style: AppTextStyles.helper),
                ),
                const SizedBox(width: 7),
                const AppIcon(AppIcons.chevronDown, size: 10),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AnalyticsTooltip extends StatelessWidget {
  const AnalyticsTooltip({
    super.key,
    required this.date,
    required this.total,
    required this.labels,
    required this.values,
    required this.colors,
  });
  final String date, total;
  final List<String> labels, values;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.transparent,
    child: Container(
      width: 176,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .16),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    date,
                    style: AppTextStyles.smallPrint.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: .55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(total, style: AppTextStyles.smallPrintEmphasis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: AppTextStyles.smallPrint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        values[i],
                        style: AppTextStyles.smallPrintEmphasis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class AnalyticsLegend extends StatelessWidget {
  const AnalyticsLegend({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: selected ? color : AppColors.transparent,
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? const AppIcon(
                      AppIcons.check,
                      size: 10,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.micro),
          ],
        ),
      ),
    ),
  );
}

class AnalyticsSummary extends StatelessWidget {
  const AnalyticsSummary({
    super.key,
    required this.value,
    this.sample = false,
    this.trailing,
  });
  final String value;
  final bool sample;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.bodyBold),
            ),
          ),
          if (sample) ...[
            const SizedBox(width: 8),
            Text(
              AppStrings.sampleChange,
              style: AppTextStyles.metadata.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .55),
              ),
            ),
            const SizedBox(width: 4),
            const AppIcon(
              AppIcons.arrowDownRight,
              color: AppColors.analyticsPurple,
              size: 12,
            ),
          ],
        ],
      ),
      ?trailing,
    ],
  );
}

String analyticsNumber(double value) => AppStrings.persianDigits(
  value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1),
);
String analyticsDate(DateTime date) => AppStrings.persianDigits(
  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
);

typedef AnalyticsReportBuilder = PostAnalyticsReport Function(
  AnalyticsPeriod period,
);
