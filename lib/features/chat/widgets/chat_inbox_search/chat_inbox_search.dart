import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/chat/cubit/chat_inbox_cubit.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Inbox search field. Owns no cubit lifecycle — only drives [ChatInboxCubit.search].
class ChatInboxSearch extends StatelessWidget {
  const ChatInboxSearch({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: TextField(
          controller: controller,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          textInputAction: TextInputAction.search,
          onChanged: (value) => context.read<ChatInboxCubit>().search(value),
          style: AppTextStyles.comfortableBody.copyWith(
            color: colors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.search,
            hintStyle: AppTextStyles.comfortableBody.copyWith(
              color: colors.onSurface.withValues(alpha: 0.38),
            ),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 13),
              child: AppIcon(AppIcons.search, size: 24),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: colors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: colors.onSurface, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: colors.onSurface, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
