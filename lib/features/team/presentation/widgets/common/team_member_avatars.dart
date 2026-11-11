import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class TeamMemberAvatars extends StatelessWidget {
  const TeamMemberAvatars({super.key, required this.members, this.maximum = 5});
  final List<PostSeller> members;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(maximum).toList();
    final remaining = members.length - shown.length;
    final count = shown.length + (remaining > 0 ? 1 : 0);
    final colors = Theme.of(context).colorScheme;
    if (count == 0) return const SizedBox.shrink();
    return SizedBox(
      width: 32 + (count - 1) * 20,
      height: 32,
      child: Stack(
        children: [
          for (var index = 0; index < count; index++)
            Positioned(
              right: index * 20.0,
              child: Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: index < shown.length
                    ? SellerAvatar(
                        asset: shown[index].avatarAsset,
                        name: shown[index].name,
                        size: 28,
                      )
                    : CircleAvatar(
                        backgroundColor: colors.primary,
                        child: Text(
                          '$remaining+',
                          style: AppTextStyles.smallPrint.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
