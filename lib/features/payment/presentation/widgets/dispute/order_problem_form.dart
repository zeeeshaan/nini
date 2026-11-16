import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/data/local_dispute_attachment_store.dart';
import 'package:nini/features/payment/domain/models/dispute_attachment.dart';
import 'package:nini/features/payment/presentation/widgets/dispute/dispute_attachment_tile.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class OrderProblemForm extends StatefulWidget {
  const OrderProblemForm({
    super.key,
    required this.heading,
    required this.hint,
    required this.requiredMessage,
    required this.actionLabel,
    required this.successMessage,
    required this.localNotice,
    required this.onSubmit,
    this.initialText,
    this.initialAttachments = const [],
    this.readOnly = false,
  });
  final String heading,
      hint,
      requiredMessage,
      actionLabel,
      successMessage,
      localNotice;
  final String? initialText;
  final List<DisputeAttachment> initialAttachments;
  final bool readOnly;
  final Future<bool> Function(String, List<DisputeAttachment>) onSubmit;

  @override
  State<OrderProblemForm> createState() => _OrderProblemFormState();
}

class _OrderProblemFormState extends State<OrderProblemForm> {
  final _description = TextEditingController();
  final _store = LocalDisputeAttachmentStore();
  final _attachments = <DisputeAttachment>[];
  bool _saved = false, _saving = false, _picking = false, _showError = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.initialText != null;
    _description.text = widget.initialText ?? '';
    _attachments.addAll(widget.initialAttachments);
  }

  @override
  void dispose() {
    _description.dispose();
    if (!_saved) unawaited(_store.discard(List.of(_attachments)));
    super.dispose();
  }

  Future<void> _attach(String type) async {
    if (_picking || _saving || _saved || widget.readOnly) return;
    setState(() => _picking = true);
    try {
      final files = <({String path, String name, bool image})>[];
      if (type == 'image') {
        final photo = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
        if (photo != null) {
          files.add((path: photo.path, name: photo.name, image: true));
        }
      } else {
        for (final file in await FilePicker.pickFiles(type: FileType.any)) {
          files.add((path: file.xFile.path, name: file.name, image: false));
        }
      }
      if (!mounted) return;
      for (final file in files) {
        final copy = await _store.copy(
          path: file.path,
          name: file.name,
          isImage: file.image,
        );
        if (!mounted) {
          await _store.discard([copy]);
          return;
        }
        setState(() => _attachments.add(copy));
      }
    } catch (_) {
      if (mounted) AppToast.warning(context, ReceiptStrings.attachFailed);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _remove(DisputeAttachment attachment) {
    setState(() => _attachments.remove(attachment));
    unawaited(_store.discard([attachment]));
  }

  Future<void> _submit() async {
    if (_saving || _picking || _saved || widget.readOnly) return;
    if (_description.text.trim().isEmpty) {
      setState(() => _showError = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final saved = await widget.onSubmit(
      _description.text,
      List.unmodifiable(_attachments),
    );
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _saving = false;
    });
    if (saved) {
      AppToast.success(context, widget.successMessage);
      Navigator.of(context).pop();
    } else {
      AppToast.warning(context, ReceiptStrings.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editable = !_saved && !widget.readOnly;
    final enabled = editable && !_saving && !_picking;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.heading,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyEmphasis,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _description,
                      readOnly: !enabled,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body,
                      minLines: 12,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        if (_showError) {
                          setState(() => _showError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        errorText: _showError ? widget.requiredMessage : null,
                        contentPadding: const EdgeInsets.all(18),
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight * .6).clamp(
                            260,
                            620,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    for (final attachment in _attachments)
                      DisputeAttachmentTile(
                        attachment: attachment,
                        onRemove: enabled ? () => _remove(attachment) : null,
                      ),
                    const SizedBox(height: 12),
                    if (editable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: ReceiptStrings.attach,
                              enabled: enabled,
                              onSelected: _attach,
                              icon: const AppIcon(
                                AppIcons.attachment,
                                size: 22,
                              ),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'file',
                                  child: Row(
                                    children: [
                                      AppIcon(AppIcons.document, size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        ReceiptStrings.file,
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'image',
                                  child: Row(
                                    children: [
                                      AppIcon(AppIcons.image, size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        ReceiptStrings.image,
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filled(
                              tooltip: widget.actionLabel,
                              onPressed: enabled ? _submit : null,
                              icon: _saving || _picking
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : AppIcon(
                                      AppIcons.send,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      size: 22,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      widget.localNotice,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.label,
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
