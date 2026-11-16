import 'package:nini/features/create_post/presentation/cubit/post_features_cubit.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/create_post_strings.dart';
import 'package:nini/features/create_post/domain/models/post_options.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

class FeaturesDialog extends StatefulWidget {
  const FeaturesDialog({super.key, required this.initial});
  final List<PostFeature> initial;
  @override
  State<FeaturesDialog> createState() => _FeaturesDialogState();
}

class _FeaturesDialogState extends State<FeaturesDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  late final _draft = PostFeaturesCubit(widget.initial);
  @override
  void dispose() {
    _draft.close();
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  bool _add() {
    if (!_draft.save(_name.text, _value.text)) return false;
    _name.clear();
    _value.clear();
    return true;
  }

  void _done() {
    if ((_name.text.isNotEmpty || _value.text.isNotEmpty) && !_add()) return;
    Navigator.of(context)
        .pop(List<PostFeature>.unmodifiable(_draft.state.features));
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostFeaturesCubit, PostFeaturesState>(
    bloc: _draft,
    builder: (context, state) => PostDialog(
      title: CreatePostStrings.featuresHeading,
      icon: AppIcons.features,
      actions: PostDialogActions(onDone: _done),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .58,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  tooltip: _draft.state.editing == null
                      ? CreatePostStrings.addFeature
                      : CreatePostStrings.saveFeature,
                  onPressed: _add,
                  icon: AppIcon(
                    _draft.state.editing == null
                        ? AppIcons.add
                        : AppIcons.check,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: _value,
                    label: CreatePostStrings.featureValue,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField(
                    controller: _name,
                    label: CreatePostStrings.feature,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (_draft.state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _draft.state.error!,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Expanded(
              child: _draft.state.features.isEmpty
                  ? const Center(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CreatePostStrings.firstFeatureHelp,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _draft.state.features.length,
                      itemBuilder: (context, index) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: IconButton(
                              tooltip: CreatePostStrings.removeFeature(
                                _draft.state.features[index].name,
                              ),
                              icon: const AppIcon(AppIcons.close, size: 18),
                              onPressed: () {
                                _draft.remove(index);
                                _name.clear();
                                _value.clear();
                              },
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _draft.state.features[index].value,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _draft.state.features[index].name,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              _draft.edit(index);
                              _name.text = _draft.state.features[index].name;
                              _value.text = _draft.state.features[index].value;
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
