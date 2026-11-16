import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TeamGeneralSection extends StatelessWidget {
  const TeamGeneralSection({
    super.key,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.spacing,
  });

  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescriptionChanged;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "عمومی",
          textAlign: TextAlign.right,
          style: AppTextStyles.caption.copyWith(color: foreground),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: spacing),
        AppTextField(
          hint: "نام تیم",
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          textStyle: AppTextStyles.bodyText.copyWith(color: foreground),
          onChanged: onNameChanged,
        ),
        SizedBox(height: spacing),
        AppTextField(
          hint: "توضیحات",
          maxLines: 5,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          textStyle: AppTextStyles.bodyText.copyWith(color: foreground),
          onChanged: onDescriptionChanged,
        ),
      ],
    );
  }
}
