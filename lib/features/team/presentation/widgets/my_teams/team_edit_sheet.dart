import 'package:flutter/material.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/features/team/domain/team_workspace.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class TeamEditSheet extends StatefulWidget {
  const TeamEditSheet({super.key, required this.team});
  final TeamWorkspace team;
  @override
  State<TeamEditSheet> createState() => _TeamEditSheetState();
}

class _TeamEditSheetState extends State<TeamEditSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.team.name);
  late final _description = TextEditingController(
    text: widget.team.description,
  );
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.team.copyWith(
        name: _name.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PostDialog(
    title: 'Edit team',
    actions: PostDialogActions(onDone: _save),
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _name,
            hint: 'Team name',
            validator: (value) =>
                value?.trim().isNotEmpty == true ? null : 'Enter a team name.',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _description,
            hint: 'Description',
            maxLines: 4,
          ),
        ],
      ),
    ),
  );
}
