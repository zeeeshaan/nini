import 'package:nini/core/localization/strings/team_strings.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/features/team/presentation/widgets/common/team_member_avatars.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.messageCount,
    required this.onTap,
    required this.onMore,
  });
  final TeamWorkspace team;
  final int messageCount;
  final VoidCallback onTap, onMore;

  String get _duration {
    final schedule = team.request.schedule;
    if (schedule == null) return '';
    final duration = schedule.endsAt.difference(schedule.startsAt);
    return TeamStrings.duration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    tooltip: "گزینه‌های تیم",
                    onPressed: onMore,
                    icon: const AppIcon(AppIcons.more, size: 18),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        team.name,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodyBold,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                team.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyles.smallPrint,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _duration,
                          style: AppTextStyles.smallPrint,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.document, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.persianDigits(
                                team.request.attachments.length,
                              ),
                              style: AppTextStyles.smallPrint,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.chat, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.persianDigits(messageCount),
                              style: AppTextStyles.smallPrint,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TeamMemberAvatars(members: team.members, maximum: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
