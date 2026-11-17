import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';

class TeamPickerCard extends StatelessWidget {
  const TeamPickerCard({
    super.key,
    required this.onTap,
    this.memberCount = 0,
    this.memberAvatars = const [],
    this.members = const [],
  });

  final VoidCallback onTap;
  final int memberCount;
  final List<ImageProvider> memberAvatars;
  final List<PostSeller> members;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final visibleAvatars = memberAvatars.take(6).toList();
    final visibleMembers = members.take(6).toList();
    final avatarCount = visibleMembers.isEmpty
        ? visibleAvatars.length
        : visibleMembers.length;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Team",
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyText.copyWith(color: colors.onSurface),
                textDirection: TextDirection.ltr,
              ),

              const SizedBox(height: 10),

              Container(
                width: 72,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Icon(Icons.chevron_left, color: colors.onSurface),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      memberCount == 0
                          ? "Add members"
                          : AppStrings.persianDigits(memberCount),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyText.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),

                  if (avatarCount > 0) ...[
                    const SizedBox(width: 8),

                    SizedBox(
                      width: 30.0 + (avatarCount - 1) * 18,
                      height: 32,
                      child: Stack(
                        children: [
                          for (var index = 0; index < avatarCount; index++)
                            Positioned(
                              right: index * 18.0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: colors.surface,
                                child: visibleMembers.isNotEmpty
                                    ? SellerAvatar(
                                        asset:
                                            visibleMembers[index].avatarAsset,
                                        name: visibleMembers[index].name,
                                        size: 28,
                                      )
                                    : CircleAvatar(
                                        radius: 14,
                                        backgroundImage: visibleAvatars[index],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
