import 'package:nini/shared/widgets/calendar/app_calendar.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/create_post/presentation/widgets/form/selected_media_grid.dart';
import 'package:nini/features/team/domain/team_request.dart';
import 'package:nini/features/team/presentation/widgets/member_request/team_request_provider_list.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class TeamRequestSummary extends StatelessWidget {
  const TeamRequestSummary({
    super.key,
    required this.request,
    required this.padding,
    required this.spacing,
  });

  final TeamRequest request;
  final double padding, spacing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dates = MaterialLocalizations.of(context);
    final start = request.schedule!.startsAt;
    final media = request.attachments.where((item) => !item.isFile).toList();
    final files = request.attachments.where((item) => item.isFile).toList();
    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        const Text(
          'Order Details',
          textAlign: TextAlign.right,
          style: AppTextStyles.sectionTitle,
          textDirection: TextDirection.ltr,
        ),
        SizedBox(height: spacing),
        TeamRequestProviderList(request: request),
        SizedBox(height: spacing * 1.5),
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                request.title,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyBold,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: spacing),
              Text(
                request.description,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyText,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: spacing * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      '${formatSolarDate(start)} · ${dates.formatTimeOfDay(TimeOfDay.fromDateTime(start))}',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppIcon(AppIcons.calendar, size: 20),
                ],
              ),
              SizedBox(height: spacing * 2),
              SelectedMediaGrid(attachments: media),
              if (files.isNotEmpty) ...[
                SizedBox(height: spacing),
                for (final attachment in files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  attachment.file!.name,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.bodyText,
                                  textDirection: TextDirection.ltr,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Selected attachment',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.smallPrint,
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const AppIcon(AppIcons.document, size: 30),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
