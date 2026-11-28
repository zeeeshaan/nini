import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/create_post_strings.dart';
import 'package:hywork/core/localization/strings/report_strings.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';
import 'package:hywork/features/reports/presentation/cubit/report_cubit.dart';
import 'package:hywork/shared/widgets/app_button/app_button.dart';
import 'package:hywork/shared/widgets/app_textfield/app_text_field.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.title,
    required this.targetType,
    required this.targetId,
  });

  final String title;
  final String targetType;
  final String targetId;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final reason = _reason;
    if (reason == null) {
      AppToast.warning(context, ReportStrings.reasonRequired);
      return;
    }
    final cubit = context.read<ReportCubit>();
    final ok = await cubit.submit(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: reason,
      note: _note.text,
    );
    if (!context.mounted) return;
    if (ok) {
      AppToast.success(context, ReportStrings.success);
      Navigator.of(context).pop(true);
    } else if (cubit.state.error != null) {
      AppToast.error(context, cubit.state.error!);
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ReportCubit, ReportState>(
    builder: (context, state) => PostDialog(
      title: widget.title,
      actions: Row(
        children: [
          Expanded(
            child: AppButton(
              label: CreatePostStrings.cancel,
              variant: AppButtonVariant.outlined,
              height: 44,
              onPressed: state.submitting
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: state.submitting
                  ? ReportStrings.submitting
                  : ReportStrings.submit,
              height: 44,
              isLoading: state.submitting,
              onPressed: state.submitting ? null : () => _submit(context),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ReportStrings.chooseReason,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          for (final entry in ReportStrings.reasons.entries)
            PostChoiceTile(
              label: entry.value,
              selected: _reason == entry.key,
              onTap: state.submitting
                  ? () {}
                  : () => setState(() => _reason = entry.key),
            ),
          const SizedBox(height: 16),
          Text(
            ReportStrings.noteOptional,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _note,
            hint: ReportStrings.noteHint,
            maxLines: 3,
            enabled: !state.submitting,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    ),
  );
}
