import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/team/presentation/widgets/common/team_member_avatars.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class TeamChatMembersBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TeamChatMembersBar({
    super.key,
    required this.members,
    required this.onTap,
  });
  final List<PostSeller> members;
  final VoidCallback onTap;
  @override
  Size get preferredSize => const Size.fromHeight(52);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Center(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'People (${members.length})',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.smallPrint,
                ),
              ),
              const SizedBox(width: 12),
              TeamMemberAvatars(members: members),
            ],
          ),
        ),
      ),
    ),
  );
}
